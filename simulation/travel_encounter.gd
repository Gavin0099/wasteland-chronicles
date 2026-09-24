class_name TravelEncounter
extends RefCounted

# ==============================================================================
# S5-B4: TRAVEL ENCOUNTERS (catalogue + deterministic selection)
# ==============================================================================
# The road stops being a number of days and becomes a place where you have to
# decide something. Every choice here spends a resource that S5-B5 made real:
# a day costs one water and one food, so "search the wreck" is never free loot.
#
# WORLD-REACTIVE (S5-B4.1):
#   The first version picked from a fixed wheel, so the same road looked the
#   same whatever was happening in the world. Gray Valley could be dying of
#   thirst and the highway would not notice. Now the candidates and their
#   weights come from what is ACTUALLY going on: a refugee column you meet is a
#   real party in world.refugees, a fresh wreck is a caravan the world really
#   lost on this route, roadblocks grow where security has collapsed, and dying
#   travellers appear on the roads out of a town that cannot find water.
#
#   Two journeys down the same highway a month apart should not look alike.
#
# DETERMINISTIC, NOT RANDOM:
#   Selection is still a pure function - of world facts plus route, day and
#   travel-day index. No RNG anywhere, so replay stays exact for free. The
#   variety now comes from the world changing, which is the variety that was
#   worth having.
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
const REFUGEE_COLUMN := &"REFUGEE_COLUMN"
const BANDIT_AMBUSH := &"BANDIT_AMBUSH"
const ItemRegistry = preload("res://simulation/item_registry.gd")

const BANDIT_BRIBE_CAPS := 15

# Base weights for an ordinary, quiet stretch of road. EMPTY is deliberately
# the heaviest: an encounter has to stay an interruption, not a commute.
const WEIGHT_EMPTY := 10
const WEIGHT_WRECK := 3
const WEIGHT_ROCKSLIDE := 3
const WEIGHT_ROADBLOCK_BASE := 1
const WEIGHT_TRAVELLER_BASE := 1

# S5-C2 costs. The plain toll stays where S5-B4 put it; someone who trades for a
# living pays less for the same barrier, so the same road costs a different
# amount depending on who is standing in front of it.
const HAGGLED_TOLL_CAPS := 4
const COLUMN_TRADE_CAPS := 5
const ROADBLOCK_PERSUADED_CAPS := 5
const BANDIT_PERSUADED_CAPS := 8
const Capability = preload("res://simulation/capability_profile.gd")

# C3 practice sources name an action the world already resolves. Paying a toll,
# receiving a gift, leaving, and merely owning a tool teach no skill. This table
# is separate from eligibility: a novice can learn by SEARCH or DETOUR, while a
# skilled character can refine that same discipline through a gated approach.
static func practice_skill(encounter_type: StringName, option_id: StringName) -> String:
	match encounter_type:
		WRECK:
			if option_id in [&"SEARCH", &"QUICK_PICK"]:
				return "SCAVENGING"
			if option_id in [&"STRIP_PARTS", &"USE_WRENCH"]:
				return "MECHANICS"
		ROCKSLIDE:
			if option_id in [&"DETOUR", &"SCOUT_PATH", &"USE_ROPE"]:
				return "SURVIVAL"
		ROADBLOCK:
			if option_id == &"HAGGLE":
				return "BARTER"
			if option_id == &"SLIP_PAST":
				return "STEALTH"
			if option_id == &"PERSUADE":
				return "SPEECH"
		DEHYDRATED_TRAVELLER:
			if option_id == &"HYDRATE":
				return "SURVIVAL"
		REFUGEE_COLUMN:
			if option_id == &"TRADE_COLUMN":
				return "BARTER"
		BANDIT_AMBUSH:
			if option_id == &"PARLEY":
				return "SPEECH"
	return ""

# Stable string hash. Deliberately simple and fully specified here so that its
# output can never change underneath the simulation.
static func stable_hash(text: String) -> int:
	var h := 2166136261
	for i in range(text.length()):
		h = (h ^ text.unicode_at(i)) * 16777619
		h = h & 0x7FFFFFFF
	return h

