extends RefCounted

const ItemRegistry = preload("res://simulation/item_registry.gd")
const Capability = preload("res://simulation/capability_profile.gd")

const HOME := "settlement:gray_valley"
const MAX_HP := 12
const ENEMY_HP := 8
const BANDIT_HP := 8
const KIT_WEIGHT := 2
const COMMANDS := ["CRAFT", "EQUIP", "UNEQUIP", "START", "ATTACK", "DEFEND", "FLEE", "OPEN", "REST", "CONFIRM"]

static func new_kit() -> Dictionary:
	return {"hp": MAX_HP, "crowbar": false, "equipped": false}

static func new_state() -> Dictionary:
	return {"enemy_hp": ENEMY_HP, "opened": false, "next_id": 1, "battle": {}, "receipt": -1}

static func begin_road_battle(world, _enc_context: Dictionary = {}) -> Dictionary:
	var state: Dictionary = world.field_state
	state.battle = {
		"id": state.next_id,
		"turn": 1,
		"prepared": false,
		"source": "road",
	}
	state.enemy_hp = BANDIT_HP
	state.next_id += 1
	state.receipt = -1
	return state.battle.duplicate(true)

static func integer(value: Variant, low: int, high: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and value == floor(float(value)) and value >= low and value <= high

static func validate_kit(kit: Variant) -> String:
	if typeof(kit) != TYPE_DICTIONARY or kit.size() != 3 or not integer(kit.get("hp"), 0, MAX_HP):
		return "INVALID_FIELD_KIT"
	for key in ["crowbar", "equipped"]:
		if typeof(kit.get(key)) != TYPE_BOOL:
			return "INVALID_FIELD_KIT"
	if kit.equipped and not kit.crowbar:
		return "UNOWNED_EQUIPMENT"
	return ""

static func validate_state(state: Variant) -> String:
	if typeof(state) != TYPE_DICTIONARY or state.size() != 5:
		return "INVALID_FIELD_STATE"
	if not integer(state.get("enemy_hp"), 0, ENEMY_HP) or typeof(state.get("opened")) != TYPE_BOOL or not integer(state.get("next_id"), 1, 2147483647) or not integer(state.get("receipt"), -1, 2147483647) or typeof(state.get("battle")) != TYPE_DICTIONARY:
		return "INVALID_FIELD_STATE"
	if state.opened and state.enemy_hp > 0:
		return "INVALID_FIELD_SITE"
	var battle = state.battle
	if not battle.is_empty():
		if battle.has("source") and typeof(battle.get("source")) != TYPE_STRING:
			return "INVALID_FIELD_BATTLE"
		for req_key in ["id", "turn", "prepared"]:
			if not battle.has(req_key):
				return "INVALID_FIELD_BATTLE"
		if not integer(battle.get("id"), 1, int(state.next_id) - 1) or battle.id != state.next_id - 1 or not integer(battle.get("turn"), 1, 2147483647) or typeof(battle.get("prepared")) != TYPE_BOOL:
			return "INVALID_FIELD_BATTLE"
		if state.enemy_hp <= 0 or state.receipt >= 0:
			return "INVALID_FIELD_BATTLE"
	return ""

static func validate_wire(data: Dictionary) -> String:
	var events: Variant = data.get("events", [])
	if typeof(events) != TYPE_ARRAY:
		return "INVALID_FIELD_EVENTS"
	for event_index in range(events.size()):
		var raw_event: Variant = events[event_index]
		if typeof(raw_event) != TYPE_DICTIONARY or raw_event.get("type") not in ["FIELD_TURN", "FIELD_RESULT", "FIELD_ACTION"]:
			continue
		var event_payload: Variant = raw_event.get("payload", {})
		if typeof(event_payload) != TYPE_DICTIONARY or not event_payload.has("skill_practice"):
			continue
		var expected_skill := "MECHANICS" if raw_event.type == "FIELD_ACTION" else "MELEE"
		if not Capability.valid_practice_award(event_payload.skill_practice, expected_skill):
			return "INVALID_FIELD_PRACTICE_RECEIPT"
		if raw_event.type == "FIELD_ACTION" and event_payload.get("command") != "CRAFT":
			return "INVALID_FIELD_PRACTICE_ACTION"
		if raw_event.type == "FIELD_TURN" and (event_payload.get("command") != "ATTACK" or not integer(event_payload.get("dealt"), 1, ENEMY_HP)):
			return "INVALID_FIELD_PRACTICE_TURN"
		if raw_event.type == "FIELD_RESULT" and event_payload.get("outcome") != "VICTORY":
			return "INVALID_FIELD_PRACTICE_RESULT"
		if raw_event.type == "FIELD_RESULT":
			if event_index == 0:
				return "INVALID_FIELD_PRACTICE_RESULT"
			var previous: Variant = events[event_index - 1]
			if typeof(previous) != TYPE_DICTIONARY or previous.get("type") != "FIELD_TURN" or previous.get("actor_id") != raw_event.get("actor_id") or previous.get("day") != raw_event.get("day"):
				return "INVALID_FIELD_PRACTICE_RESULT"
			var turn_payload: Variant = previous.get("payload", {})
			if typeof(turn_payload) != TYPE_DICTIONARY or turn_payload.get("command") != "ATTACK" or turn_payload.get("enemy_hp") != 0 or turn_payload.get("skill_practice", {}) != event_payload.skill_practice:
				return "INVALID_FIELD_PRACTICE_RESULT"
	var player = data.get("player", {})
	if not data.has("field_schema_version"):
		if data.has("field_state") or (typeof(player) == TYPE_DICTIONARY and player.has("field_kit")):
			return "MISSING_FIELD_SCHEMA"
		return ""
	if not integer(data.field_schema_version, 1, 1):
		return "UNSUPPORTED_FIELD_SCHEMA"
	var error = validate_state(data.get("field_state"))
	if error != "":
		return error
	if typeof(player) == TYPE_DICTIONARY and not player.is_empty():
		return validate_kit(player.get("field_kit"))
	return ""

static func normalize_state(state: Dictionary) -> Dictionary:
	var out = state.duplicate(true)
	for key in ["enemy_hp", "next_id", "receipt"]:
		out[key] = int(out[key])
	if not out.battle.is_empty():
		out.battle.id = int(out.battle.id)
		out.battle.turn = int(out.battle.turn)
	return out

static func validate_world(world) -> String:
	var error = validate_state(world.field_state)
	if error != "":
		return error
	var state = world.field_state
	if world.player == null:
		return "ORPHAN_FIELD_STATE" if not state.battle.is_empty() or state.receipt >= 0 else ""
	error = validate_kit(world.player.field_kit)
	if error != "":
		return error
	var life = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life == null:
		return "FIELD_OWNER_MISSING"
	if life.is_alive() and world.player.field_kit.hp == 0:
		return "FIELD_DEATH_NOT_COMMITTED"
	if not state.battle.is_empty():
		var source: String = String(state.battle.get("source", "field"))
		if not life.is_alive() or world.active_encounter != null or world.pending_encounter_result >= 0:
			return "FIELD_BATTLE_CONFLICT"
		if source == "road":
			if life.status != NpcLifeState.Status.IN_TRANSIT:
				return "FIELD_BATTLE_CONFLICT"
		else:
			if String(life.population_container_id) != HOME or life.status != NpcLifeState.Status.SETTLED:
				return "FIELD_BATTLE_CONFLICT"
	if state.receipt >= 0:
		if state.receipt >= world.event_log.size() or world.active_encounter != null or world.pending_encounter_result >= 0:
			return "INVALID_FIELD_RECEIPT"
		var event = world.event_log[state.receipt]
		if event.type != "FIELD_RESULT" or event.actor_id != world.player.npc_id or event.payload.get("hp") != world.player.field_kit.hp or event.payload.get("outcome") not in ["VICTORY", "ESCAPED", "DEAD", "CACHE", "DEFEAT"]:
			return "INVALID_FIELD_RECEIPT"
	return ""

static func authorize(world, payload: Dictionary) -> String:
	var error = validate_world(world)
	if error != "":
		return error
	var command = payload.get("command")
	if typeof(command) != TYPE_STRING or command not in COMMANDS:
		return "INVALID_FIELD_COMMAND"
	var state = world.field_state
	if command == "CONFIRM":
		if payload.size() != 2 or typeof(payload.get("receipt")) != TYPE_INT or payload.receipt != state.receipt or state.receipt < 0:
			return "STALE_FIELD_RECEIPT"
		return ""
	if world.pending_encounter_result >= 0 or world.active_encounter != null:
		return "ROAD_ENCOUNTER_PENDING"
	if state.receipt >= 0:
		return "FIELD_RESULT_PENDING"
	var player = world.player
	var life = world.npc_life_state_registry.get_life_state(player.npc_id)
	var is_road: bool = not state.battle.is_empty() and String(state.battle.get("source", "field")) == "road"
	if is_road:
		if not life.is_alive() or life.status != NpcLifeState.Status.IN_TRANSIT:
			return "FIELD_REQUIRES_LIVING_TRANSIT_PLAYER"
	else:
		if not life.is_alive() or life.status != NpcLifeState.Status.SETTLED:
			return "FIELD_REQUIRES_LIVING_SETTLED_PLAYER"
	if command in ["ATTACK", "DEFEND", "FLEE"]:
		if state.battle.is_empty() or payload.size() != 3 or typeof(payload.get("battle_id")) != TYPE_INT or typeof(payload.get("turn")) != TYPE_INT or payload.battle_id != state.battle.id or payload.turn != state.battle.turn:
			return "STALE_FIELD_TURN"
		return ""
	if not state.battle.is_empty():
		return "BATTLE_PENDING"
	if is_road:
		return "INVALID_ROAD_COMMAND"
	if payload.size() != 1:
		return "INVALID_FIELD_PAYLOAD"
	match command:
		"CRAFT":
			if player.field_kit.crowbar:
				return "CROWBAR_ALREADY_OWNED"
			if player.inventory.scrap < 3:
				return "NEED_SCRAP_3"
			if player.get_total_inventory_load() - 3 + KIT_WEIGHT > player.capacity_total:
				return "PACK_FULL"
		"EQUIP", "UNEQUIP":
			if not player.field_kit.crowbar:
				return "NEED_CROWBAR"
			if player.field_kit.equipped == (command == "EQUIP"):
				return "EQUIPMENT_ALREADY_SET"
		"START", "OPEN":
			if String(life.population_container_id) != HOME:
				return "RETURN_TO_GRAY_VALLEY"
			if command == "START" and state.enemy_hp <= 0:
				return "SITE_ALREADY_CLEARED"
			if command == "OPEN":
				if state.enemy_hp > 0:
					return "DOG_GUARDS_CACHE"
				if state.opened:
					return "CACHE_ALREADY_OPENED"
				if not player.field_kit.crowbar:
					return "NEED_CROWBAR"
		"REST":
			if player.field_kit.hp >= MAX_HP:
				return "HEALTH_FULL"
	return ""

static func attack_damage(world) -> int:
	var base = 3 if world.player.field_kit.equipped else 2
	var rank = world.player.capability.get_skill_rank("MELEE")
	var bonus = 2 if world.field_state.battle.get("prepared", false) else 0
	return base + _equipped_main_hand_bonus(world) + int(rank.rank) + bonus

static func _equipped_main_hand_bonus(world) -> int:
	if world == null or world.player == null or world.player.equipment == null:
		return 0
	var item_id: String = world.player.equipment.equipped_item("main_hand")
	match item_id:
		"rusted_knife": return 1
		"hunting_knife": return 2
		"rebar_club": return 2
		"scrap_machete": return 3
		_: return 0

static func enemy_damage(turn: int) -> int:
	return 4 if turn % 3 == 0 else 2

static func finish(world, outcome: String, gains: Dictionary = {}, left: Dictionary = {}, source: String = "field", caps_gained: int = 0, practice: Dictionary = {}) -> void:
	world.field_state.battle = {}
	var is_road := source == "road"
	var container_id = StringName(HOME)
	if is_road:
		var ls = world.npc_life_state_registry.get_life_state(world.player.npc_id)
		if ls != null:
			container_id = ls.population_container_id
	var payload := {
		"outcome": outcome,
		"hp": world.player.field_kit.hp,
		"gained": gains,
		"left_behind": left if outcome != "DEFEAT" else {}
	}
	if is_road:
		payload["source"] = "road"
		if outcome == "DEFEAT":
			payload["lost"] = left
		if caps_gained > 0:
			payload["caps_gained"] = caps_gained
	if not practice.is_empty():
		payload["skill_practice"] = practice.duplicate(true)
	world.record_event(EventRecord.new(world.current_day, "FIELD_RESULT", world.player.npc_id, container_id, payload))
	world.field_state.receipt = world.event_log.size() - 1

static func apply(world, engine, payload: Dictionary) -> String:
	var player = world.player
	var state = world.field_state
	var command = payload.command
	var action_payload := {"command": command}
	match command:
		"CONFIRM":
			state.receipt = -1
		"CRAFT":
			player.inventory.scrap -= 3
			player.field_kit.crowbar = true
			if player.capability != null:
				var growth: Dictionary = player.capability.grant_practice("MECHANICS", world.current_day)
				if growth.get("awarded", false):
					action_payload["skill_practice"] = {"skill_id": "MECHANICS", "rank_up": growth.rank_up,
						"from_rank": growth.from_rank, "to_rank": growth.to_rank,
						"points": growth.points, "required": growth.required}
		"EQUIP", "UNEQUIP":
			player.field_kit.equipped = command == "EQUIP"
		"START":
			state.battle = {"id": state.next_id, "turn": 1, "prepared": false}
			state.next_id += 1
		"REST":
			engine.tick(world)
			if world.npc_life_state_registry.get_life_state(player.npc_id).is_alive():
				player.field_kit.hp = mini(MAX_HP, player.field_kit.hp + 4)
		"OPEN":
			var gains = {}
			var left = {}
			for id in ["water", "food"]:
				var offered = 4 if id == "water" else 2
				var amount = mini(offered, maxi(0, player.capacity_total - player.get_total_inventory_load()))
				if amount > 0:
					player.inventory.add_amount(id, amount)
					gains[id] = amount
				if amount < offered:
					left[id] = offered - amount
			state.opened = true
			finish(world, "CACHE", gains, left)
		"ATTACK", "DEFEND", "FLEE":
			var battle = state.battle
			var turn = battle.turn
			var source: String = String(battle.get("source", "field"))
			var is_road: bool = source == "road"
			var dealt = 0
			var taken = 0
			if command == "ATTACK":
				dealt = mini(state.enemy_hp, attack_damage(world))
				state.enemy_hp -= dealt
				battle.prepared = false
			var practice := {}
			if command == "ATTACK" and dealt > 0 and player.capability != null:
				var growth: Dictionary = player.capability.grant_practice("MELEE", world.current_day)
				if growth.get("awarded", false):
					practice = {"skill_id": "MELEE", "rank_up": growth.rank_up,
						"from_rank": growth.from_rank, "to_rank": growth.to_rank,
						"points": growth.points, "required": growth.required}
			if command == "DEFEND":
				battle.prepared = true
			if state.enemy_hp > 0:
				var raw_damage: int = 1 if command == "FLEE" else maxi(0, enemy_damage(turn) - (3 if command == "DEFEND" else 0))
				if is_road:
					if command == "FLEE":
						taken = mini(raw_damage, maxi(0, player.field_kit.hp - 1))
					else:
						if raw_damage >= player.field_kit.hp:
							taken = maxi(0, player.field_kit.hp - 1)
						else:
							taken = raw_damage
				else:
					taken = mini(raw_damage, player.field_kit.hp)
				player.field_kit.hp -= taken

			var container_id: StringName = StringName(HOME)
			if is_road:
				var ls = world.npc_life_state_registry.get_life_state(player.npc_id)
				if ls != null:
					container_id = ls.population_container_id
			var turn_payload := {"battle_id": battle.id, "turn": turn, "command": command,
				"dealt": dealt, "taken": taken, "hp": player.field_kit.hp, "enemy_hp": state.enemy_hp}
			if not practice.is_empty():
				turn_payload["skill_practice"] = practice
			world.record_event(EventRecord.new(world.current_day, "FIELD_TURN", player.npc_id, container_id, turn_payload))

			if is_road:
				if state.enemy_hp == 0:
					var gains := {}
					var left := {}
					var offered_scrap := 2
					var can_take := mini(offered_scrap, maxi(0, player.capacity_total - player.get_total_inventory_load()))
					if can_take > 0:
						player.inventory.add_amount("scrap", can_take)
						gains["scrap"] = can_take
					if can_take < offered_scrap:
						left["scrap"] = offered_scrap - can_take
					player.money += 5
					finish(world, "VICTORY", gains, left, "road", 5, practice)
				elif command == "FLEE":
					finish(world, "ESCAPED", {}, {}, "road")
				elif player.field_kit.hp == 1 and (enemy_damage(turn) - (3 if command == "DEFEND" else 0)) >= 1:
					var water_lost: int = clampi(2, 0, player.inventory.get_amount("water"))
					var food_lost: int = clampi(1, 0, player.inventory.get_amount("food"))
					var caps_lost: int = clampi(10, 0, player.money)
					if water_lost > 0:
						player.inventory.add_amount("water", -water_lost)
					if food_lost > 0:
						player.inventory.add_amount("food", -food_lost)
					if caps_lost > 0:
						player.money -= caps_lost
					var lost_dict := {}
					if water_lost > 0: lost_dict["water"] = water_lost
					if food_lost > 0: lost_dict["food"] = food_lost
					if caps_lost > 0: lost_dict["caps"] = caps_lost
					finish(world, "DEFEAT", {}, lost_dict, "road")
				else:
					battle.turn += 1
			else:
				if player.field_kit.hp == 0:
					var death = world.npc_life_state_registry.commit_named_death(world, player.npc_id)
					if not death.success:
						return death.error
					world.record_event(EventRecord.new(world.current_day, "PLAYER_DIED", player.npc_id, StringName(HOME), {"cause": "field_combat", "days_survived": world.current_day, "in_transit": false}))
					finish(world, "DEAD")
				elif state.enemy_hp == 0:
					finish(world, "VICTORY", {}, {}, "field", 0, practice)
				elif command == "FLEE":
					finish(world, "ESCAPED")
				else:
					battle.turn += 1
			world.record_event(EventRecord.new(world.current_day, "FIELD_ACTION", player.npc_id, container_id, {"command": command}))
			return ""
	world.record_event(EventRecord.new(world.current_day, "FIELD_ACTION", player.npc_id, StringName(HOME), action_payload))
	return ""

static func commit(world, engine, payload: Dictionary) -> Dictionary:
	var error = engine.validate_invariants(world)
	if error == "":
		error = authorize(world, payload)
	if error != "":
		return {"success": false, "error": error}
	var staged = world.duplicate_state()
	error = apply(staged, engine, payload)
	if error == "":
		error = engine.validate_invariants(staged)
	if error != "":
		return {"success": false, "error": error}
	# Publish every owned world field because REST runs the real day simulation.
	for key in ["current_day", "total_initial_population", "next_npc_sequence", "npc_registry", "npc_life_state_registry", "npc_profile_registry", "settlements", "caravans", "refugees", "event_log", "player", "decision_audit_trail", "active_encounter", "pending_encounter_result", "field_state"]:
		world.set(key, staged.get(key))
	var result := {"success": true, "error": "", "action": "FIELD_ACTION"}
	if not world.event_log.is_empty():
		var last_event = world.event_log.back()
		if last_event.type == "FIELD_ACTION" and last_event.payload.get("command") == payload.command and last_event.payload.has("skill_practice"):
			result["skill_practice"] = last_event.payload.skill_practice.duplicate(true)
	return result
