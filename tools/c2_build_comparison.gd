extends SceneTree

# ==============================================================================
# S5-C2 BUILD COMPARISON — an OBSERVATION tool, not a test suite
# ==============================================================================
# It answers the objective half of the hand-play table: given the SAME world,
# the SAME road and the SAME encounter, what does each Background actually see,
# and what does each choice actually cost and return?
#
# It cannot answer the half that matters most - whether a locked option makes
# you want to learn the skill - because that is a feeling, not a number. Only
# playing answers that.
#
# Nothing here is authority. It reads the catalogue, the projection and the
# engine exactly as the game does, and prints what they say.
# ==============================================================================

const Intent = preload("res://simulation/character_creation_intent.gd")
const Enc = preload("res://simulation/travel_encounter.gd")
const Profile = preload("res://simulation/capability_profile.gd")

const BACKGROUNDS := ["CARAVAN_GUARD", "MECHANIC", "FARMER", "SCAVENGER"]
const ORIGIN := &"settlement:gray_valley"
const DESTINATION := &"settlement:new_hope"
const FIXED_DAY := 12
const FIXED_INDEX := 1

var engine := SimulationEngine.new()

# Identical starting conditions for every build: same world, same supplies, same
# road, same day. The ONLY difference between the four runs is who the player is.
func build(background: String, traits: Array) -> WorldState:
	var w := S1WorldData.create_s1_world()
	var res := engine.commit_character_creation(w, Intent.new({
		"source_settlement_id": String(ORIGIN), "character_name": "Drifter", "age": 25,
		"background_id": background, "trait_ids": traits,
	}))
	if not res.success:
		push_error("creation failed: %s" % res)
		return w
	w.player.inventory.set_amount("water", 8)
	w.player.inventory.set_amount("food", 8)
	w.player.inventory.set_amount("scrap", 2)
	w.player.inventory.set_amount("fuel", 0)
	w.player.money = 200
	engine.commit_player_intent(w, PlayerIntent.create_travel(w.player.npc_id, DESTINATION))
	return w

func staged(background: String, traits: Array, encounter_type: StringName) -> WorldState:
	var w := build(background, traits)
	# Overwrite whatever the road happened to produce, so all four builds answer
	# the same encounter on the same day with the same context.
	w.pending_encounter_result = -1
	w.active_encounter = TravelEncounterState.create(
		encounter_type, FIXED_DAY, ORIGIN, DESTINATION, FIXED_INDEX,
		{"min_security": 40.0, "headcount": 12, "origin_name": "Gray Valley", "destination_name": "New Hope"})
	return w

func label_of(encounter_type: StringName, option_id: String) -> String:
	for o in Enc.options(encounter_type):
		if String(o["id"]) == option_id:
			return String(o["label"])
	return option_id

func amounts(d: Dictionary) -> String:
	var parts := PackedStringArray()
	for k in ["water", "food", "scrap", "fuel", "caps"]:
		if int(d.get(k, 0)) > 0:
			parts.append("%s %d" % [k, int(d[k])])
	return ", ".join(parts) if not parts.is_empty() else "-"

func _init() -> void:
	var encounters := [Enc.WRECK, Enc.ROCKSLIDE, Enc.ROADBLOCK, Enc.DEHYDRATED_TRAVELLER, Enc.REFUGEE_COLUMN]

	print("================================================================================")
	print(" S5-C2 BUILD COMPARISON  (same world, same road, day %d, index %d)" % [FIXED_DAY, FIXED_INDEX])
	print("================================================================================")

	var locked_counts := {}
	for encounter_type in encounters:
		print("\n■ %s — %s" % [encounter_type, Enc.title(encounter_type)])
		for background in BACKGROUNDS:
			var w := staged(background, [], encounter_type)
			var proj: Dictionary = PlayerUIProjection.project(w).active_encounter
			var open_ids := PackedStringArray()
			var locked_ids := PackedStringArray()
			var shown := {}
			for o in proj.options:
				shown[String(o.id)] = true
				if bool(o.get("locked", false)):
					locked_ids.append("%s〔需要 %s〕" % [label_of(encounter_type, String(o.id)), String(o.requirement_label)])
				elif bool(o.enabled):
					open_ids.append(String(o.id))
			var hidden_ids := PackedStringArray()
			for o in Enc.options(encounter_type):
				if not shown.has(String(o["id"])):
					hidden_ids.append(String(o["id"]))
			locked_counts[background] = int(locked_counts.get(background, 0)) + locked_ids.size()
			print("  %-14s 可選 %d：%s" % [background, open_ids.size(), ", ".join(open_ids)])
			if locked_ids.size() > 0:
				print("  %-14s 灰 %d：%s" % ["", locked_ids.size(), ", ".join(locked_ids)])
			if hidden_ids.size() > 0:
				print("  %-14s 隱藏：%s" % ["", ", ".join(hidden_ids)])

	# What each capability approach actually does, committed through the real
	# engine on an identical world. This is the "different deterministic
	# consequence" half of the closure criterion, observed rather than asserted.
	print("\n================================================================================")
	print(" WHAT EACH CAPABILITY APPROACH ACTUALLY COSTS AND RETURNS")
	print("================================================================================")
	for encounter_type in encounters:
		for o in Enc.options(encounter_type):
			var option_id := StringName(String(o["id"]))
			var req: Dictionary = o.get("requires", {})
			# Pick a build that can take it; traits are supplied where needed.
			for background in BACKGROUNDS:
				var traits := ["RECKLESS", "GREEDY"] if not req.is_empty() and String(o.get("requirement_label", "")) in ["魯莽", "貪財"] else []
				var w := staged(background, traits, encounter_type)
				if engine.authorize_encounter_option(w, option_id) != "":
					continue
				var before_day: int = w.current_day
				var r: Dictionary = engine.commit_encounter_choice(w, option_id)
				print("%-22s %-13s 獲得 %-22s 消耗 %-24s 天 +%d" % [
					String(encounter_type), String(option_id),
					amounts(r.gained), amounts(r.spent), w.current_day - before_day])
				break

	print("\n================================================================================")
	print(" WHICH SKILLS HAVE A STAGE IN THE WORLD AT ALL")
	print("================================================================================")
	var stage := {}
	for skill in Profile.SKILLS:
		stage[skill] = 0
	for encounter_type in encounters:
		for o in Enc.options(encounter_type):
			for clause in (o.get("requires", {}) as Dictionary).get("all", []):
				if clause.kind == "skill":
					stage[clause.skill_id] = int(stage[clause.skill_id]) + 1
	for skill in Profile.SKILLS:
		print("  %-12s %s" % [skill, "使用 %d 次" % int(stage[skill]) if int(stage[skill]) > 0 else "— 世界目前沒有提供舞台"])

	print("\n 每個 Background 在五個遭遇合計看到的灰選項：")
	for background in BACKGROUNDS:
		print("  %-14s %d" % [background, int(locked_counts.get(background, 0))])
	quit()