# Build the candidate list for this stretch of road, from what is true right
# now. `facts` is gathered by the engine so this stays a pure function.
#
#   facts.min_security             lowest security at either end of the road
#   facts.destination_water_pressure how thirsty the place you are heading is
#   facts.refugee_column           a real party in transit on this road, or {}
#   facts.fresh_wreck              a caravan this road really lost lately, or {}
static func candidates(facts: Dictionary) -> Array:
	var out: Array = []
	out.append({"type": &"", "weight": WEIGHT_EMPTY})
	out.append({"type": ROCKSLIDE, "weight": WEIGHT_ROCKSLIDE})

	# A wreck is always possible; a caravan lost here RECENTLY is much more so,
	# and it is a specific wreck rather than an anonymous one.
	var wreck_weight := WEIGHT_WRECK
	if not (facts.get("fresh_wreck", {}) as Dictionary).is_empty():
		wreck_weight += 6
	out.append({"type": WRECK, "weight": wreck_weight})

	# People set up barricades where nobody is keeping order.
	var min_security: float = float(facts.get("min_security", 100.0))
	var roadblock_weight: int = WEIGHT_ROADBLOCK_BASE + int(maxf(0.0, 100.0 - min_security) / 10.0)
	out.append({"type": ROADBLOCK, "weight": roadblock_weight})

	# People walk out of a town that has run dry, and some do not make it.
	var dest_pressure: float = float(facts.get("destination_water_pressure", 0.0))
	var traveller_weight: int = WEIGHT_TRAVELLER_BASE + int(dest_pressure / 20.0)
	out.append({"type": DEHYDRATED_TRAVELLER, "weight": traveller_weight})

	# Only if there is genuinely a column of people on this road today.
	if not (facts.get("refugee_column", {}) as Dictionary).is_empty():
		out.append({"type": REFUGEE_COLUMN, "weight": 8})

	# Bandits ambush where security is compromised. Clamped and scaled to match existing weights.
	var ambush_weight: int = int(maxf(0.0, 75.0 - min_security) / 10.0)
	if facts.get("bandit_ambush", false):
		ambush_weight += 5
	if ambush_weight > 0:
		out.append({"type": BANDIT_AMBUSH, "weight": ambush_weight})

	return out

# Which encounter, if any, happens on this day of this journey.
# Returns &"" for an empty stretch of road.
static func select(facts: Dictionary, origin_id: StringName, destination_id: StringName, departure_day: int, travel_day_index: int) -> StringName:
	var pool := candidates(facts)
	var total := 0
	for c in pool:
		total += int(c["weight"])
	if total <= 0:
		return &""

	var h := stable_hash("%s>%s" % [String(origin_id), String(destination_id)])
	h = (h + departure_day * 31 + travel_day_index * 7) & 0x7FFFFFFF
	var roll := h % total
	for c in pool:
		roll -= int(c["weight"])
		if roll < 0:
			return c["type"]
	return &""

# ── Presentation and options ─────────────────────────────────────────────────
# Options are DEFINED here and never stored in the world, so a saved game can
# never disagree with the catalogue about what a choice does.

static func title(encounter_type: StringName) -> String:
	match encounter_type:
		WRECK: return "翻覆的貨車"
		ROCKSLIDE: return "崩塌的道路"
		ROADBLOCK: return "路上的關卡"
		DEHYDRATED_TRAVELLER: return "脫水的旅人"
		REFUGEE_COLUMN: return "逃難的人群"
		BANDIT_AMBUSH: return "劫匪伏擊"
	return "路上的事"

