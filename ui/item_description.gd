extends RefCounted

# Public item facts only: no world reference, stock, hidden clue or mutation.
const Registry = preload("res://simulation/item_registry.gd")
const Weapons = preload("res://simulation/weapon_rules.gd")
const Gear = preload("res://simulation/gear_rules.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Properties = preload("res://game_data/gear_property_profiles.gd")
const SUPPLIES := {
	"water": "飲水供旅途每天消耗；同行同伴也需要水。可交易或交付運補。",
	"food": "食物供旅途每天消耗；同行同伴也需要口糧。可交易或交付運補。",
	"scrap": "廢料可製作撬棍、支付場景維修成本，也可交易與運補。",
	"fuel": "燃料可交易與運補，交到缺油聚落的倉庫；步行不耗燃料。",
}

static func text(id: String) -> String:
	if SUPPLIES.has(id): return String(SUPPLIES[id])
	var found: Dictionary = Registry.resolve(id)
	if not found.success: return ""
	var definition: Dictionary = found.definition
	var base: String = Properties.base_item(id)
	var use: String = ""
	var gun: Dictionary = Weapons.firearm(id)
	if Field.TREATMENT_HEALING.has(id):
		use = "聚落休整或迷宮戰鬥間使用，消耗1個、恢復最多%d生命；戰鬥與待確認事件中不能使用。" % int(Field.TREATMENT_HEALING[id])
	elif not gun.is_empty():
		use = "裝備到主手：基礎射擊傷害%d，再加槍械等級；每次消耗%s×%d。" % [int(gun.damage), Registry.resolve(String(gun.ammo_item_id)).definition.display_name_zh, int(gun.ammo_spent)]
	elif Weapons.MELEE_BONUSES.has(base):
		use = "裝備到主手：近戰傷害加成+%d，近戰等級與架勢另計；使用後保留。" % int(Weapons.MELEE_BONUSES[base])
	elif base in ["revolver_round", "shotgun_shell"]:
		use = "裝備對應的%s後射擊，每次消耗1發；沒有彈藥仍可近戰或撤退。" % ("左輪槍" if base == "revolver_round" else "霰彈槍")
	elif id == "military_gas_mask":
		use = "攜帶可進入污染工坊；需先追尋對應傳聞並準備場景成本。使用後保留，不提供戰鬥防護。"
	elif "body" in definition.equip_slots:
		use = "裝備到身體：基礎防護%d，每次敵方反擊減傷；使用後保留。" % int(Gear.PROTECTION.get(base, 0))
	elif "back" in definition.equip_slots:
		use = "裝備到背部：生存物資容量+%d；正式物品公斤容量另外計算。" % int(Gear.PACK_CARGO.get(base, 0))
	elif id == "rope":
		use = "落石擋路時可固定路線，不耗廢料、不耽誤行程；繩索保留，也可交付運送委託。"
	elif id == "flashlight":
		use = "可交易的照明用品；目前沒有額外戰鬥或探索加成。"
	else:
		for skill: String in ["MECHANICS", "ELECTRONICS"]:
			var grade: int = Gear.grade_for(id, skill)
			if grade > 0:
				use = "攜帶即可提供%s工具%d；技能等級與材料成本另外判定，工具保留。" % ["機械" if skill == "MECHANICS" else "電子", grade]
		if id == "wrench": use += " 也可拆解旅途殘骸，耗時1天。"
	if use.is_empty(): use = "可交易；其他用途以當前場景或委託選項為準。"
	var lines: PackedStringArray = [String(definition.description_zh), "用途：" + use]
	for property: String in definition.properties:
		lines.append(String(Properties.DESCRIPTIONS[property]))
	return "\n".join(lines)
