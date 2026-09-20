class_name TravelEncounter
extends RefCounted

# ==============================================================================
# S5-B4: TRAVEL ENCOUNTERS (catalogue + deterministic selection)
# ==============================================================================
# The road stops being a number of days and becomes a place where you have to
# decide something. Every choice here spends a resource that S5-B5 made real:
# a day costs one water and one food, so "search the wreck" is never free loot.
#
# DETERMINISTIC, NOT RANDOM (first version):
#   An encounter is a pure function of (route, departure day, travel-day index).
#   No RNG, no seeded table, no framework. Replay stays exact for free, and if
#   play-testing shows the road feels repetitive, a seeded encounter table is a
#   later decision made against evidence rather than a guess made now.
#
#   The hash below is written out by hand rather than using Godot's hash(),
#   because engine-internal hashing is not guaranteed stable across versions and
#   the world's behaviour must not quietly change on an engine upgrade. The same
#   lesson as StringName ordering.
#
# NOT here: combat, factions, injuries, reputation, random loot tables. The
# roadblock is "some people have put a barrier across the road and want paying",
# not a declared bandit faction: inventing world truth is not this slice's job.
# ==============================================================================

const WRECK := &"WRECK"
const ROCKSLIDE := &"ROCKSLIDE"
const ROADBLOCK := &"ROADBLOCK"
const DEHYDRATED_TRAVELLER := &"DEHYDRATED_TRAVELLER"

# The wheel of possible road events. NONE entries are what make an empty road
# the common case, so an encounter still feels like an interruption.
const ENCOUNTER_WHEEL: Array[StringName] = [
	&"", WRECK, &"", ROADBLOCK, &"", ROCKSLIDE, &"", DEHYDRATED_TRAVELLER,
]

# Stable string hash. Deliberately simple and fully specified here so that its
# output can never change underneath the simulation.
static func stable_hash(text: String) -> int:
	var h := 2166136261
	for i in range(text.length()):
		h = (h ^ text.unicode_at(i)) * 16777619
		h = h & 0x7FFFFFFF
	return h

# Which encounter, if any, happens on this day of this journey.
# Returns &"" for an empty stretch of road.
static func select(origin_id: StringName, destination_id: StringName, departure_day: int, travel_day_index: int) -> StringName:
	var key := stable_hash("%s>%s" % [String(origin_id), String(destination_id)])
	key = (key + departure_day * 31 + travel_day_index * 7) & 0x7FFFFFFF
	return ENCOUNTER_WHEEL[key % ENCOUNTER_WHEEL.size()]

# ── Presentation and options ─────────────────────────────────────────────────
# Options are DEFINED here and never stored in the world, so a saved game can
# never disagree with the catalogue about what a choice does.

static func title(encounter_type: StringName) -> String:
	match encounter_type:
		WRECK: return "翻覆的貨車"
		ROCKSLIDE: return "崩塌的道路"
		ROADBLOCK: return "路上的關卡"
		DEHYDRATED_TRAVELLER: return "脫水的旅人"
	return "路上的事"

static func body(encounter_type: StringName) -> String:
	match encounter_type:
		WRECK:
			return "一輛翻覆的舊貨車橫在路邊。貨箱早就被翻過了，但車底下似乎還卡著些東西。\n搜尋要花掉一整天。"
		ROCKSLIDE:
			return "前方的路被土石埋了半邊。你可以拆些廢料墊出一條通道，或是繞遠路。"
		ROADBLOCK:
			return "幾個陌生人用廢鐵在路中間架起了關卡。他們沒有拔槍，只是伸手要過路費。"
		DEHYDRATED_TRAVELLER:
			return "一個人靠坐在路邊的水泥墩上，嘴唇乾裂，幾乎沒有反應。\n他身邊的背包看起來還有點東西。"
	return ""

# WHAT THE PLAYER IS TOLD, and deliberately what they are NOT told.
#
# The COST is always stated: you must be able to work out whether you can
# afford a day, and "three days of road, two days of water" is only a real
# decision if the price is visible.
#
# The PAYOFF is never stated. Printing "得到 廢料 +3、燃料 +1" turned searching a
# wreck into arithmetic instead of a gamble - and worse, every wreck paid out
# exactly the same, so after the first one there was nothing left to find out.
# You can see that the truck is worth a look. You cannot see what is under it.
static func options(encounter_type: StringName) -> Array:
	match encounter_type:
		WRECK:
			return [
				{"id": &"SEARCH", "label": "搜尋殘骸", "detail": "耗時 1 天（水 −1、食物 −1）　收穫不明"},
				{"id": &"LEAVE", "label": "繼續趕路", "detail": "什麼也沒發生"},
			]
		ROCKSLIDE:
			return [
				{"id": &"CLEAR", "label": "墊出通道", "detail": "廢料 −1　不耽誤行程"},
				{"id": &"DETOUR", "label": "繞路", "detail": "耗時 1 天（水 −1、食物 −1）"},
			]
		ROADBLOCK:
			return [
				{"id": &"PAY", "label": "付過路費", "detail": "瓶蓋 −10　直接通過"},
				{"id": &"DETOUR", "label": "繞路", "detail": "耗時 1 天（水 −1、食物 −1）"},
			]
		DEHYDRATED_TRAVELLER:
			return [
				{"id": &"GIVE_WATER", "label": "給他一份水", "detail": "水 −1　他也許身上有點什麼"},
				{"id": &"LEAVE", "label": "離開", "detail": "什麼也沒發生"},
			]
	return []

static func has_option(encounter_type: StringName, option_id: StringName) -> bool:
	for o in options(encounter_type):
		if o["id"] == option_id:
			return true
	return false

static func is_valid_type(encounter_type: StringName) -> bool:
	return encounter_type in [WRECK, ROCKSLIDE, ROADBLOCK, DEHYDRATED_TRAVELLER]

# ── What you actually find ───────────────────────────────────────────────────
# Still no RNG: the yield is a pure function of WHICH wreck this is, so a replay
# finds exactly the same thing under exactly the same truck. But two different
# wrecks are two different trucks, and one of them may be picked clean.
#
# The empty result matters most. If searching always paid, the only question
# would be whether you can afford the day. Sometimes you spend the day, drink
# the water, and find nothing - which is what makes the gamble a gamble.
static func wreck_yield(day: int, origin_id: StringName, destination_id: StringName, travel_day_index: int) -> Dictionary:
	var h := stable_hash("wreck|%s>%s|%d|%d" % [String(origin_id), String(destination_id), day, travel_day_index])
	var roll := h % 10
	if roll <= 1:
		return {}                                  # picked clean
	if roll <= 4:
		return {"scrap": 1 + (h / 10) % 2}         # scraps of metal
	if roll <= 7:
		return {"scrap": 2 + (h / 10) % 3, "fuel": 1}
	if roll == 8:
		return {"scrap": 1, "fuel": 2}             # a half-full jerrycan
	return {"scrap": 4 + (h / 10) % 3, "fuel": 2}  # a genuinely good find

# The traveller gives what little he has. He is grateful, not rich, and one
# in five has nothing left to give at all.
static func traveller_yield(day: int, origin_id: StringName, destination_id: StringName, travel_day_index: int) -> Dictionary:
	var h := stable_hash("traveller|%s>%s|%d|%d" % [String(origin_id), String(destination_id), day, travel_day_index])
	var roll := h % 10
	if roll <= 1:
		return {}
	if roll <= 6:
		return {"scrap": 1 + h % 2}
	if roll <= 8:
		return {"scrap": 2, "fuel": 1}
	return {"scrap": 3}