# The same road reads differently depending on what the world is doing, so the
# prose takes the context that was observed when the encounter fired.
static func body(encounter_type: StringName, context: Dictionary = {}) -> String:
	match encounter_type:
		BANDIT_AMBUSH:
			return "一夥持械的荒原劫匪從路旁的掩體後竄出，將你團團圍住。\n為首的劫匪揮舞著生鏽的砍刀，大聲喝令你交出所有財物。"
		WRECK:
			var wreck: Dictionary = context.get("fresh_wreck", {})
			if not wreck.is_empty():
				return "一輛商隊貨車翻覆在路肩，看得出來出事沒多久。貨箱被撬開過，地上還有拖行的痕跡。\n翻找要花掉一整天。"
			return "一輛翻覆的舊貨車橫在路邊。貨箱早就被翻過了，但車底下似乎還卡著些東西。\n搜尋要花掉一整天。"
		ROCKSLIDE:
			return "前方的路被土石埋了半邊。你可以拆些廢料墊出一條通道，或是繞遠路。"
		ROADBLOCK:
			var sec: float = float(context.get("min_security", 100.0))
			if sec <= 35.0:
				return "幾個人用廢鐵在路中間架起關卡。這一帶早就沒人管事了，他們也不避諱——伸手就是要過路費。"
			return "幾個陌生人用廢鐵在路中間架起了關卡。他們沒有拔槍，只是伸手要過路費。"
		DEHYDRATED_TRAVELLER:
			var from_name: String = String(context.get("from_name", ""))
			if from_name != "":
				return "一個人靠坐在路邊的水泥墩上，嘴唇乾裂，幾乎沒有反應。\n聽口音是從%s那邊走出來的——那裡的水井已經撐不住了。" % from_name
			return "一個人靠坐在路邊的水泥墩上，嘴唇乾裂，幾乎沒有反應。\n他身邊的背包看起來還有點東西。"
		REFUGEE_COLUMN:
			var headcount: int = int(context.get("headcount", 0))
			var origin_name: String = String(context.get("origin_name", "某處"))
			var dest_name: String = String(context.get("destination_name", "別處"))
			return "路上迎面走來一列人，大約 %d 個。他們是從%s出來的，要往%s去。\n帶頭的看了你的背包一眼，沒有開口。" % [
				headcount, origin_name, dest_name
			]
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
static func options(encounter_type: StringName, context: Dictionary = {}) -> Array:
	match encounter_type:
		WRECK:
			return [
				{"id": &"SEARCH", "label": "搜尋殘骸", "detail": "耗時 1 天（水 −1、食物 −1）　收穫不明"},
				{"id": &"STRIP_PARTS", "label": "拆解引擎與傳動", "detail": "耗時 1 天（水 −1、食物 −1）　收穫不明",
					"requires": _skill("MECHANICS", 2), "requirement_label": "機械 熟練", "gate": GATE_CAPABILITY},
				{"id": &"USE_WRENCH", "label": "用扳手拆下可用部件", "detail": "耗時 1 天（水 −1、食物 −1）　收穫不明",
					"requires_item": "wrench", "requirement_label": "持有：扳手", "gate": GATE_ITEM},
				{"id": &"QUICK_PICK", "label": "一眼挑出值得帶走的", "detail": "不耽誤行程　收穫不明",
					"requires": _skill("SCAVENGING", 2), "requirement_label": "搜刮 熟練", "gate": GATE_KNOWLEDGE},
				{"id": &"LEAVE", "label": "繼續趕路", "detail": "什麼也沒發生"},
			]
		ROCKSLIDE:
			return [
				{"id": &"CLEAR", "label": "墊出通道", "detail": "廢料 −1　不耽誤行程"},
				{"id": &"SCOUT_PATH", "label": "找一條繞過崩塌的小徑", "detail": "不耗廢料、不耽誤行程",
					"requires": _skill("SURVIVAL", 2), "requirement_label": "荒野求生 熟練", "gate": GATE_KNOWLEDGE},
				{"id": &"FORCE_THROUGH", "label": "直接翻過去", "detail": "不耗廢料、不耽誤行程　翻越時弄丟 1 件物資（廢料→燃料→水）",
					"requires": _trait("RECKLESS"), "requirement_label": "魯莽", "gate": GATE_KNOWLEDGE},
				{"id": &"USE_ROPE", "label": "用繩索固定路線", "detail": "不耗廢料、不耽誤行程",
					"requires_item": "rope", "requirement_label": "持有：繩索", "gate": GATE_ITEM},
				{"id": &"DETOUR", "label": "繞路", "detail": "耗時 1 天（水 −1、食物 −1）"},
			]
		ROADBLOCK:
			var opts: Array = [
				{"id": &"PAY", "label": "付過路費", "detail": "瓶蓋 −10　直接通過"},
				{"id": &"PERSUADE", "label": "跟他們談談", "detail": "嘗試協商過路費（成功 %d 瓶蓋，失敗 10 瓶蓋）" % ROADBLOCK_PERSUADED_CAPS},
				{"id": &"HAGGLE", "label": "把價錢談下來", "detail": "瓶蓋 −%d　直接通過" % HAGGLED_TOLL_CAPS,
					"requires": _skill("BARTER", 1), "requirement_label": "交易 略懂", "gate": GATE_CAPABILITY},
			]
			if not bool(context.get("stealth_failed", false)):
				opts.append({"id": &"SLIP_PAST", "label": "等天黑再摸過去", "detail": "耗時 1 天（水 −1、食物 −1）　嘗試潛行繞過路障"})
			opts.append({"id": &"DETOUR", "label": "繞路", "detail": "耗時 1 天（水 −1、食物 −1）"})
			return opts
		DEHYDRATED_TRAVELLER:
			return [
				{"id": &"GIVE_WATER", "label": "給他一份水", "detail": "水 −1　他也許身上有點什麼"},
				{"id": &"HYDRATE", "label": "用正確的方式讓他補水", "detail": "水 −1　不耽誤行程",
					"requires": _skill("SURVIVAL", 1), "requirement_label": "荒野求生 略懂", "gate": GATE_CAPABILITY},
				{"id": &"TAKE_PACK", "label": "拿走他的背包", "detail": "什麼也不付出　他還坐在那裡",
					"requires": _trait("GREEDY"), "requirement_label": "貪財", "gate": GATE_KNOWLEDGE},
				{"id": &"LEAVE", "label": "離開", "detail": "什麼也沒發生"},
			]
		REFUGEE_COLUMN:
			return [
				{"id": &"SHARE_FOOD", "label": "分一份糧食", "detail": "食物 −1　他們也許有東西可以回報"},
				{"id": &"TRADE_COLUMN", "label": "跟他們換東西", "detail": "瓶蓋 −%d　換他們身上還帶得動的" % COLUMN_TRADE_CAPS,
					"requires": _skill("BARTER", 1), "requirement_label": "交易 略懂", "gate": GATE_CAPABILITY},
				{"id": &"LEAVE", "label": "讓路讓他們過去", "detail": "什麼也沒發生"},
			]
		BANDIT_AMBUSH:
			return [
				{"id": &"FIGHT", "label": "正面迎戰", "detail": "進入戰鬥，擊退劫匪"},
				{"id": &"BRIBE", "label": "破財消災", "detail": "瓶蓋 −%d　交出財物以保平安" % BANDIT_BRIBE_CAPS},
				{"id": &"PARLEY", "label": "出言周旋", "detail": "嘗試說服劫匪少拿一些（成功 %d 瓶蓋，失敗 %d 瓶蓋）" % [BANDIT_PERSUADED_CAPS, BANDIT_BRIBE_CAPS]},
				{"id": &"FLEE_ROAD", "label": "尋隙逃跑", "detail": "耗時 1 天（水 −1、食物 −1）　狼狽脫身"},
			]
	return []

