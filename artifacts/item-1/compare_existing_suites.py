"""Compare fresh fixed-suite baseline and ITEM-1 regression evidence."""
import hashlib
import json
from pathlib import Path
import re
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


def read(relative):
    return json.loads((HERE / relative).read_text(encoding="utf-8"))


def digest(data):
    return hashlib.sha256(data).hexdigest()


def shutdown_warning(line):
    return bool(re.fullmatch(r"ERROR: \d+ RID allocations of type '.+' were leaked at exit\.", line)
                or re.fullmatch(r'WARNING: \d+ RIDs of type "CanvasItem" were leaked\.', line)
                or re.fullmatch(r"WARNING: \d+ ObjectDB instances were leaked at exit \(run with `--verbose` for details\)\.", line))


def main():
    manifest = read("existing_suites_manifest.json")
    before = {row["suite"]: row for row in read("before/results.json")}
    after = {row["suite"]: row for row in read("after/results.json")}
    expected = {Path(row["path"]).name for row in manifest["suites"]}
    defects = []
    if set(before) != expected or set(after) != expected or len(expected) != 40:
        defects.append("Suite sets do not equal the original frozen 40 suites")
    rows = []
    for suite in manifest["suites"]:
        name = Path(suite["path"]).name
        old, new = before.get(name, {}), after.get(name, {})
        source_sha = digest((ROOT / suite["path"]).read_bytes())
        old_log = (HERE / "before" / (Path(name).stem + ".log")).read_bytes()
        new_log = (HERE / "after" / (Path(name).stem + ".log")).read_bytes()
        unexpected = [line for line in old.get("diagnostics", []) + new.get("diagnostics", [])
                      if not shutdown_warning(line)]
        result = {"suite": name, "source_sha256": source_sha,
                  "source_unchanged": source_sha == suite["sha256"],
                  "before_exit": old.get("exit_code"), "after_exit": new.get("exit_code"),
                  "before_sha_lines": old.get("sha_lines"), "after_sha_lines": new.get("sha_lines"),
                  "sha_lines_identical": old.get("sha_lines") == new.get("sha_lines"),
                  "before_log_sha256": digest(old_log), "after_log_sha256": digest(new_log),
                  "log_receipts_match": digest(old_log) == old.get("log_sha256") and digest(new_log) == new.get("log_sha256"),
                  "before_script_errors": old.get("script_errors"), "after_script_errors": new.get("script_errors"),
                  "before_shutdown_warnings": old.get("diagnostics", []),
                  "after_shutdown_warnings": new.get("diagnostics", []),
                  "shutdown_warnings_identical": old.get("diagnostics") == new.get("diagnostics"),
                  "unexpected_diagnostics": unexpected}
        if (not result["source_unchanged"] or result["before_exit"] != 0 or result["after_exit"] != 0
                or not result["sha_lines_identical"] or not result["log_receipts_match"]
                or result["before_script_errors"] or result["after_script_errors"] or unexpected):
            defects.append("Regression evidence mismatch: " + name)
        rows.append(result)

    old_artifacts = {row["path"]: row for row in read("before/historical-restoration.json")}
    new_artifacts = {row["path"]: row for row in read("after/historical-restoration.json")}
    if set(old_artifacts) != set(new_artifacts) or len(old_artifacts) != 8:
        defects.append("Historical snapshot set differs from expected eight write targets")
    snapshots = []
    for name, old in old_artifacts.items():
        new = new_artifacts.get(name, {})
        file_name = Path(name).name
        old_data = (HERE / "before/historical-emitted" / file_name).read_bytes()
        new_data = (HERE / "after/historical-emitted" / file_name).read_bytes()
        old_original = (HERE / "before/historical-originals" / file_name).read_bytes()
        new_original = (HERE / "after/historical-originals" / file_name).read_bytes()
        live_data = (ROOT / name).read_bytes()
        result = {"path": name, "before_emitted_sha256": digest(old_data),
                  "after_emitted_sha256": digest(new_data), "emitted_bytes_identical": old_data == new_data,
                  "emitted_receipts_match": digest(old_data) == old["emitted_sha256"] and digest(new_data) == new.get("emitted_sha256"),
                  "originals_identical": old_original == new_original,
                  "current_sha256": digest(live_data), "restored_to_original_bytes": live_data == old_original == new_original}
        if not all(result[key] for key in ("emitted_bytes_identical", "emitted_receipts_match", "originals_identical", "restored_to_original_bytes")):
            defects.append("Historical artifact mismatch: " + name)
        snapshots.append(result)

    summary = {"status": "PASS" if not defects else "FAIL",
               "baseline_commit": manifest["source_commit"],
               "before_results": "artifacts/item-1/before/results.json",
               "after_results": "artifacts/item-1/after/results.json",
               "suite_count": len(rows),
               "source_test_sha_unchanged_count": sum(row["source_unchanged"] for row in rows),
               "before_sha_line_count": sum(len(row["before_sha_lines"]) for row in rows),
               "after_sha_line_count": sum(len(row["after_sha_lines"]) for row in rows),
               "snapshot_count": len(snapshots),
               "known_shutdown_warning_suite_count": sum(bool(row["after_shutdown_warnings"]) for row in rows),
               "warning_scope": "Existing Godot shutdown RID/CanvasItem/ObjectDB leak diagnostics are retained. This is not a leak-free claim.",
               "defects": defects, "suites": rows, "snapshots": snapshots}
    (HERE / "regression-comparison.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in summary.items() if key not in ("suites", "snapshots")}, ensure_ascii=False))
    return 1 if defects else 0


if __name__ == "__main__":
    sys.exit(main())
