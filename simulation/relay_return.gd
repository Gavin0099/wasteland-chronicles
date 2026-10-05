extends RefCounted

const SITE: String = "dungeon:buried_relay"
const HOME: StringName = &"settlement:gray_valley"
const ABBAN: String = "companion:abban"
const COMMANDS: Array[String] = ["ACK_ABBAN_RELAY"]
const EVENT: String = "ABBAN_RELAY_ACKNOWLEDGED"
const Board = preload("res://simulation/job_board.gd")

# A historical candidate is evaluated at each agreement, never against a later trip.
static func state(world: WorldState) -> Dictionary:
	var s: Dictionary = {"operation_index": -1, "return_index": -1, "friend": false, "wrench_friend": false, "trip": {}, "error": ""}
	if world == null or world.player == null: return s
	var companion: String = ""
	var city: String = ""
	var enter: int = -1
	var operation: int = -1
	var dead: bool = false
	var waterworks: bool = false
	var pending: bool = false
	var latest_day: int = -1
	for index: int in range(world.event_log.size()):
		var e: EventRecord = world.event_log[index]
		var p: Dictionary = e.payload
		if e.type.begins_with("ABBAN_RELAY_"):
			var valid: bool = e.type == EVENT and e.actor_id == world.player.npc_id and e.target_id == StringName(ABBAN) and p.size() == 7
			valid = valid and SimulationEngine.Relay.text(p.get("site_id"), SITE) and SimulationEngine.Relay.text(p.get("city_id"), String(HOME)) and SimulationEngine.Relay.text(p.get("companion_id"), ABBAN)
			valid = valid and SimulationEngine.Relay.number(p.get("operation_index"), int(s.operation_index), int(s.operation_index)) and SimulationEngine.Relay.number(p.get("return_index"), int(s.return_index), int(s.return_index)) and s.operation_index >= 0 and s.return_index > s.operation_index and s.return_index < index
			valid = valid and SimulationEngine.Relay.number(p.get("fee_before"), 50, 50) and SimulationEngine.Relay.number(p.get("fee_after"), 25, 25)
			valid = valid and not s.friend and not s.wrench_friend and companion == ABBAN and city == String(HOME) and not dead and enter < 0 and not waterworks and not pending and e.day >= latest_day and e.day <= world.current_day
			if not valid: s.error = "RETURN_INVALID_AGREEMENT"; return s
			s.friend = true
		if e.actor_id != world.player.npc_id: continue
		latest_day = max(latest_day, e.day)
		match e.type:
			"PLAYER_MATERIALIZED", "NAMED_MIGRATION_COMPLETED": city = String(e.target_id); pending = false
			"PLAYER_TRAVEL_STARTED": city = ""
			"PLAYER_DIED", "NAMED_NPC_DIED": dead = true
			"COMPANION_JOINED": companion = String(p.get("companion_id", ""))
			"COMPANION_LEFT": companion = ""; operation = -1
			"COMPANION_REQUEST_COMPLETED": s.wrench_friend = true
			"RELAY_ENTERED": enter = index; operation = -1
			"DOG_REPAIRED":
				if enter >= 0 and companion == ABBAN: operation = index
			"STATION_POWER_CONFIGURED":
				if enter >= 0 and companion == ABBAN and typeof(p.get("mode")) == TYPE_STRING and p.mode in ["TURRET", "LIFT"]: operation = index
			"RELAY_LEFT":
				if enter >= 0:
					s.trip = {"enter_index": enter, "return_index": index, "start_day": world.event_log[enter].day, "end_day": e.day}
					if operation >= enter and companion == ABBAN: s.operation_index = operation; s.return_index = index
				enter = -1; operation = -1
			"RELAY_TRIP_ENDED": enter = -1; operation = -1
			"DUNGEON_ENTERED": waterworks = true
			"DUNGEON_LEFT", "DUNGEON_TRIP_ENDED": waterworks = false
			"RELAY_BATTLE_STARTED", "DUNGEON_BATTLE_STARTED", "ROAD_COMBAT_BEGAN", "PURSUIT_STARTED", "TRAVEL_ENCOUNTER": pending = true
			"FIELD_ACTION":
				if SimulationEngine.Relay.text(p.get("command"), "START"): pending = true
				elif SimulationEngine.Relay.text(p.get("command"), "CONFIRM"): pending = false
			"FIELD_RESULT": pending = true
			"RELAY_BATTLE_CONFIRMED", "DUNGEON_BATTLE_CONFIRMED", "PURSUIT_CONFIRMED": pending = false
	return s

