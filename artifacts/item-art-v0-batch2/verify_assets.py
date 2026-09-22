"""Read-only bitmap validation and manifest generation; never rewrites images."""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "ui/assets/items/candidates"
EXPECTED = {
    "rusty_knife", "hunting_knife", "rebar_club", "scrap_machete",
    "work_clothes", "desert_robe", "caravan_coat", "travel_backpack",
    "rope", "flashlight", "wrench", "medkit",
}

def main():
    jobs = json.loads((ASSETS / "prompts.json").read_text(encoding="utf-8"))["jobs"]
    sources = json.loads((ASSETS / "sources.json").read_text(encoding="utf-8"))
    assert len(jobs) == len(EXPECTED)
    assert {job["id"] for job in jobs} == EXPECTED
    assert set(sources) == EXPECTED
    manifest = []
    for job in jobs:
        path = ASSETS / (job["id"] + ".png")
        source = sources[job["id"]]
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        assert digest == source["sha256"], f"Original output bytes changed: {path}"
        with Image.open(path) as bitmap:
            bitmap.load()
            assert bitmap.mode == "RGBA", f"Missing RGBA: {path}"
            alpha = bitmap.getchannel("A")
            assert alpha.getextrema() == (0, 255), f"Missing transparency/opaque subject: {path}"
            bounds = alpha.getbbox()
            assert bounds is not None and min(bitmap.size) >= 512, f"Empty/undersized bitmap: {path}"
            manifest.append({
                "id": job["id"], "name": job["name"], "category": job["category"],
                "file": path.name, "sha256": digest, "source_output": source["source_output"],
                "size": list(bitmap.size), "mode": bitmap.mode,
                "alpha_range": list(alpha.getextrema()), "alpha_bounds": list(bounds),
                "art_status": "GENERATED", "gameplay_status": "NOT_IMPLEMENTED",
            })
    (ASSETS / "manifest.json").write_text(json.dumps({
        "generator": "built-in image_gen", "original_outputs_preserved": True,
        "scope": "12-item follow-up batch", "assets": manifest,
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"PASS: {len(manifest)} original RGBA assets; SHA-256 and transparent/opaque pixels verified.")
    print("No images, gameplay state, production catalogue or simulation code were modified by this check.")

if __name__ == "__main__":
    main()