# ── Who can take which approach (S5-C2) ──────────────────────────────────────
# Requirements are written in the C1 clause vocabulary and evaluated by the
# capability profile itself, so the catalogue never re-implements eligibility.
# The catalogue is the ONLY place a requirement is declared, and the engine
# reads it back at commit time - so a UI holding a stale option list cannot buy
# the player an approach their character does not have.
#
# TWO KINDS OF GATE, because "you cannot" and "you would never think of it" are
# not the same sentence:
#
#   GATE_CAPABILITY - the character knows perfectly well that this could be
#       done; they just cannot do it. Anyone can see an engine in a wreck and
#       understand that someone could strip it. The option is SHOWN, disabled,
#       with what it would take. This is the only way the player ever learns
#       that a skill is worth raising: you have to see the locked door first.
#
#   GATE_KNOWLEDGE - the character does not know the option exists at all. You
#       cannot see a path through a rockslide that you have no idea is there,
#       and it is not "locked content" to you - it is not there. Hidden.
#
# Trait approaches are knowledge gates: a person who is not reckless does not
# stand in front of a landslide thinking about climbing it.
const GATE_CAPABILITY := "capability"
const GATE_KNOWLEDGE := "knowledge"
const GATE_ITEM := "item"

static func _skill(skill_id: String, min_rank: int) -> Dictionary:
	return {"all": [{"kind": "skill", "skill_id": skill_id, "min_rank": min_rank}]}