static func validate_world(world: WorldState) -> String:
	if world.player == null: return "RETURN_ORPHAN_AGREEMENT" if world.event_log.any(func(e: EventRecord) -> bool: return e.type.begins_with("ABBAN_RELAY_")) else ""
	return String(state(world).error)

static func intent(world: WorldState) -> PlayerIntent:
	var s: Dictionary = state(world)
	return PlayerIntent.create_dungeon_action(world.player.npc_id, {"site_id": SITE, "command": "ACK_ABBAN_RELAY", "operation_index": int(s.operation_index), "return_index": int(s.return_index)})

static func safe_refusal(world: WorldState) -> String:
	if world == null or world.player == null: return "RETURN_NO_PLAYER"
	var life: NpcLifeState = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	if life == null or not life.is_alive(): return "RETURN_PLAYER_DEAD"
	if life.status != NpcLifeState.Status.SETTLED or life.population_container_id != HOME: return "RETURN_REQUIRES_GRAY"
	if SimulationEngine.Relay.state(world).active or SimulationEngine.Dungeon.state(world).active or SimulationEngine.RelayCustody.pending(world) or world.active_encounter != null or world.pending_encounter_result >= 0 or not world.field_state.battle.is_empty() or world.field_state.receipt >= 0: return "RETURN_ACTIVITY_PENDING"
	return ""

static func authorize(world: WorldState, p: Dictionary) -> String:
	var invalid: String = SimulationEngine.Dungeon.validate_world(world)
	if invalid != "": return invalid
	if p.size() != 4 or not SimulationEngine.Relay.text(p.get("site_id"), SITE) or not SimulationEngine.Relay.text(p.get("command"), "ACK_ABBAN_RELAY"): return "RETURN_INVALID_INTENT"
	invalid = safe_refusal(world)
	if invalid != "": return invalid
	var s: Dictionary = state(world)
	if s.friend or s.wrench_friend: return "RETURN_ALREADY_FRIEND"
	if SimulationEngine.Party.current(world) != ABBAN: return "RETURN_NEED_ABBAN"
	if s.operation_index < 0: return "RETURN_NO_SHARED_OPERATION"
	if typeof(p.get("operation_index")) != TYPE_INT or typeof(p.get("return_index")) != TYPE_INT or p.operation_index != s.operation_index or p.return_index != s.return_index: return "RETURN_STALE_SOURCE"
	return ""

static func commit(world: WorldState, p: Dictionary, events: Array[EventRecord], engine: SimulationEngine) -> Dictionary:
	var invalid: String = authorize(world, p)
	if invalid != "": return {"success": false, "error": invalid}
	if engine == null: return {"success": false, "error": "RETURN_ENGINE_REQUIRED"}
	var staged: WorldState = world.duplicate_state()
	var event: EventRecord = EventRecord.new(staged.current_day, EVENT, staged.player.npc_id, StringName(ABBAN), {"site_id": SITE, "operation_index": p.operation_index, "return_index": p.return_index, "city_id": String(HOME), "companion_id": ABBAN, "fee_before": 50, "fee_after": 25})
	staged.record_event(event)
	invalid = engine.validate_invariants(staged)
	if invalid != "": return {"success": false, "error": invalid}
	world.event_log = staged.event_log
	if events != null: events.append(event)
	return {"success": true, "action": "DUNGEON_ACTION"}

static func note(world: WorldState) -> String:
	var s: Dictionary = state(world)
	if s.friend: return "阿扳記得中繼站那次共同維修。未來在灰谷再雇用他收25瓶蓋；水糧照原本規則準備。" + next_plan(world)
	if s.wrench_friend: return "找回並交還扳手後，再雇用已是25瓶蓋；共同維修不再折價或退款。"
	if s.operation_index >= 0: return "阿扳記得你們在中繼站一起修復設備。回灰谷與他談下一趟，未來再雇用可由50改為25瓶蓋。" + next_plan(world)
	return "尚未與阿扳完成中繼站的共同維修與返城。只是在事後雇用他，不會變成共同經歷。"

