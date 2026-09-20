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

# Each option: id, label, and a one-line statement of what it costs and gives.
# The cost line is written from the catalogue so the UI can never describe a
# different bargain from the one the engine will actually commit.
static func options(encounter_type: StringName) -> Array:
	match encounter_type:
		WRECK:
			return [
				{"id": &"SEARCH", "label": "搜尋殘骸", "detail": "耗時 1 天（水 −1、食物 −1）　得到 廢料 +3、燃料 +1"},
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
				{"id": &"GIVE_WATER", "label": "給他一份水", "detail": "水 −1　他把身上的 廢料 +2 塞給你"},
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