static func _trait(trait_id: String) -> Dictionary:
	return {"all": [{"kind": "trait_present", "trait_id": trait_id}]}

# {} means anyone on the road can choose it. Every encounter keeps at least one
# such ordinary option, so no character is ever left with nothing to answer.
static func option_requirements(encounter_type: StringName, option_id: StringName) -> Dictionary:
	for o in options(encounter_type):
		if o["id"] == option_id:
			return (o.get("requires", {}) as Dictionary).duplicate(true)
	return {}

static func option_requirement_label(encounter_type: StringName, option_id: StringName) -> String:
	for o in options(encounter_type):
		if o["id"] == option_id:
			return String(o.get("requirement_label", ""))
	return ""

static func option_gate(encounter_type: StringName, option_id: StringName) -> String:
	for o in options(encounter_type):
		if o["id"] == option_id:
			return String(o.get("gate", GATE_KNOWLEDGE))
	return ""

static func option_item_requirement(encounter_type: StringName, option_id: StringName) -> String:
	for o in options(encounter_type):
		if o["id"] == option_id:
			return String(o.get("requires_item", ""))
	return ""

static func has_option(encounter_type: StringName, option_id: StringName, context: Dictionary = {}) -> bool:
	for o in options(encounter_type, context):
		if o["id"] == option_id:
			return true
	return false

static func is_valid_type(encounter_type: StringName) -> bool:
	return encounter_type in [WRECK, ROCKSLIDE, ROADBLOCK, DEHYDRATED_TRAVELLER, REFUGEE_COLUMN, BANDIT_AMBUSH]

# Pending receipts loaded from disk must contain concrete, displayable facts.
static func valid_resolution(data: Dictionary) -> bool:
	if typeof(data.get("encounter_type")) != TYPE_STRING or typeof(data.get("option")) != TYPE_STRING:
		return false
	if not has_option(StringName(data.encounter_type), StringName(data.option)):
		return false
	for field in ["origin", "destination"]:
		if typeof(data.get(field)) != TYPE_STRING:
			return false
	var elapsed: Variant = data.get("elapsed_days")
	if typeof(elapsed) not in [TYPE_INT, TYPE_FLOAT] or (float(elapsed) != 0.0 and float(elapsed) != 1.0):
		return false
	for field in ["gained", "spent", "left_behind"]:
		if typeof(data.get(field)) != TYPE_DICTIONARY:
			return false
		for resource in data[field]:
			if resource not in ["water", "food", "scrap", "fuel", "caps"]:
				return false
			var amount: Variant = data[field][resource]
			if typeof(amount) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(amount)) or float(amount) <= 0 or float(amount) != floor(float(amount)):
				return false
	for field in ["items_gained", "items_left_behind"]:
		if data.has(field) and not valid_item_quantities(data[field]):
			return false
	if data.has("skill_practice") and not valid_practice_receipt(data.skill_practice,
		StringName(data.encounter_type), StringName(data.option)):
		return false
	return true

static func valid_practice_receipt(value: Variant, encounter_type: StringName, option_id: StringName) -> bool:
	return Capability.valid_practice_award(value, practice_skill(encounter_type, option_id))

