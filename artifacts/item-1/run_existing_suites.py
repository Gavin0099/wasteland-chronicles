"""Run the frozen pre-ITEM-1 Godot suites and preserve historical snapshots.

This test-only launcher uses an explicit executable and an argv list, never a
shell. Before/after evidence shares the same forty-suite manifest. It does not
run new ITEM-1 suites or modify gameplay code.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
MANIFEST = HERE / "existing_suites_manifest.json"
ENV_KEYS = ("SystemRoot", "WINDIR", "TEMP", "TMP", "APPDATA", "LOCALAPPDATA",
            "USERPROFILE", "HOMEDRIVE", "HOMEPATH", "NUMBER_OF_PROCESSORS",
            "PROCESSOR_ARCHITECTURE")
WRITE_PATTERN = re.compile(r'FileAccess\.open\("res://(artifacts/[^"\n]+)",\s*FileAccess\.WRITE\)')
HASH_PATTERN = re.compile(r"\b[0-9a-f]{64}\b")


def sha(data):
    return hashlib.sha256(data).hexdigest()


def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def relative_file(name):
    path = (ROOT / name).resolve()
    if not path.is_relative_to(ROOT) or not path.is_file():
        raise ValueError("File outside repository or missing: " + name)
    return path


def executable_metadata(path):
    path = Path(path).resolve(strict=True)
    if not path.is_file() or path.suffix.lower() != ".exe":
        raise ValueError("Expected an existing Godot executable")
    data = path.read_bytes()
    return {"path": str(path), "bytes": len(data), "sha256": sha(data)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--phase", required=True, choices=["before", "after"])
    parser.add_argument("--godot", required=True)
    parser.add_argument("--source-commit", required=True)
    args = parser.parse_args()
    executable = executable_metadata(args.godot)
    child_env = {key: os.environ[key] for key in ENV_KEYS if key in os.environ}
    if args.phase == "before":
        if MANIFEST.exists():
            raise ValueError("Refusing to replace the baseline manifest")
        suites = sorted(ROOT.glob("tests/test_*.gd"))
        if len(suites) != 40:
            raise ValueError("Expected exactly the original 40 suites")
        manifest = {"source_commit": args.source_commit, "godot": executable,
                    "argv_prefix": ["--headless", "--path", str(ROOT), "--script"],
                    "child_environment_keys": sorted(child_env), "suites": []}
        for path in suites:
            source = path.read_bytes()
            manifest["suites"].append({"path": path.relative_to(ROOT).as_posix(),
                                       "sha256": sha(source),
                                       "historical_writes": WRITE_PATTERN.findall(source.decode("utf-8-sig"))})
        dump(MANIFEST, manifest)
    else:
        manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
        if manifest["godot"] != executable:
            raise ValueError("Godot executable differs from baseline")

    for suite in manifest["suites"]:
        if sha(relative_file(suite["path"]).read_bytes()) != suite["sha256"]:
            raise ValueError("Existing test changed: " + suite["path"])

    output = HERE / args.phase
    if output.exists():
        raise ValueError("Refusing to replace prior run evidence")
    output.mkdir()
    backups = output / "historical-originals"
    backups.mkdir()
    historical = sorted({path for suite in manifest["suites"] for path in suite["historical_writes"]})
    original = {}
    for name in historical:
        data = relative_file(name).read_bytes()
        original[name] = data
        (backups / Path(name).name).write_bytes(data)
    dump(output / "historical-before.json", [{"path": name, "sha256": sha(data), "bytes": len(data)}
                                              for name, data in original.items()])
    results = []
    restored = []
    for index, suite in enumerate(manifest["suites"], 1):
        if executable_metadata(executable["path"]) != executable:
            raise ValueError("Godot executable changed before launch")
        for name in suite["historical_writes"]:
            if relative_file(name).read_bytes() != original[name]:
                raise ValueError("Historical artifact changed outside this suite: " + name)
        argv = [executable["path"], *manifest["argv_prefix"], suite["path"]]
        started = time.monotonic()
        timed_out = False
        try:
            completed = subprocess.run(argv, cwd=ROOT, env=child_env, shell=False,
                                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
            raw, exit_code = completed.stdout, completed.returncode
        except subprocess.TimeoutExpired as exc:
            raw, exit_code, timed_out = exc.stdout or b"", -1, True
        log_path = output / (Path(suite["path"]).stem + ".log")
        log_path.write_bytes(raw)
        text = raw.decode("utf-8", errors="replace")
        lines = text.splitlines()
        result = {"suite": Path(suite["path"]).name, "argv": argv,
                  "exit_code": exit_code, "timeout": timed_out,
                  "elapsed_seconds": round(time.monotonic() - started, 3),
                  "log_sha256": sha(raw),
                  "script_errors": [line for line in lines if "SCRIPT ERROR" in line],
                  "sha_lines": [line for line in lines if HASH_PATTERN.search(line)],
                  "diagnostics": [line for line in lines if "WARNING:" in line or "ERROR:" in line]}
        results.append(result)
        # Only this suite's explicit literal WRITE targets can be restored.
        # Keep emitted bytes as evidence first; refuse to clobber any later edit.
        for name in suite["historical_writes"]:
            path = relative_file(name)
            emitted = path.read_bytes()
            record = {"suite": result["suite"], "path": name, "original_sha256": sha(original[name]),
                      "emitted_sha256": sha(emitted), "changed": emitted != original[name]}
            if emitted != original[name]:
                generated = output / "historical-emitted"
                generated.mkdir(exist_ok=True)
                (generated / path.name).write_bytes(emitted)
                if path.read_bytes() != emitted:
                    raise ValueError("Artifact changed after test; refusing restore: " + name)
                path.write_bytes(original[name])
            record["restored_sha256"] = sha(path.read_bytes())
            restored.append(record)
        dump(output / "results.json", results)
        dump(output / "historical-restoration.json", restored)
        print(f"{index:02d}/40 {result['suite']}: exit={exit_code}; script_errors={len(result['script_errors'])}", flush=True)

    final_hashes = [{"path": name, "sha256": sha(relative_file(name).read_bytes()),
                     "matches_original": relative_file(name).read_bytes() == data}
                    for name, data in original.items()]
    failures = [result["suite"] for result in results if result["exit_code"] or result["script_errors"]]
    summary = {"phase": args.phase, "source_commit": args.source_commit, "godot": executable,
               "suite_count": len(results), "failed_suites": failures,
               "script_error_count": sum(len(result["script_errors"]) for result in results),
               "diagnostic_suite_count": sum(bool(result["diagnostics"]) for result in results),
               "historical_artifacts": final_hashes,
               "trust_scope": "Test-only exact-path/hash launcher; no production or security attestation."}
    dump(output / "summary.json", summary)
    print(json.dumps(summary, ensure_ascii=False), flush=True)
    return 1 if failures or not all(row["matches_original"] for row in final_hashes) else 0


if __name__ == "__main__":
    sys.exit(main())
