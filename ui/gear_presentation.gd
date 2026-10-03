extends RefCounted

# Detached comparisons of held gear. Hypothetical equipment exists only on copies.
const Registry = preload("res://simulation/item_registry.gd")
const Gear = preload("res://simulation/gear_rules.gd")
const Field = preload("res://simulation/field_adventure.gd")
const Properties = preload("res://game_data/gear_property_profiles.gd")
const Rumors = preload("res://simulation/rumors.gd")
const Trust = preload("res://simulation/local_trust.gd")
const Request = preload("res://simulation/companion_request.gd")
const QUALITY_NAMES := {"COMMON": "普通", "MODIFIED": "改良", "RARE": "稀有", "UNIQUE": "獨特"}

static func name_for(id: String) -> String:
	var found: Dictionary = Registry.resolve(id)
	return String(found.definition.display_name_zh) if found.success else "未裝備"

static func stats(world: WorldState, id: String, slot: String = "") -> Dictionary:
	var copy: WorldState = world.duplicate_state()
	copy.field_state.battle = {"prepared": false, "turn": 0}
	if slot != "" and id != "":
		copy.player.equipment.equip(id, slot, copy.player.item_inventory)
	var out := {"weight_g": 0, "lines": [], "properties": []}
	var found: Dictionary = Registry.resolve(id)
	if found.success:
		out.weight_g = int(found.definition.base_weight)
		out.lines.append("重量 %.2f 公斤" % (float(out.weight_g) / 1000.0))
		out.lines.append("基價 %d 瓶蓋" % int(found.definition.base_value))
		for property: String in found.definition.properties:
			out.properties.append(String(Properties.DESCRIPTIONS[property]))
	if slot == "main_hand":
		out.melee = Field.attack_damage(copy)
		out.lines.append("常態近戰傷害 %d" % int(out.melee))
		var gun: Dictionary = Field.firearm_for(copy)
		out.shot = Field.shot_damage(copy) if not gun.is_empty() else 0
		out.ammo = int(gun.get("ammo_spent", 0))
		if not gun.is_empty():
			out.lines.append("常態射擊傷害 %d · 每次耗 %s ×%d" % [int(out.shot), name_for(gun.ammo_item_id), int(out.ammo)])
			out.lines.append("持有彈藥 %d" % copy.player.item_inventory.quantity(gun.ammo_item_id))
		else:
			out.lines.append("無射擊方式")
		out.lines.append("撤退受傷 %d" % Field.flee_damage(copy))
	elif slot == "body":
		out.protection = Gear.protection(copy.player)
		out.lines.append("防護 %d · 生存物資容量 %d" % [int(out.protection), copy.player.get_effective_capacity()])
	elif slot == "back":
		out.capacity = copy.player.get_effective_capacity()
		out.lines.append("生存物資容量 %d · 敗退失水 %d" % [int(out.capacity), Gear.defeat_water_loss(copy.player)])
	for skill: String in ["MECHANICS", "ELECTRONICS"]:
		var grade: int = Gear.grade_for(id, skill)
		if grade > 0:
			out.lines.append("%s工具 %d · 知識等級另外判定" % ["機械" if skill == "MECHANICS" else "電子", grade])
	if found.success:
		out.lines.append(String(found.definition.description_zh))
	return out

static func project(world: WorldState) -> Dictionary:
	var out := {"details": {}, "tools": [], "experiences": [], "aspiration": {}}
	if world == null or world.player == null:
		return out
	for entry: Dictionary in world.player.item_inventory.to_dict().items:
		var id: String = entry.item_id
		var definition: Dictionary = Registry.resolve(id).definition
		var slots: Array = definition.equip_slots
		var slot: String = String(slots[0]) if not slots.is_empty() else ""
		var current: String = world.player.equipment.equipped_item(slot) if slot != "" else ""
		if slot == "":
			if Gear.grade_for(id, "MECHANICS") > 0: current = Gear.best_tool(world.player, "MECHANICS")
			elif Gear.grade_for(id, "ELECTRONICS") > 0: current = Gear.best_tool(world.player, "ELECTRONICS")
		out.details[id] = {"id": id, "name": String(definition.display_name_zh), "tier": String(definition.tier),
			"quality": QUALITY_NAMES[definition.quality], "slot": slot,
			"equipped": slot != "" and current == id, "current_id": current,
			"current_name": name_for(current), "candidate": stats(world, id, slot), "current": stats(world, current, slot)}
	for skill: String in ["MECHANICS", "ELECTRONICS"]:
		var id: String = Gear.best_tool(world.player, skill)
		out.tools.append({"skill": skill, "item_id": id, "name": name_for(id) if id != "" else "未持有工具",
			"grade": Gear.tool_grade(world.player, skill), "rank": world.player.capability.get_rank(skill)})
	for town: String in Trust.TOWNS:
		var score: int = Trust.score(world, town)
		if score != 0:
			out.experiences.append(Trust.summary(world, town))
	var shared: Dictionary = Request.state(world)
	if shared.error == "" and not shared.shared.is_empty():
		out.experiences.append("曾與阿扳找回扳手" + ("；已交還，往後雇費 25 瓶蓋。" if shared.tool_given else "；還留著交還的承諾。"))
	var seen: bool = not world.field_state.battle.is_empty() and Field.battle_enemy(world.field_state) == "heavy_raider"
	for evt: EventRecord in world.event_log:
		if evt.actor_id == world.player.npc_id and evt.type == "FIELD_RESULT" and evt.payload.get("enemy") == "heavy_raider":
			seen = true
	if seen: out.experiences.append("見過重裝掠奪者：他的蓄力重擊需要留意。")
	for rumor: Dictionary in Rumors.project(world):
		if bool(rumor.tracked):
			out.aspiration = rumor.duplicate(true)
	return out
