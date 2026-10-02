extends RefCounted

# ==============================================================================
# PLACE-4: FOUR ROAD LOCATIONS THAT ARE PART OF THE WORLD
# ==============================================================================
# Owner ruling (2026-09-27): the map does not need more towns, it needs places
# that change where you go and feed a town's economy, work or danger. Seven
# places that all play "arrive -> search -> take -> leave" are seven reskinned
# buttons, so this slice is exactly four, and each is a different verb:
#
#   舊水井   RESOURCE  take the water yourself, or mark it for a town short of
#                      water and walk there to report it - that town then
#                      produces more water every day, for good
#   廢棄加油站 RESOURCE  the same choice, for fuel
#   鐵鎚幫營地 CAMP     the heavy raider's camp on the wilderness route. Raid it
#                      and the wilderness is quiet until it re-forms; walk
#                      round it and pay a day
#   商隊殘骸  WRECK     a wreck the world keeps refilling: every caravan lost
#                      on that road leaves more scrap on it
#
# WHERE THE RESOURCES GO. The owner's example put the fuel station with Dry Well
# and the well with New Hope. The world's own data disagrees: Dry Well is the
# fuel refinery (+5/day) and New Hope is the water oasis (+8/day), so neither
# would notice. Each resource place therefore sits on a road between two towns
# that are both short of it, and choosing which one gets it is the decision.
#
# NO NEW SAVE STATE. Everything here is folded from committed receipts
# (TRAVEL_ENCOUNTER_RESOLVED, FIELD_RESULT, PLACE_REPORTED and the caravan-loss
# events), the same way growth points are derived. The only thing a place ever
# writes into the world is a town's production when a report lands, and that
# is carried on the PLACE_REPORTED receipt.
# ==============================================================================

const RESOURCE := "RESOURCE"
const CAMP := "CAMP"
const WRECK_SITE := "WRECK_SITE"
# ASP-1: a place worth a special journey, holding something the market does
# not sell, behind a condition the player can see but may not meet yet.
const SECRET := "SECRET"
const ARMORY_MECHANICS := 2
const ARMORY_ELECTRONICS := 2
const ARMORY_CIRCUIT_SCRAP := 2

const CAMP_CLEARED_DAYS := 15
# Walking past a place is an answer too. It is not asked again for a week, or
# every trip would open with the same question.
const LEFT_QUIET_DAYS := 30
const WRECK_BASE_SCRAP := 3
const WRECK_SCRAP_PER_LOSS := 2
const WRECK_MAX_SCRAP := 8

const PLACES := {
	"place:old_well": {
		"name_zh": "枯河舊水井",
		"kind": RESOURCE,
		"resource": "water",
		"a": "settlement:gray_valley",
		"b": "settlement:dry_well",
		"route": "HIGHWAY",
		"take": 3,
		"production": 2,
		"fee_caps": 20,
		"fee_xp": 6,
		"body_zh": "枯河床邊有一口舊井，井繩早斷了，但往下丟顆石子還聽得到水聲。\n灰谷和乾井都缺水。這口井可以是你的，也可以是其中一座鎮的。",
		"map_t": 0.76,
		"map_label": "below",
	},
	"place:fuel_station": {
		"name_zh": "廢棄加油站",
		"kind": RESOURCE,
		"resource": "fuel",
		"a": "settlement:gray_valley",
		"b": "settlement:new_hope",
		"route": "HIGHWAY",
		"take": 2,
		"production": 1,
		"fee_caps": 25,
		"fee_xp": 6,
		"body_zh": "路邊一座塌了頂棚的加油站。地下儲槽的蓋子鏽死了，撬開一條縫，有油味。\n灰谷和新希望都缺燃料。你可以抽一點自己帶走，或是記下位置，讓其中一座鎮派人來接手。",
		"map_t": 0.28,
		"map_label": "below",
	},
	"place:hammer_camp": {
		"name_zh": "鐵鎚幫營地",
		"kind": CAMP,
		"a": "settlement:dry_well",
		"b": "settlement:new_hope",
		"route": "WILDERNESS",
		# Deep in the four-day wilderness, not at its mouth.
		"day_index": 2,
		"body_zh": "荒野路的岔口搭著一圈焊死的鐵皮，火堆還在冒煙。重裝掠奪者就住在這裡。\n打進去，這條荒野路會安靜一陣子；不驚動他們，路就照樣危險。",
		"map_t": 0.5,
	},
	"place:old_armory": {
		"name_zh": "舊世地下軍械庫",
		"kind": SECRET,
		"a": "settlement:dry_well",
		"b": "settlement:new_hope",
		"route": "WILDERNESS",
		# Past the raider's camp: the long road, the camp, then this.
		"day_index": 3,
		"prize": "old_world_saber",
		"body_zh": "荒野深處，半埋在沙裡的一道防爆門，門上的漆字還看得出「補給」兩個字。\n控制盒的蓋板用螺絲鎖死，線路還連著。懂機械的人能拆開；懂電子的人可以用廢料搭接線路。兩條路通向同一間庫房。",
		"map_t": 0.78,
	},
	"place:convoy_wreck": {
		"name_zh": "翻覆的商隊殘骸",
		"kind": WRECK_SITE,
		"a": "settlement:gray_valley",
		"b": "settlement:new_hope",
		"route": "HIGHWAY",
		# Past the fuel station, on the road the oasis caravan runs.
		"day_index": 2,
		"body_zh": "公路彎道下躺著幾輛翻覆的商隊貨車，有些是舊的，有些看起來才剛出事。\n這條路每死一支商隊，這裡就多一點能撿的東西。",
		"map_t": 0.72,
	},
}

