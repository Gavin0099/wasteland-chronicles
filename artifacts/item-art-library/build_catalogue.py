"""Build an art-only coverage index from the owner catalogue and original PNGs."""
import argparse
import hashlib
import json
import re
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LIBRARY = ROOT / "ui/assets/items/library"
GROUPS = ["weapons", "clothing", "supplies", "relics"]
EXISTING = {
    "生鏽小刀": "candidates/rusty_knife.png", "獵刀": "candidates/hunting_knife.png",
    "撬棍": "crowbar.png", "鋼筋棍": "candidates/rebar_club.png",
    "廢鐵砍刀": "candidates/scrap_machete.png", "舊工作服": "candidates/work_clothes.png",
    "沙地長袍": "candidates/desert_robe.png", "商隊外套": "candidates/caravan_coat.png",
    "舊旅行包": "candidates/travel_backpack.png", "水壺": "water.png",
    "乾糧": "food.png", "繩索": "candidates/rope.png",
    "手電筒": "candidates/flashlight.png", "急救包": "candidates/medkit.png",
    "扳手": "candidates/wrench.png", "燃料": "fuel.png",
}


def catalogue_rows():
    rows, sections = [], {}
    current = None
    for line in (ROOT / "docs/item-world-v0.md").read_text(encoding="utf-8-sig").splitlines():
        heading = re.match(r"^## (\d+)\. (.+)$", line)
        if heading:
            current = int(heading[1])
            sections[current] = heading[2]
        elif line.startswith("## "):
            current = None
        elif current and line.startswith("| "):
            cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
            if cells[0] not in ("物品", "材料", "名稱") and not cells[0].startswith("---"):
                rows.append({"section": current, "name": cells[0]})
    assert len(rows) == 187 and len(sections) == 15, "Owner catalogue topology changed"
    return rows, sections


def inspect_png(path):
    with Image.open(path) as bitmap:
        bitmap.load()
        assert bitmap.mode == "RGBA", f"RGBA required: {path}"
        alpha = bitmap.getchannel("A")
        assert alpha.getextrema() == (0, 255) and alpha.getbbox(), f"Transparency missing: {path}"
        assert min(bitmap.size) >= 512, f"Undersized image: {path}"
        return {"sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                "size": list(bitmap.size), "mode": bitmap.mode,
                "alpha_bounds": list(alpha.getbbox()), "alpha_range": [0, 255]}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    rows, sections = catalogue_rows()
    names = list(dict.fromkeys(row["name"] for row in rows))
    assert len(names) == 185
    baseline_hashes = {}
    for folder in [ROOT / "ui/assets/items", ROOT / "ui/assets/items/candidates"]:
        manifest = json.loads((folder / "manifest.json").read_text(encoding="utf-8-sig"))
        for asset in manifest["assets"]:
            baseline_hashes[folder / asset["file"]] = asset["sha256"]
    jobs = {}
    for group in GROUPS:
        source = LIBRARY / group / "prompts.json"
        for job in json.loads(source.read_text(encoding="utf-8-sig"))["jobs"]:
            assert job["name"] not in jobs and job["name"] not in EXISTING, job["name"]
            jobs[job["name"]] = (group, job)
    assert len(jobs) == 169 and set(jobs) | set(EXISTING) == set(names), "Art plan must cover every name exactly once"
    index = []
    for name in names:
        memberships = [row["section"] for row in rows if row["name"] == name]
        entry = {"name": name, "sections": memberships, "art_role": "item_illustration"}
        if name in EXISTING:
            path = ROOT / "ui/assets/items" / EXISTING[name]
            entry.update({"file": path.relative_to(ROOT).as_posix(), "status": "EXISTING_ART",
                          "prompt_file": "ui/assets/items/" + ("candidates/" if "candidates/" in EXISTING[name] else "") + "prompts.json"})
            entry.update(inspect_png(path))
            assert entry["sha256"] == baseline_hashes[path], f"Baseline image changed: {path}"
        else:
            group, job = jobs[name]
            relative = f"ui/assets/items/library/{group}/{job['id']}.png"
            entry.update({"file": relative, "status": "PENDING", "art_role": job.get("art_role", "item_illustration"),
                          "prompt_file": f"ui/assets/items/library/{group}/prompts.json"})
            record_file = LIBRARY / group / "records" / (job["id"] + ".json")
            if record_file.exists():
                record = json.loads(record_file.read_text(encoding="utf-8-sig"))
                assert record["name"] == name and record["file"] == relative
                observed = inspect_png(ROOT / relative)
                assert observed["sha256"] == record["sha256"], f"Original bytes changed: {relative}"
                entry.update(observed)
                entry.update({"status": "GENERATED", "source_output": record["source_output"]})
        index.append(entry)
    pending = [entry["name"] for entry in index if entry["status"] == "PENDING"]
    payload = {"scope": "Item World V0 inventory artwork; not a runtime item registry",
               "source": "docs/item-world-v0.md", "catalogue_rows": 187, "unique_names": 185,
               "existing_art": 16, "new_generated": 169 - len(pending), "pending": len(pending),
               "sections": [{"id": number, "name": title} for number, title in sections.items()],
               "items": index}
    (LIBRARY / "catalogue.json").write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    navigation = ["# 物品世界 V0 素材圖庫", "",
                  f"圖片覆蓋：{185-len(pending)}／185 個名稱。完整清單 187 列，鹽與電池跨分類共用。",
                  "", "這是美術索引，圖片不代表物品玩法已實裝。原始 PNG 與完整提示詞均已保留。",
                  "", "## 分類圖集", "", "| 分類 | 項目數 | 預覽 |", "| --- | ---: | --- |"]
    for number, title in sections.items():
        count = sum(row["section"] == number for row in rows)
        page_links = " / ".join(f"[第 {page} 頁](category-{number:02}-{page:02}.png)" for page in range(1, (count + 11) // 12 + 1))
        navigation.append(f"| {title} | {count} | {page_links} |")
    navigation += ["", "## 原圖", "", "| 名稱 | 素材 |", "| --- | --- |"]
    for entry in index:
        target = "../../" + entry["file"]
        label = "PNG 原圖" if entry["status"] != "PENDING" else "待完成"
        navigation.append(f"| {entry['name']} | [{label}]({target}) |")
    (ROOT / "artifacts/item-art-library/INDEX.md").write_text("\n".join(navigation) + "\n", encoding="utf-8")
    print(f"Art coverage: {185-len(pending)}/185 names; 16 existing + {169-len(pending)}/169 new; {len(pending)} pending.")
    if pending and args.require_complete:
        raise SystemExit("INCOMPLETE: " + ", ".join(pending))
    if args.require_complete:
        print("PASS: every catalogue name resolves to a verified transparent original PNG.")


if __name__ == "__main__":
    main()
