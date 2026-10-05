extends RefCounted

const ABBAN := "companion:abban"
const PLACE := "place:convoy_wreck"

static func integer(value: Variant, expected: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == expected

# One request, one recovered real tool, one shared experience. No saved counter.
static func state(world) -> Dictionary:
	var out := {"status": "OFFERED", "shared": {}, "tool_given": false, "with_you": "", "error": "", "relay_friend": false, "fee_before": 50}
	if world == null or world.player == null:
		return out
	var site_day := -1
	var location := ""
	for index in range(world.event_log.size()):
		var evt = world.event_log[index]
		var p: Dictionary = evt.payload
		var ours: bool = evt.actor_id == world.player.npc_id
		if (evt.type in ["COMPANION_REQUEST_RESPONDED", "COMPANION_REQUEST_COMPLETED"] or (evt.type == "TRAVEL_ENCOUNTER_RESOLVED" and p.get("option") == "RECOVER_ABBAN_TOOL")) and not ours:
			out.error = "INVALID_COMPANION_REQUEST_ACTOR"
			return out
		if not ours:
			continue
		match String(evt.type):
			"ABBAN_RELAY_ACKNOWLEDGED": out.relay_friend = true
			"COMPANION_JOINED": out.with_you = String(p.get("companion_id", ""))
			"COMPANION_LEFT": out.with_you = ""
			"PLAYER_TRAVEL_STARTED": location = ""
			"NAMED_MIGRATION_COMPLETED": location = String(evt.target_id)
			"TRAVEL_ENCOUNTER":
				site_day = int(evt.day) if p.get("place_id") == PLACE and out.with_you == ABBAN and out.status == "ACCEPTED" else -1
			"COMPANION_REQUEST_RESPONDED":
				if out.with_you != ABBAN or out.status not in ["OFFERED", "DEFERRED"] or evt.target_id != StringName(ABBAN) or p.size() != 2 or p.get("companion_id") != ABBAN or p.get("response") not in ["ACCEPT", "DEFER", "REFUSE"]:
					out.error = "INVALID_COMPANION_REQUEST_RESPONSE"
					return out
				out.status = {"ACCEPT": "ACCEPTED", "DEFER": "DEFERRED", "REFUSE": "REFUSED"}[p.response]
			"TRAVEL_ENCOUNTER_RESOLVED":
				if p.get("option") == "RECOVER_ABBAN_TOOL":
					var valid: bool = out.status == "ACCEPTED" and site_day >= 0 and int(evt.day) == site_day + 1 and p.get("place_id") == PLACE and p.get("encounter_type") == "PLACE_VISIT" and integer(p.get("elapsed_days"), 1) and p.get("cost_extra_day") == true
					valid = valid and typeof(p.get("items_gained")) == TYPE_DICTIONARY
					if valid:
						valid = p.items_gained.size() == 1 and integer(p.items_gained.get("wrench"), 1)
					if not valid:
						out.error = "INVALID_COMPANION_RECOVERY_RECEIPT"
						return out
					out.status = "RECOVERED"
					out.shared = {"recovery_index": index, "day": int(evt.day), "place_id": PLACE}
				site_day = -1
			"COMPANION_REQUEST_COMPLETED":
				var valid: bool = out.status == "RECOVERED" and out.with_you == ABBAN and evt.target_id == StringName(ABBAN) and p.size() == 7
				valid = valid and p.get("companion_id") == ABBAN and p.get("item_id") == "wrench" and integer(p.get("quantity"), 1)
				valid = valid and integer(p.get("fee_before"), 25 if out.relay_friend else 50) and integer(p.get("fee_after"), 25) and integer(p.get("recovery_index"), int(out.shared.get("recovery_index", -1)))
				valid = valid and typeof(p.get("settlement_id")) == TYPE_STRING and p.get("settlement_id") == location and world.get_settlement(StringName(location)) != null
				if not valid:
					out.error = "INVALID_COMPANION_REQUEST_RECEIPT"
					return out
				out.status = "COMPLETED"
				out.tool_given = true
				out.fee_before = int(p.fee_before)
	return out

static func response_refusal(world, response: String) -> String:
	var s := state(world)
	if s.error != "": return String(s.error)
	if s.with_you != ABBAN: return "ABBAN_NOT_WITH_YOU"
	if response not in ["ACCEPT", "DEFER", "REFUSE"]: return "INVALID_COMPANION_REQUEST_RESPONSE"
	if s.status not in ["OFFERED", "DEFERRED"]: return "COMPANION_REQUEST_ALREADY_ANSWERED"
	return ""

static func recovery_pending(world) -> bool:
	var s := state(world)
	return s.error == "" and s.with_you == ABBAN and s.status == "ACCEPTED"

static func recovery_refusal(world) -> String:
	if not recovery_pending(world): return "NO_ACCEPTED_COMPANION_REQUEST"
	var enc = world.active_encounter
	if enc == null or enc.encounter_type != &"PLACE_VISIT" or enc.context.get("place_id") != PLACE or enc.travel_day_index != 2 or enc.context.get("companion_request") != true:
		return "COMPANION_WRONG_SITE"
	var real_visit := false
	for index in range(world.event_log.size() - 1, -1, -1):
		var evt = world.event_log[index]
		if evt.type == "TRAVEL_ENCOUNTER" and evt.actor_id == world.player.npc_id:
			real_visit = evt.day == enc.day and evt.payload.get("place_id") == PLACE
			break
	if not real_visit: return "COMPANION_WRONG_SITE"
	var ls = world.npc_life_state_registry.get_life_state(world.player.npc_id)
	var party = world.get_refugee_party(ls.population_container_id)
	if party == null or enc.origin_id != party.origin_id or enc.destination_id != party.destination_id or not ((String(party.origin_id) == "settlement:gray_valley" and String(party.destination_id) == "settlement:new_hope") or (String(party.origin_id) == "settlement:new_hope" and String(party.destination_id) == "settlement:gray_valley")):
		return "COMPANION_WRONG_SITE"
	if world.player.item_inventory.contains("wrench", 1): return "WRENCH_ALREADY_CARRIED"
	if not world.player.item_inventory.has_capacity_for("wrench", 1): return "ITEM_CAPACITY_EXCEEDED"
	return ""

static func delivery_refusal(world) -> String:
	var s := state(world)
	if s.error != "": return String(s.error)
	if s.with_you != ABBAN: return "ABBAN_NOT_WITH_YOU"
	if s.tool_given: return "COMPANION_REQUEST_ALREADY_DONE"
	if s.status != "RECOVERED": return "RECOVER_TOOL_FIRST"
	if not world.player.item_inventory.contains("wrench", 1): return "WRENCH_REQUIRED"
	return ""

static func note(world) -> String:
	var s := state(world)
	if s.relay_friend:
		return "阿扳的扳手仍可按原本請求找回並交還；中繼站已約定再雇用25瓶蓋，交工具不再降價或退款。" + ("\n已完成找回並交還扳手。" if s.tool_given else "\n請求狀態：" + {"OFFERED": "尚未答覆", "DEFERRED": "暫緩", "ACCEPTED": "已答應找回", "REFUSED": "已拒絕", "RECOVERED": "已找回，可交還或留用"}.get(s.status, s.status))
	match String(s.status):
		"REFUSED": return "你拒絕了阿扳的工具請求。他仍照原本的條件同行。"
		"ACCEPTED": return "已答應阿扳：走灰谷—新希望公路，到翻覆的商隊殘骸找回他的扳手。搜尋要多花 1 天；拿到後可留著，或回鎮交給他，往後簽約金降為 25 瓶蓋。背包只能帶一把扳手，出發前先空出位置。"
		"RECOVERED", "COMPLETED":
			var memory := "共同經歷｜第 %d 天，你和阿扳在翻覆的商隊殘骸找回扳手。" % int(s.shared.day)
			return memory + ("\n阿扳收下扳手 ×1，已從背包交出。往後在灰谷再雇用他只收 25 瓶蓋（原價 50）。" if s.tool_given else "\n扳手在你手上。交給阿扳，往後在灰谷再雇用他只收 25 瓶蓋；也可以留著自己用。")
	return ("已暫緩，準備好再答覆。\n" if s.status == "DEFERRED" else "") + "阿扳：我把扳手落在灰谷—新希望公路的商隊殘骸了。願意陪我繞去找找嗎？找回後交給我，下次簽約只收 25 瓶蓋。"
