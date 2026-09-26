"""Exercise the real Godot skill dispatcher against disposable import sidecars.

This is a tooling boundary regression, not a gameplay test. The caller supplies
an absolute Godot executable; no vendored launcher or shell resolves it for us.
All hostile destinations and link targets are inside one disposable test root.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile


def absolute_file(value: str) -> Path:
    path = Path(value)
    if not path.is_absolute() or not path.is_file():
        raise argparse.ArgumentTypeError("an absolute existing file is required")
    return path.resolve(strict=True)


def directory_link(link: Path, target: Path) -> None:
    if os.name == "nt":
        # Junctions do not require Windows symlink privileges. Both endpoints
        # are owned by this test's temporary directory.
        import _winapi
        _winapi.CreateJunction(str(target), str(link))
    else:
        link.symlink_to(target, target_is_directory=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot-bin", type=absolute_file, required=True)
    parser.add_argument("--dispatcher", type=absolute_file, default=(
        Path(__file__).resolve().parents[1]
        / ".agents/skills/godot/scripts/core/dispatcher.gd"))
    args = parser.parse_args()
    passed: list[str] = []
    skipped: list[str] = []

    with tempfile.TemporaryDirectory(prefix="wc-import-boundary-") as temp:
        root = Path(temp).resolve(strict=True)
        assert root.parent == Path(tempfile.gettempdir()).resolve(strict=True)

        def exercise(name: str, mode: str, accept: bool = False) -> None:
            project = root / name
            cache = project / ".godot/imported"
            cache.mkdir(parents=True)
            (project / "project.godot").write_text(
                'config_version=5\n[application]\nconfig/name="Import boundary fixture"\n',
                encoding="utf-8")
            (project / "asset.bin").write_bytes(b"fixture source\x00")
            outside = root / (name + "-outside.keep")
            local = project / "sentinel.keep"
            artifact = cache / "probe.ctex"
            companion = cache / "probe.md5"
            for path in [outside, local, artifact, companion]:
                path.write_bytes(("preserve:" + path.name).encode() + b"\x00\xff")
            watched = {path: path.read_bytes() for path in [outside, local, artifact, companion]}
            good = "res://.godot/imported/probe.ctex"
            entries: object = [good]
            packed = False
            links: list[tuple[Path, bool]] = []
            try:
                if mode == "external":
                    entries = [good, outside.as_posix()]
                elif mode == "project":
                    entries = [good, "res://sentinel.keep"]
                elif mode == "traversal":
                    entries = [good, "res://.godot/imported/../../sentinel.keep"]
                elif mode == "cache_traversal":
                    entries = ["res://.godot/imported/../imported/probe.ctex"]
                elif mode == "sibling":
                    entries = [good, "res://.godot/imported-other/probe.ctex"]
                elif mode == "nested":
                    entries = [good, "res://.godot/imported/nested/probe.ctex"]
                elif mode == "ads":
                    entries = [good, "res://.godot/imported/probe.ctex:stream"]
                elif mode == "non_string":
                    entries = [good, 123]
                elif mode == "scalar":
                    entries = good
                elif mode == "directory":
                    (cache / "directory.ctex").mkdir()
                    entries = [good, "res://.godot/imported/directory.ctex"]
                elif mode in {"cache_link", "data_link"}:
                    link = cache if mode == "cache_link" else project / ".godot"
                    target = root / (name + "-linked-directory")
                    link.rename(target)
                    directory_link(link, target)
                    links.append((link, True))
                elif mode in {"artifact_junction", "md5_junction"}:
                    link = companion if mode == "md5_junction" else artifact
                    link.unlink()
                    watched.pop(link)
                    target = root / (name + "-linked-directory")
                    target.mkdir()
                    nested_sentinel = target / "sentinel.keep"
                    nested_sentinel.write_bytes(b"linked directory must survive")
                    watched[nested_sentinel] = nested_sentinel.read_bytes()
                    directory_link(link, target)
                    links.append((link, True))
                elif mode in {"artifact_link", "md5_link", "broken_link"}:
                    link = companion if mode == "md5_link" else artifact
                    link.unlink()
                    target = root / "nonexistent.keep" if mode == "broken_link" else outside
                    try:
                        link.symlink_to(target)
                    except OSError as exc:
                        skipped.append(f"{name}: file symlink unavailable (errno={exc.errno}, winerror={getattr(exc, 'winerror', None)})")
                        return
                    links.append((link, False))
                    watched.pop(link)
                elif mode == "absolute_ok":
                    entries = [artifact.as_posix()]
                elif mode == "packed_ok":
                    entries = [good, "res://.godot/imported/already-missing.ctex"]
                    packed = True

                encoded = json.dumps(entries)
                if packed:
                    encoded = "PackedStringArray(" + ", ".join(json.dumps(x) for x in entries) + ")"
                sidecar = project / "asset.bin.import"
                original = ('[deps]\ndest_files=' + encoded + '\n\n[params]\nloop=false\n').encode()
                sidecar.write_bytes(original)
                result = subprocess.run(
                    [str(args.godot_bin), "--headless", "--path", str(project),
                     "--script", str(args.dispatcher), "set_import_options",
                     json.dumps({"file_path": "res://asset.bin", "options": {"loop": True}})],
                    capture_output=True, text=True, stdin=subprocess.DEVNULL, timeout=30,
                    check=False)
                output = result.stdout + result.stderr
                assert "SCRIPT ERROR" not in output, f"{name}: script failure\n{output}"
                if accept:
                    assert result.returncode == 0, f"{name}: rejected legal target\n{output}"
                    assert not artifact.exists() and not companion.exists(), name
                    assert b"loop=true" in sidecar.read_bytes().replace(b" ", b""), name
                    for path in [outside, local]:
                        assert path.read_bytes() == watched[path], f"{name}: unrelated bytes changed"
                else:
                    # Check bytes even when a vulnerable dispatcher reports success.
                    for path, contents in watched.items():
                        assert path.is_file() and path.read_bytes() == contents, f"{name}: {path.name} changed"
                    assert sidecar.read_bytes() == original, f"{name}: sidecar changed before refusal"
                    assert result.returncode == 1 and "Unsafe import cache destination:" in output, (
                        f"{name}: expected deliberate refusal\n{output}")
                passed.append(name)
            finally:
                # Remove links themselves before TemporaryDirectory cleans its own
                # verified root; never traverse a junction during cleanup.
                for link, is_directory in reversed(links):
                    if is_directory and os.name == "nt":
                        os.rmdir(link)
                    else:
                        link.unlink()

        for case in ["external", "project", "traversal", "cache_traversal", "sibling",
                     "nested", "ads", "non_string", "scalar", "directory", "cache_link",
                     "data_link", "artifact_junction", "md5_junction", "artifact_link",
                     "md5_link", "broken_link"]:
            exercise(case, case)
        for case in ["resource_ok", "absolute_ok", "packed_ok"]:
            exercise(case, case, accept=True)
    print(json.dumps({"ok": True, "passed": len(passed), "cases": passed, "skipped": skipped}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