static func valid_item_quantities(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	for item_id in value:
		if typeof(item_id) != TYPE_STRING:
			return false
		var resolved := ItemRegistry.resolve(item_id)
		if not resolved.success:
			return false
		var amount: Variant = value[item_id]
		if typeof(amount) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(amount)) or float(amount) <= 0 or float(amount) != floor(float(amount)):
			return false
		var definition: Dictionary = resolved.definition
		if (not definition.stackable and float(amount) != 1.0) or (definition.stackable and float(amount) > float(definition.max_stack)):
			return false
	return true

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

# ITEM-4: formal item loot remains a separate channel from the old aggregate
# resource yield. The same wreck facts produce the same item on replay, while a
# picked-over truck can still give no item at all. Item effects, rarity and
# equipment authority remain deferred.
static func wreck_item_yield(day: int, origin_id: StringName, destination_id: StringName, travel_day_index: int, option_id: StringName = &"SEARCH") -> Dictionary:
	var h := stable_hash("wreck-item|%s|%s>%s|%d|%d" % [String(option_id), String(origin_id), String(destination_id), day, travel_day_index])
	var roll := (h >> 1) % 12
	if roll <= 7:
		return {}
	match roll:
		8: return {"rusted_knife": 1}
		9: return {"flashlight": 1}
		10: return {"wrench": 1}
		_: return {"rope": 1}

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

# People who are already walking away from a failed town do not have much.
# Nearly half of them have nothing at all to give back.
static func refugee_yield(day: int, origin_id: StringName, destination_id: StringName, travel_day_index: int) -> Dictionary:
	var h := stable_hash("refugees|%s>%s|%d|%d" % [String(origin_id), String(destination_id), day, travel_day_index])
	var roll := h % 10
	if roll <= 4:
		return {}
	if roll <= 7:
		return {"scrap": 1}
	if roll == 8:
		return {"scrap": 2}
	return {"fuel": 1}

# ── S5-C2: what a capability actually buys you ───────────────────────────────
# Still no RNG. A different approach reads a DIFFERENT hash of the same wreck,
# so two characters standing in front of the same truck find different things,
# and each of them finds the same thing again on replay.
#
# None of these invent a world fact. They move existing resources and existing
# days around, which is all the simulation currently has authority over.

# A mechanic is not searching the wreck, they are dismantling it: they take the
# parts a scavenger would walk past. Rarely empty - they know what is worth
# pulling before they start - but it still costs the day.
static func strip_parts_yield(day: int, origin_id: StringName, destination_id: StringName, travel_day_index: int) -> Dictionary:
	var h := stable_hash("strip|%s>%s|%d|%d" % [String(origin_id), String(destination_id), day, travel_day_index])
	var roll := h % 10
	if roll == 0:
		return {"scrap": 2}
	if roll <= 5:
		return {"scrap": 3 + (h / 10) % 2, "fuel": 1}
	if roll <= 8:
		return {"scrap": 4, "fuel": 2}
	return {"scrap": 5 + (h / 10) % 2, "fuel": 3}

# A scavenger does not need the day. They can see from the roadside whether
# anything is left, take it and keep walking - which also means they take only
# what is within reach, and often there is nothing within reach at all.
static func quick_pick_yield(day: int, origin_id: StringName, destination_id: StringName, travel_day_index: int) -> Dictionary:
	var h := stable_hash("quickpick|%s>%s|%d|%d" % [String(origin_id), String(destination_id), day, travel_day_index])
	var roll := h % 10
	if roll <= 2:
		return {}
	if roll <= 6:
		return {"scrap": 1 + (h / 10) % 2}
	if roll <= 8:
		return {"scrap": 2, "fuel": 1}
	return {"fuel": 1}