static func next_plan(world: WorldState) -> String:
	if safe_refusal(world) != "": return ""
	var jobs: Array = Board.postings(world, HOME)
	for entry: Dictionary in jobs:
		if bool(entry.get("urgent", false)): return "\n阿扳：今天補給吃緊；先看看「%s」，帶好水糧再出發。" % entry.definition.title_zh
	for entry: Dictionary in jobs:
		if entry.archetype == "REPAIR": return "\n阿扳：你回報的舊井還沒修好。可以先接「%s」，工具和零件照委託準備。" % entry.definition.title_zh
	for entry: Dictionary in jobs:
		if entry.archetype == "SALVAGE": return "\n阿扳：再找些零件吧；「%s」可以接。我的扳手請求仍照你之前的答覆。" % entry.definition.title_zh
	return "\n阿扳：先看看現在的委託，再決定下一趟要帶什麼。"

static func project(world: WorldState) -> Dictionary:
	var out: Dictionary = {"available": false, "refusal": safe_refusal(world), "trip": "還沒有完成中繼站往返。", "news": [], "stocks": [], "jobs": [], "abban": note(world)}
	if out.refusal != "": return out
	out.available = true
	var s: Dictionary = state(world)
	var town: SettlementState = world.get_settlement(HOME)
	if not s.trip.is_empty():
		out.trip = "第%d～%d天，中繼站往返已完成。\n軍用背包%s · 機械犬%s" % [s.trip.start_day, s.trip.end_day, "仍在行囊" if world.player.item_inventory.contains("military_backpack") else ("已取走，未在行囊" if SimulationEngine.Relay.state(world).prize_taken else "尚未取得"), "已修復" if SimulationEngine.RelayHound.state(world).repaired else "尚未修復"]
		for index: int in range(int(s.trip.enter_index) + 1, int(s.trip.return_index)):
			var e: EventRecord = world.event_log[index]
			var p: Dictionary = e.payload
			var line: String = ""
			if e.target_id == HOME and e.type == "CARAVAN_ARRIVED" and typeof(p.get("unloaded")) == TYPE_DICTIONARY:
				var goods: PackedStringArray = []
				for resource: String in Board.RESOURCE_NAMES:
					if SimulationEngine.Relay.number(p.unloaded.get(resource, 0), 1, 2147483647): goods.append("%s%d" % [Board.RESOURCE_NAMES[resource], p.unloaded[resource]])
				line = "商隊抵達，卸下" + "、".join(goods) if not goods.is_empty() else "商隊空載抵達，沒有補貨。"
			elif e.target_id == HOME and e.type == "CARAVAN_DESTROYED": line = "前往灰谷的商隊失聯；該趟貨物沒有抵達。"
			elif e.target_id == HOME and e.type == "CARAVAN_LOADED": line = "商隊從灰谷裝貨出發。"
			elif e.target_id == HOME and e.type == "REFUGEES_ARRIVED": line = "旅人抵達灰谷，加入當地生活。"
			elif e.type == "REFUGEES_DEPARTED" and SimulationEngine.Relay.text(p.get("origin"), String(HOME)): line = "有人離開灰谷，動身去別處生活。"
			if line != "": out.news.append({"source_index": index, "day": e.day, "text": line})
		while out.news.size() > 4: out.news.pop_front()
		var disposition: Dictionary = SimulationEngine.RelayDisposition.state(world)
		if disposition.reported: out.trip += "\n灰鴉處置已回報：" + {"LIVE": "活人交付", "DEAD": "死訊", "RELEASED": "放人"}.get(disposition.outcome, "已記錄")
	for resource: String in Board.RESOURCE_NAMES:
		out.stocks.append("%s%d／儲備目標%d · 市場基準價%.1f瓶蓋" % [Board.RESOURCE_NAMES[resource], town.inventory.get_amount(resource), town.get_target(resource), town.get_current_price(resource)])
	var jobs: Array = Board.postings(world, HOME)
	for entry: Dictionary in jobs:
		if bool(entry.get("urgent", false)) or entry.archetype in ["REPAIR", "SALVAGE"]: out.jobs.append({"id": entry.definition.id, "title": entry.definition.title_zh, "summary": entry.summary})
	if out.jobs.is_empty() and not jobs.is_empty(): out.jobs.append({"id": jobs[0].definition.id, "title": jobs[0].definition.title_zh, "summary": jobs[0].summary})
	return out
