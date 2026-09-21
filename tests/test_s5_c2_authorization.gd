extends SceneTree

# ==============================================================================
# S5-C2-A : AUTHORITY / SAFETY  (the half that does not depend on how it feels)
# ==============================================================================
# C2 closure is deliberately split. C2-B (does a different character actually
# FEEL different to play) can only be answered by hand-playing. C2-A is this
# file: whatever the playtest later decides about HYDRATE, STRIP_PARTS, a new
# Speech option or which gates are hidden versus greyed out, this rule does not
# move:
#
#     showing an option  !=  being allowed to take it
#
# The UI projection is a hint. The commit boundary is the authority. Every gate
# below either proves that an unauthorized choice is refused, or that a refused
# choice left the world byte-identical.
#
#   A1  An approach the character has not unlocked is refused, hidden or not
#   A2  A stale/tampered choice from a capability the player no longer has
#   A3  Double resolution and resolution with nothing on the road
#   A4  An option that does not belong to THIS encounter
#   A5  Requirement failure mutates nothing (SHA-256 identical)
#   A6  Resource shortage mutates nothing (SHA-256 identical)
#   A7  Eligibility survives save/load unchanged, option for option
#   A8  Same world + same encounter + different build -> different legal set
#       and different deterministic consequence; same build -> identical world
#
# Staged encounters: A1-A8 write `world.active_encounter` directly so that four
# builds answer the SAME encounter on the same day. That is the same state shape
# the loader reconstructs from a save, and selection itself is already covered
# by S5-B4 E1. What is under test here is authorization, not generation.
# ==============================================================================

const Intent = preload("res://simulation/character_creation_intent.gd")
const Enc = preload("res://simulation/travel_encounter.gd")
const Profile = preload("res://simulation/capability_profile.gd")
const Catalogue = preload("res://simulation/background_catalogue.gd")

const ORIGIN := &"settlement:gray_valley"
const DESTINATION := &"settlement:new_hope"
const FIXED_DAY := 12
const FIXED_INDEX := 1

var engine := SimulationEngine.new()
var failed := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failed += 1
		push_error("FAIL: " + message)
		print("  FAIL: " + message)

func staged(background: String, traits: Array, encounter_type: StringName, water: int = 8, caps: int = 200) -> WorldState:
	var w := S1WorldData.create_s1_world()
	var res := engine.commit_character_creation(w, Intent.new({
		"source_settlement_id": String(ORIGIN), "character_name": "Drifter", "age": 25,
		"background_id": background, "trait_ids": traits,
	}))
	check(res.success, "fixture creation must succeed: " + background)
	w.player.inventory.set_amount("water", water)
	w.player.inventory.set_amount("food", 8)
	w.player.inventory.set_amount("scrap", 2)
	w.player.inventory.set_amount("fuel", 0)
	w.player.money = caps
	engine.commit_player_intent(w, PlayerIntent.create_travel(w.player.npc_id, DESTINATION))
	w.pending_encounter_result = -1
	w.active_encounter = TravelEncounterState.create(
		encounter_type, FIXED_DAY, ORIGIN, DESTINATION, FIXED_INDEX,
		{"min_security": 40.0, "headcount": 12, "origin_name": "Gray Valley", "destination_name": "New Hope"})
	return w

func sha(w: WorldState) -> String:
	return w.to_canonical_json().sha256_text()

func resolve(w: WorldState, option_id: StringName) -> Dictionary:
	return engine.commit_player_intent(w, PlayerIntent.create_resolve_encounter(w.player.npc_id, option_id))

func projected_ids(w: WorldState) -> PackedStringArray:
	var ids := PackedStringArray()
	for o in PlayerUIProjection.project(w).active_encounter.options:
		ids.append("%s:%s:%s" % [String(o.id), "locked" if bool(o.get("locked", false)) else "open", str(bool(o.enabled))])
	return ids