static func ids() -> Array:
	var out: Array = PLACES.keys()
	out.sort()
	return out

static func exists(place_id: Variant) -> bool:
	return typeof(place_id) == TYPE_STRING and PLACES.has(place_id)

static func info(place_id: String) -> Dictionary:
	return (PLACES[place_id] as Dictionary).duplicate(true) if exists(place_id) else {}

static func towns(place_id: String) -> Array:
	var p := info(place_id)
	return [String(p.get("a", "")), String(p.get("b", ""))]

static func on_road(place_id: String, origin: String, destination: String, route_type: String) -> bool:
	var p := info(place_id)
	if p.is_empty():
		return false
	var same_road: bool = (origin == p.a and destination == p.b) or (origin == p.b and destination == p.a)
	var road_type := route_type if route_type != "" else "HIGHWAY"
	return same_road and road_type == String(p.route)

# ── Derived state ─────────────────────────────────────────────────────────────

# Everything the world knows about one place, folded from the ledger.
static func state(world, place_id: String) -> Dictionary:
	var p := info(place_id)
	var out := {
		"place_id": place_id, "discovered": false, "status": "UNTOUCHED",
		"marked_for": "", "claimed_by": "", "cleared_until": -1, "scrap": 0, "left_day": -1, "fresh_losses": 0, "prize_taken": false,
	}
	if p.is_empty() or world == null:
		return out
	var last_search := -1
	var last_visit := -1
	for i in range(world.event_log.size()):
		var evt = world.event_log[i]
		if typeof(evt.payload) != TYPE_DICTIONARY:
			continue
		if String(evt.payload.get("place_id", "")) != place_id:
			continue
		match evt.type:
			"TRAVEL_ENCOUNTER", "ROAD_COMBAT_BEGAN":
				out.discovered = true
			"TRAVEL_ENCOUNTER_RESOLVED":
				out.discovered = true
				last_visit = i
				match String(evt.payload.get("option", "")):
					"TAKE_RESOURCE":
						if out.status == "UNTOUCHED":
							out.status = "STRIPPED"
					"MARK_A", "MARK_B":
						if out.status == "UNTOUCHED":
							out.status = "MARKED"
							out.marked_for = String(evt.payload.get("marked_for", ""))
					"SEARCH_SITE":
						last_search = i
					"OPEN_ARMORY", "BRIDGE_ARMORY":
						if int((evt.payload.get("items_gained", {}) as Dictionary).get(String(p.get("prize", "")), 0)) > 0:
							out.prize_taken = true
					"LEAVE":
						out.left_day = int(evt.day)
			"PLACE_REPORTED":
				out.status = "CLAIMED"
				out.claimed_by = String(evt.payload.get("settlement_id", ""))
				out.marked_for = ""
			"FIELD_RESULT":
				if String(evt.payload.get("outcome", "")) == "VICTORY":
					out.cleared_until = int(evt.day) + CAMP_CLEARED_DAYS
	if String(p.kind) == WRECK_SITE:
		var losses := 0
		var fresh := 0
		for i in range(last_search + 1, world.event_log.size()):
			var evt = world.event_log[i]
			if evt.type != "TRANSIT_PREDATION" and evt.type != "CARAVAN_DESTROYED":
				continue
			var o := String(evt.payload.get("origin", ""))
			var d := String(evt.payload.get("destination", ""))
			if (o == p.a and d == p.b) or (o == p.b and d == p.a):
				losses += 1
				if i > last_visit:
					fresh += 1
		var base := WRECK_BASE_SCRAP if last_search < 0 else 0
		out.scrap = mini(WRECK_MAX_SCRAP, base + WRECK_SCRAP_PER_LOSS * losses)
		out.fresh_losses = fresh
	return out

