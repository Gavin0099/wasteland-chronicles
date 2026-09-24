"""Export immutable editorial references from the completed art catalogue."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
art = json.loads((ROOT / "ui/assets/items/library/catalogue.json").read_text(encoding="utf-8"))
baseline = {
    "生鏽小刀": ("rusted_knife", 250), "獵刀": ("hunting_knife", 400),
    "鋼筋棍": ("rebar_club", 1800), "廢鐵砍刀": ("scrap_machete", 1200),
    "舊工作服": ("work_clothes", 1200), "沙地長袍": ("desert_robe", 900),
    "商隊外套": ("caravan_coat", 1500), "舊旅行包": ("travel_backpack", 1100),
    "繩索": ("rope", 2500), "手電筒": ("flashlight", 400),
    "扳手": ("wrench", 700), "急救包": ("first_aid_kit", 800),
}
rows = []
for item in art["items"]:
    runtime_id, weight = baseline.get(item["name"], (None, None))
    slug = runtime_id or Path(item["file"]).stem
    rows.append({"content_id": "content_" + slug, "name_zh": item["name"],
                 "art_file": item["file"], "art_sections": item["sections"],
                 "art_role": item["art_role"], "runtime_item_id": runtime_id,
                 "baseline_weight_g": weight})
assert len(rows) == len({row["content_id"] for row in rows}) == 185
(HERE / "item-seeds.json").write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("PASS: 185 editorial IDs; twelve explicit runtime references; no registration performed.")