func _init() -> void:
	print("================================================================================")
	print("      WASTELAND CHRONICLES - S5-C2-A AUTHORITY / SAFETY SUITE                   ")
	print("================================================================================")

	# --------------------------------------------------------------------------
	print("\n--- [GATE A1] An approach the character has not unlocked is refused ---")

	# Both kinds of gate are enforced identically at the boundary. Hiding an
	# option is presentation; it is NOT the thing that stops it being taken.
	var guard := staged("CARAVAN_GUARD", [], Enc.WRECK)
	var capability_gated := resolve(guard, &"STRIP_PARTS")   # shown greyed out
	var knowledge_gated := resolve(guard, &"QUICK_PICK")     # not shown at all
	check(not capability_gated.get("success", false), "a capability-gated approach must be refused")
	check(not knowledge_gated.get("success", false), "a knowledge-gated approach must be refused")
	check(String(capability_gated.get("error", "")).begins_with("CAPABILITY_NOT_MET"),
		"refusal must name the capability, got: " + String(capability_gated.get("error", "")))
	check(String(knowledge_gated.get("error", "")).begins_with("CAPABILITY_NOT_MET"),
		"hidden options are refused by the same rule, got: " + String(knowledge_gated.get("error", "")))
	check(guard.active_encounter != null and guard.pending_encounter_result < 0,
		"a refused choice leaves the encounter unanswered")

	# The same two approaches ARE allowed for the characters that have them.
	var mechanic := staged("MECHANIC", [], Enc.WRECK)
	check(engine.authorize_encounter_option(mechanic, &"STRIP_PARTS") == "",
		"the mechanic must be allowed to strip the wreck - otherwise A1 is vacuous")
	var scavenger := staged("SCAVENGER", [], Enc.WRECK)
	check(engine.authorize_encounter_option(scavenger, &"QUICK_PICK") == "",
		"the scavenger must be allowed the quick pick - otherwise A1 is vacuous")

	# A trait approach is a trait approach, not a skill one.
	var plain := staged("SCAVENGER", [], Enc.ROCKSLIDE)
	var reckless := staged("SCAVENGER", ["RECKLESS"], Enc.ROCKSLIDE)
	check(engine.authorize_encounter_option(plain, &"FORCE_THROUGH") != "",
		"without the trait, the trait approach is refused")
	check(engine.authorize_encounter_option(reckless, &"FORCE_THROUGH") == "",
		"with the trait, the trait approach is allowed")
	print("  Capability, knowledge and trait gates all enforced at the commit boundary")

	# --------------------------------------------------------------------------
	print("\n--- [GATE A2] A choice held over from a capability you no longer have ---")

	# The UI read the options while the character could strip a wreck. Between
	# the projection and the commit, the profile changed (a tampered save, a
	# stale screen, a replayed intent). The boundary must re-check, not trust.
	var swapped := staged("MECHANIC", [], Enc.WRECK)
	var stale_options := projected_ids(swapped)
	check("STRIP_PARTS:open:true" in stale_options, "fixture must start with the approach available")
	swapped.player.capability = Profile.from_dict_checked({
		"npc_id": String(swapped.player.npc_id), "creation_origin": "CHARACTER_CREATION",
		"skill_ranks": Catalogue.resolve("FARMER").ranks,
		"selected_creation_traits": [], "background_id": "FARMER", "package_version": 1,
	}).profile
	var stale := resolve(swapped, &"STRIP_PARTS")
	check(not stale.get("success", false), "a choice from a capability the player no longer has must be refused")

	# And with no capability profile at all, a gated approach is still refused -
	# it must never fail OPEN into "unknown means allowed".
	var legacy := staged("MECHANIC", [], Enc.WRECK)
	legacy.player.capability = null
	var no_profile := resolve(legacy, &"STRIP_PARTS")
	check(not no_profile.get("success", false), "a missing capability profile must fail closed")
	check(String(no_profile.get("error", "")).begins_with("CAPABILITY_UNAVAILABLE"),
		"a missing profile is named as such, got: " + String(no_profile.get("error", "")))
	# The ordinary approach stays available to a character with no profile, so
	# failing closed never strands the player in front of an unanswerable road.
	check(engine.authorize_encounter_option(legacy, &"SEARCH") == "",
		"an ungated approach must remain available without a profile")
	print("  Stale, swapped and absent capabilities all fail closed")

	# --------------------------------------------------------------------------
	print("\n--- [GATE A3] Double resolution, and answering an empty road ---")

	var once := staged("MECHANIC", [], Enc.WRECK)
	var first := resolve(once, &"STRIP_PARTS")
	check(first.get("success", false), "the first legal resolution must succeed")
	check(once.pending_encounter_result >= 0, "resolution must leave exactly one receipt")
	var receipt_index := once.pending_encounter_result
	var ledger_size := once.event_log.size()
	var second := resolve(once, &"STRIP_PARTS")
	check(not second.get("success", false), "resolving twice must be refused")
	check(once.pending_encounter_result == receipt_index and once.event_log.size() == ledger_size,
		"a refused second resolution must not write a second receipt")

	# A receipt is consumed exactly once, and only the real one.
	var wrong_receipt := engine.commit_player_intent(once,
		PlayerIntent.create_continue_journey(once.player.npc_id, receipt_index + 7))
	check(not wrong_receipt.get("success", false), "continuing on a receipt that is not the pending one must be refused")
	check(once.pending_encounter_result == receipt_index, "a refused continue must not consume the receipt")
	var continued := engine.commit_player_intent(once,
		PlayerIntent.create_continue_journey(once.player.npc_id, receipt_index))
	check(continued.get("success", false), "the real receipt must be accepted once")
	var replayed := engine.commit_player_intent(once,
		PlayerIntent.create_continue_journey(once.player.npc_id, receipt_index))
	check(not replayed.get("success", false), "a consumed receipt must not be replayable")

	var nothing := staged("MECHANIC", [], Enc.WRECK)
	nothing.active_encounter = null
	var empty_road := resolve(nothing, &"STRIP_PARTS")
	check(not empty_road.get("success", false), "answering an encounter that is not there must be refused")
	check(String(empty_road.get("error", "")).begins_with("NO_ACTIVE_ENCOUNTER"),
		"an empty road is named as such, got: " + String(empty_road.get("error", "")))
	print("  One encounter, one resolution, one receipt, consumed once")

	# --------------------------------------------------------------------------
	print("\n--- [GATE A4] An option that does not belong to this encounter ---")

	var mismatch := staged("MECHANIC", [], Enc.ROADBLOCK)
	for foreign in [&"STRIP_PARTS", &"QUICK_PICK", &"SCOUT_PATH", &"HYDRATE", &"TRADE_COLUMN", &"INVENTED"]:
		var res_foreign := resolve(mismatch, foreign)
		check(not res_foreign.get("success", false), "%s must not be answerable at a roadblock" % foreign)
		check(String(res_foreign.get("error", "")).begins_with("INVALID_OPTION"),
			"a foreign option is refused as invalid, not as a capability problem: " + String(res_foreign.get("error", "")))
	check(mismatch.active_encounter != null, "the roadblock is still waiting for a real answer")
	print("  Encounter identity is checked before capability")

	# --------------------------------------------------------------------------
	print("\n--- [GATE A5] A refused requirement changes nothing ---")

	for probe in [
		{"bg": "CARAVAN_GUARD", "enc": Enc.WRECK, "opt": &"STRIP_PARTS"},
		{"bg": "CARAVAN_GUARD", "enc": Enc.WRECK, "opt": &"QUICK_PICK"},
		{"bg": "MECHANIC", "enc": Enc.ROADBLOCK, "opt": &"HAGGLE"},
		{"bg": "MECHANIC", "enc": Enc.ROADBLOCK, "opt": &"SLIP_PAST"},
		{"bg": "MECHANIC", "enc": Enc.DEHYDRATED_TRAVELLER, "opt": &"HYDRATE"},
		{"bg": "MECHANIC", "enc": Enc.ROCKSLIDE, "opt": &"FORCE_THROUGH"},
		{"bg": "MECHANIC", "enc": Enc.DEHYDRATED_TRAVELLER, "opt": &"TAKE_PACK"},
		{"bg": "SCAVENGER", "enc": Enc.REFUGEE_COLUMN, "opt": &"TRADE_COLUMN"},
	]:
		var w := staged(String(probe.bg), [], probe.enc)
		var before := sha(w)
		var refused := resolve(w, probe.opt)
		check(not refused.get("success", false), "%s must be refused for %s" % [probe.opt, probe.bg])
		check(sha(w) == before, "a refused %s must leave the world byte-identical" % probe.opt)
	print("  Eight refused approaches, eight identical world hashes")

	# --------------------------------------------------------------------------
	print("\n--- [GATE A6] A capability you have but cannot afford changes nothing ---")

	# Being eligible is not being able. These options pass the capability check
	# and then fail on resources, which must be just as clean a refusal.
	for probe2 in [
		{"bg": "FARMER", "enc": Enc.ROADBLOCK, "opt": &"HAGGLE", "water": 8, "caps": 3},
		{"bg": "FARMER", "enc": Enc.REFUGEE_COLUMN, "opt": &"TRADE_COLUMN", "water": 8, "caps": 3},
		{"bg": "FARMER", "enc": Enc.DEHYDRATED_TRAVELLER, "opt": &"HYDRATE", "water": 0, "caps": 200},
	]:
		var w2 := staged(String(probe2.bg), [], probe2.enc, int(probe2.water), int(probe2.caps))
		check(String(engine.authorize_encounter_option(w2, probe2.opt)).begins_with("INSUFFICIENT"),
			"%s must fail on resources, not on capability" % probe2.opt)
		var before2 := sha(w2)
		var broke := resolve(w2, probe2.opt)
		check(not broke.get("success", false), "%s must be refused when unaffordable" % probe2.opt)
		check(sha(w2) == before2, "an unaffordable %s must leave the world byte-identical" % probe2.opt)
	print("  Capability passes, resources refuse, and nothing moves")

	# --------------------------------------------------------------------------
	print("\n--- [GATE A7] Eligibility survives save / load, option for option ---")

	for background in ["CARAVAN_GUARD", "MECHANIC", "FARMER", "SCAVENGER"]:
		for encounter_type in [Enc.WRECK, Enc.ROCKSLIDE, Enc.ROADBLOCK, Enc.DEHYDRATED_TRAVELLER, Enc.REFUGEE_COLUMN]:
			var live := staged(background, ["RECKLESS", "GREEDY"], encounter_type)
			var loaded := WorldState.from_json(JSON.stringify(live.to_dict()))
			check(loaded != null, "a world paused on an encounter must reload")
			if loaded == null:
				continue
			check(sha(live) == sha(loaded), "round trip must be byte-identical: %s/%s" % [background, encounter_type])
			check(projected_ids(live) == projected_ids(loaded),
				"the same options must be offered after a reload: %s/%s" % [background, encounter_type])
			# Not just the same list - the same verdict, reason for reason.
			for o in Enc.options(encounter_type):
				check(engine.authorize_encounter_option(live, o["id"]) == engine.authorize_encounter_option(loaded, o["id"]),
					"authorization verdict must survive the round trip: %s/%s" % [background, o["id"]])
	print("  20 build/encounter pairs: identical hashes, identical offers, identical verdicts")

	# --------------------------------------------------------------------------
	print("\n--- [GATE A8] Different build -> different legal set, different consequence ---")

	# The first half of the closure criterion, asserted rather than eyeballed:
	# same world, same encounter, different character, different legal answers.
	var sets := {}
	for background2 in ["CARAVAN_GUARD", "MECHANIC", "FARMER", "SCAVENGER"]:
		var legal := PackedStringArray()
		for encounter_type2 in [Enc.WRECK, Enc.ROCKSLIDE, Enc.ROADBLOCK, Enc.DEHYDRATED_TRAVELLER, Enc.REFUGEE_COLUMN]:
			var w3 := staged(background2, [], encounter_type2)
			for o in Enc.options(encounter_type2):
				if engine.authorize_encounter_option(w3, o["id"]) == "":
					legal.append("%s/%s" % [encounter_type2, o["id"]])
		sets[background2] = legal
	check(sets["MECHANIC"] != sets["SCAVENGER"], "mechanic and scavenger must not have the same answers")
	check(sets["FARMER"] != sets["CARAVAN_GUARD"], "farmer and guard must not have the same answers")
	check(sets["MECHANIC"] != sets["FARMER"], "mechanic and farmer must not have the same answers")
	for background3 in sets:
		check(PackedStringArray(sets[background3]).size() > 0, "every build must be able to answer the road: " + background3)

	# Same encounter, two builds, two different worlds afterwards.
	var m := staged("MECHANIC", [], Enc.WRECK)
	var s := staged("SCAVENGER", [], Enc.WRECK)
	var m_res := resolve(m, &"STRIP_PARTS")
	var s_res := resolve(s, &"QUICK_PICK")
	check(m_res.get("success", false) and s_res.get("success", false), "both builds must be able to act")
	check(m_res.gained != s_res.gained or int(m_res.elapsed_days) != int(s_res.elapsed_days),
		"two builds answering the same wreck must not get identical outcomes")

	# ...and the same build twice is exactly the same world. No RNG anywhere.
	var twin_a := staged("MECHANIC", [], Enc.WRECK)
	var twin_b := staged("MECHANIC", [], Enc.WRECK)
	resolve(twin_a, &"STRIP_PARTS")
	resolve(twin_b, &"STRIP_PARTS")
	check(sha(twin_a) == sha(twin_b), "the same build answering the same wreck must produce the same world")
	print("  Builds diverge from each other and replay identically to themselves")
	print("  Replay SHA-256 (MECHANIC / STRIP_PARTS): %s" % sha(twin_a))

	# --------------------------------------------------------------------------
	check(engine.validate_invariants(m) == "", "global invariants hold after a capability resolution")
	check(engine.validate_invariants(s) == "", "global invariants hold after a capability resolution")

	print("\n================================================================================")
	if failed > 0:
		print("S5-C2-A FAILED: %d check(s) did not hold." % failed)
		quit(1)
		return
	print("ALL S5-C2-A AUTHORITY GATES (A1 ~ A8) PASSED CLEANLY!")
	print("  This proves the boundary is safe. It does NOT prove C2 is fun:")
	print("  C2-B Player Experience still needs four Backgrounds played by hand.")
	print("================================================================================")
	quit()