static func camp_cleared(world) -> bool:
	return int(state(world, "place:hammer_camp").cleared_until) > int(world.current_day)

# Whether passing this place today offers a decision at all.
static func is_live(world, place_id: String) -> bool:
	var p := info(place_id)
	var s := state(world, place_id)
	match String(p.get("kind", "")):
		RESOURCE:
			return s.status == "UNTOUCHED"
		CAMP:
			return int(s.cleared_until) <= int(world.current_day)
		SECRET:
			return not bool(s.prize_taken)
		WRECK_SITE:
			# Seen once, it is only worth stopping again when the road has left
			# something new on it.
			return int(s.scrap) > 0 and (not bool(s.discovered) or int(s.fresh_losses) > 0)
	return false

# The place this trip passes on this day of the road (the first, unless the
# place says otherwise), if it has something to offer and
# the player has not already dealt with it on this trip.
static func place_for_trip(world, party, travel_day_index: int) -> String:
	if world == null or party == null or travel_day_index < 1:
		return ""
	var route_type := String(party.route_type) if party.route_type != &"" else "HIGHWAY"
	for place_id in ids():
		if not on_road(place_id, String(party.origin_id), String(party.destination_id), route_type):
			continue
		if int(info(place_id).get("day_index", 1)) != travel_day_index:
			continue
		if not is_live(world, place_id):
			continue
		if _met_this_trip(world, place_id, int(party.departure_day)):
			continue
		# A secret is the reason for the trip: it always asks, so coming back
		# once you are ready is never met with silence.
		if String(info(place_id).kind) == SECRET:
			return place_id
		var left_day := int(state(world, place_id).left_day)
		if left_day >= 0 and int(world.current_day) - left_day < LEFT_QUIET_DAYS:
			continue
		return place_id
	return ""

static func _met_this_trip(world, place_id: String, departure_day: int) -> bool:
	for i in range(world.event_log.size() - 1, -1, -1):
		var evt = world.event_log[i]
		if int(evt.day) < departure_day:
			break
		if evt.type in ["TRAVEL_ENCOUNTER_RESOLVED", "ROAD_COMBAT_BEGAN"] and typeof(evt.payload) == TYPE_DICTIONARY and String(evt.payload.get("place_id", "")) == place_id:
			return true
	return false

# ── Presentation of the encounter ─────────────────────────────────────────────

static func town_name(world, settlement_id: String) -> String:
	var s = world.get_settlement(StringName(settlement_id)) if world != null else null
	if s == null:
		return settlement_id.replace("settlement:", "")
	var name := String(s.name)
	var cut := name.find(" (")
	return name.substr(0, cut) if cut > 0 else name

const RESOURCE_NAMES := {"water": "水", "food": "食物", "scrap": "廢料", "fuel": "燃料"}

# Every option id a place can ever offer, for validating a receipt that no
# longer has its context.
const ALL_OPTION_IDS := [&"TAKE_RESOURCE", &"MARK_A", &"MARK_B", &"LEAVE", &"FIGHT", &"SEARCH_SITE", &"OPEN_ARMORY", &"BRIDGE_ARMORY"]