# Water alone, handed over and walked away from, is a gamble on him managing
# it himself. Knowing how to rehydrate someone means staying long enough to
# make him drink slowly and seeing him stand up - and he gives back what he has
# rather than what he can spare.
#
# This is NOT medicine and does not claim to be. There is no injury, no
# treatment and no recovery state in this world, and the traveller is a
# roadside prop rather than a member of the population - so nothing here may
# imply that a wound was treated or a life was saved on the world's books.
static func hydrate_yield(day: int, origin_id: StringName, destination_id: StringName, travel_day_index: int) -> Dictionary:
	var h := stable_hash("hydrate|%s>%s|%d|%d" % [String(origin_id), String(destination_id), day, travel_day_index])
	var roll := h % 10
	if roll <= 3:
		return {"scrap": 2}
	if roll <= 6:
		return {"scrap": 2, "fuel": 1}
	if roll <= 8:
		return {"scrap": 1, "food": 1}
	return {"scrap": 3, "fuel": 1}

# You take the pack. There is no water in it - that is why he is sitting there -
# and nobody owes you anything for the taking, so it is whatever he still had.
static func take_pack_yield(day: int, origin_id: StringName, destination_id: StringName, travel_day_index: int) -> Dictionary:
	var h := stable_hash("takepack|%s>%s|%d|%d" % [String(origin_id), String(destination_id), day, travel_day_index])
	var roll := h % 10
	if roll <= 1:
		return {}
	if roll <= 5:
		return {"scrap": 2}
	if roll <= 8:
		return {"scrap": 2, "fuel": 1}
	return {"scrap": 3}

# People leaving a failed town will part with more for caps than for charity,
# but they are still carrying only what they could lift.
static func column_trade_yield(day: int, origin_id: StringName, destination_id: StringName, travel_day_index: int) -> Dictionary:
	var h := stable_hash("columntrade|%s>%s|%d|%d" % [String(origin_id), String(destination_id), day, travel_day_index])
	var roll := h % 10
	if roll <= 1:
		return {}
	if roll <= 5:
		return {"scrap": 2}
	if roll <= 8:
		return {"scrap": 2, "fuel": 1}
	return {"scrap": 1, "food": 1}

# Going over the slide costs no time and no scrap. What it costs is that one
# thing on your back does not come over with you - and you are told which,
# before you choose. C2 keeps capability differences legible on purpose:
# "reckless is faster and costs you a specific thing" is a decision, while
# "reckless usually works out" is a slot machine. Unpredictable outcomes can
# come back when the encounter system is mature enough to carry them.
const FORCE_THROUGH_LOSS_PRIORITY: Array[String] = ["scrap", "fuel", "water"]

# S5-C3b: Deterministic persuasion check for negotiation options.
# Uses world facts (min_security, route, day, index) and SPEECH rank. Zero RNG.
static func check_persuasion_success(encounter_type: StringName, origin_id: StringName, destination_id: StringName, day: int, travel_day_index: int, speech_rank: int, context: Dictionary = {}) -> bool:
	var h := stable_hash("speech|%s|%s>%s|%d|%d" % [String(encounter_type), String(origin_id), String(destination_id), day, travel_day_index])
	var roll := h % 100
	var base_threshold: int = 35
	match speech_rank:
		0: base_threshold = 35
		1: base_threshold = 60
		2: base_threshold = 80
		3: base_threshold = 95
		_: base_threshold = 100
	var sec: float = float(context.get("min_security", 50.0))
	var sec_mod: int = int((sec - 50.0) * 0.2)
	var threshold: int = clampi(base_threshold + sec_mod, 10, 100)
	return roll < threshold

# S5-C3c: Deterministic stealth check for novice/expert sneaking.
# BALANCE_PROVISIONAL: Rank 0 = 35%, Rank 1 = 70%, Rank 2+ = 100%.
# Pending human playtest review to consider 35 / 65 / 85 / 95. Zero RNG.
static func check_stealth_success(encounter_type: StringName, origin_id: StringName, destination_id: StringName, day: int, travel_day_index: int, stealth_rank: int, _context: Dictionary = {}) -> bool:
	if stealth_rank >= 2:
		return true # BALANCE_PROVISIONAL
	var h := stable_hash("stealth|%s|%s>%s|%d|%d" % [String(encounter_type), String(origin_id), String(destination_id), day, travel_day_index])
	var roll := h % 100
	var threshold: int = 35 if stealth_rank <= 0 else 70
	return roll < threshold


