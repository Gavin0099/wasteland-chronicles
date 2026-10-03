extends RefCounted

# Public authored supply, never remote stock or quotes. Unique clues are knowledge gated.
const Registry = preload("res://simulation/item_registry.gd")
const Rumors = preload("res://simulation/rumors.gd")
const TOWNS := {"new_hope": "新希望", "gray_valley": "灰谷", "dry_well": "乾井"}
const UNIQUE_RUMORS := {"military_gas_mask": "rumor:gas_mask", "engineer_precision_tools": "rumor:engineer_tools", "old_world_saber": "rumor:armory", "military_backpack": "rumor:armory"}

static func project(world: WorldState, id: String) -> Dictionary:
	var found: Dictionary = Registry.resolve(id)
	if not found.success or world == null or world.player == null:
		return {}
	var held: bool = world.player.item_inventory.contains(id)
	var rumor_id: String = String(UNIQUE_RUMORS.get(id, ""))
	var heard: bool = rumor_id != "" and Rumors.heard(world, rumor_id)
	if not held and not heard:
		return {}
	var definition: Dictionary = found.definition
	var places: PackedStringArray = []
	for town: String in TOWNS:
		if definition.settlement_supply[town] != "none": places.append(TOWNS[town])
	var source: String = "常見供應：%s。實際庫存與成交價以當地市場為準。" % "、".join(places) if not places.is_empty() else "一般商店沒有常備供應。"
	var use: String = "使用後保留；實際用途以已開放的裝備與場景選項為準。"
	if id == "first_aid_kit":
		use = "停留聚落且沒有戰鬥或待確認事件時使用；消耗1個，恢復最多4生命。"
	elif "ammunition" in definition.tags:
		use = "每次有效射擊消耗1發；需裝備對應槍械，無彈藥仍可近戰或撤退。"
	elif String(definition.category) == "TOOL":
		use = "攜帶工具即可供對應選項使用，工具保留；知識技能另外判定。"
	var pursuit: String = ""
	if id == "military_gas_mask" and held:
		pursuit = "下一步：到新希望或乾井打聽「污染工坊的工程師」，在傳聞頁改選「追這個」，再走乾井—新希望荒野路第一天。帶面具、2廢料與水糧；取工具另耗1天，面具保留。"
	elif heard:
		pursuit = String(Rumors.progress(world, rumor_id).next)
	elif id == "engineer_precision_tools" and held:
		pursuit = "攜帶工具、機械2、3廢料，可花2天精修委託井泵，產水+2/日。"
	return {"source": source, "use": use, "pursuit": pursuit, "rumor_entry": not pursuit.is_empty()}