static func options(context: Dictionary, world = null) -> Array:
	var place_id := String(context.get("place_id", ""))
	# Without its place an encounter can only be walked past; every place
	# offers that, so it is the one answer that is always safe.
	if not exists(place_id):
		return [{"id": &"LEAVE", "label": "不停留", "detail": ""}]
	var p := info(place_id)
	match String(p.kind):
		RESOURCE:
			var res_name: String = RESOURCE_NAMES.get(String(p.resource), String(p.resource))
			var a_name := String(context.get("a_name", town_name(world, String(p.a))))
			var b_name := String(context.get("b_name", town_name(world, String(p.b))))
			var report_detail := "到%s後回報：%s每天多產 %d 份%s（永久），你拿 %d 瓶蓋。之後這裡歸他們。"
			return [
				{"id": &"TAKE_RESOURCE", "label": "自己帶走 %d 份%s" % [int(p.take), res_name],
					"detail": "拿了就沒了——這裡被你搬空，不會再有鎮派人來接手。"},
				{"id": &"MARK_A", "label": "記下位置，回報%s" % a_name,
					"detail": report_detail % [a_name, a_name, int(p.production), res_name, int(p.fee_caps)]},
				{"id": &"MARK_B", "label": "記下位置，回報%s" % b_name,
					"detail": report_detail % [b_name, b_name, int(p.production), res_name, int(p.fee_caps)]},
				{"id": &"LEAVE", "label": "先不管它", "detail": "下次經過還在"},
			]
		CAMP:
			return [
				{"id": &"FIGHT", "label": "突襲營地", "detail": "對上重裝掠奪者。打贏後這條荒野路約 %d 天內不會再有人攔路。" % CAMP_CLEARED_DAYS},
				{"id": &"LEAVE", "label": "繞遠一點，不驚動他們", "detail": "營地還在，這條荒野路照樣危險"},
			]
		SECRET:
			return [
				{"id": &"OPEN_ARMORY", "label": "拆開控制盒，進去", "detail": "耗時 1 天。裡面是什麼，只有進去才知道。",
					"requires": {"all": [{"kind": "skill", "skill_id": "MECHANICS", "min_rank": ARMORY_MECHANICS}]},
					"requirement_label": "機械 %d" % ARMORY_MECHANICS, "gate": "capability"},
				{"id": &"BRIDGE_ARMORY", "label": "搭接控制線路，進去", "detail": "耗時 1 天，消耗廢料 %d。與拆開控制盒共用同一批藏品。灰谷的電器修補匠教電子。" % ARMORY_CIRCUIT_SCRAP,
					"requires": {"all": [{"kind": "skill", "skill_id": "ELECTRONICS", "min_rank": ARMORY_ELECTRONICS}]},
					"requirement_label": "電子 %d、廢料 %d" % [ARMORY_ELECTRONICS, ARMORY_CIRCUIT_SCRAP], "gate": "capability"},
				{"id": &"LEAVE", "label": "記下位置，改天再來", "detail": "門不會自己打開"},
			]
		WRECK_SITE:
			var scrap := int(context.get("scrap", 0))
			return [
				{"id": &"SEARCH_SITE", "label": "翻找殘骸", "detail": "耗時 1 天，約 %d 份廢料（拾荒越熟練拿得越多）" % scrap},
				{"id": &"LEAVE", "label": "不停留", "detail": "什麼也沒發生"},
			]
	return []

static func all_options() -> Array:
	var out: Array = []
	for place_id in ids():
		out.append_array(options({"place_id": place_id}))
	return out

static func title(context: Dictionary) -> String:
	return String(info(String(context.get("place_id", ""))).get("name_zh", "路邊的地方"))

static func body(context: Dictionary) -> String:
	return String(info(String(context.get("place_id", ""))).get("body_zh", ""))

# One line for the map and the journal: what this place is to the world now.
static func status_text(world, place_id: String) -> String:
	var p := info(place_id)
	var s := state(world, place_id)
	if not bool(s.discovered):
		return "未探索"
	match String(p.kind):
		RESOURCE:
			match String(s.status):
				"STRIPPED": return "已被你搬空"
				"MARKED": return "待回報%s" % town_name(world, String(s.marked_for))
				"CLAIMED": return "歸%s" % town_name(world, String(s.claimed_by))
			return "無人接手"
		CAMP:
			if int(s.cleared_until) > int(world.current_day):
				return "已清除（約 %d 天後重組）" % (int(s.cleared_until) - int(world.current_day))
			return "有人盤據"
		WRECK_SITE:
			return "約 %d 份廢料" % int(s.scrap) if int(s.scrap) > 0 else "暫時撿空了"
		SECRET:
			return "已被你搬空" if bool(s.prize_taken) else "門還鎖著（機械 %d，或電子 %d＋廢料 %d）" % [ARMORY_MECHANICS, ARMORY_ELECTRONICS, ARMORY_CIRCUIT_SCRAP]
	return ""
