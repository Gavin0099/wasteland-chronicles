extends SceneTree

# ==============================================================================
# PLAY-1 BATTLE TRUTH — the screen must not contradict the game
# ==============================================================================
# Found by hand-play: "就算裝備裝備 打的時候也沒有裝備在手上" and "敵人只有一種
# 是狼". Both were true and neither was a simulation bug. The stage hardcoded a
# supply-shed background, a feral dog and a crowbar, so a road ambush drew a dog
# standing in a shed while the label said 荒原劫匪, and equipping a machete
# changed the damage and the text while the hand held a crowbar or nothing.
#
#   G1  the weapon shown is the weapon actually equipped
#   G2  an unarmed fighter shows nothing in hand
#   G3  a road ambush and a shed fight do not look the same
#   G4  a placeholder is admitted as one rather than passed off as art
#   G5  none of this touches a combat number
#
# This is a presentation contract. It exists because the previous version broke
# silently: nothing failed, the picture was simply wrong.
# ==============================================================================

const Stage = preload("res://ui/components/battle_stage.gd")
const Creation = preload("res://simulation/character_creation_intent.gd")
const Field = preload("res://simulation/field_adventure.gd")

var engine := SimulationEngine.new()
var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("PLAY-1: " + label)

func _init() -> void:
	call_deferred("run")

func stage() -> Control:
	var s = Stage.new()
	s.size = Vector2(640, 360)
	root.add_child(s)
	return s

func run() -> void:
	var world := S1WorldData.create_s1_world()
	check(engine.commit_character_creation(world, Creation.new({
		"source_settlement_id": "settlement:gray_valley", "character_name": "Stage Tester",
		"age": 30, "background_id": "CARAVAN_GUARD", "trait_ids": [],
	})).success, "character creation succeeds")

	# ---- G1 the hand follows the equipment ----
	var shed := stage()
	shed.configure("feral_dog", "scrap_machete", false)
	var machete_art: Variant = shed.weapon.texture
	check(shed.weapon.visible, "G1: an equipped weapon is shown")
	check(machete_art != null, "G1: the machete resolves to real art")

	shed.configure("feral_dog", "hunting_knife", false)
	check(shed.weapon.visible and shed.weapon.texture != machete_art,
		"G1: changing the equipped weapon really changes the picture")

	shed.configure("feral_dog", "crowbar", false)
	check(shed.weapon.visible, "G1: the legacy crowbar still shows")

	# ---- G2 empty hands look empty ----
	shed.configure("feral_dog", "", false)
	check(not shed.weapon.visible, "G2: an unarmed fighter holds nothing")

	# ---- G3 the two fights must not look alike ----
	shed.configure("feral_dog", "rebar_club", false)
	shed.refresh(false, true)
	check(shed.enemy.visible and not shed.enemy_placeholder.visible, "G3: the shed fight shows the dog art")
	check(shed.shed_background.visible and not shed.road_background.visible, "G3: the shed fight is in the shed")

	var road := stage()
	road.configure("bandit", "rebar_club", true)
	road.refresh(false, true)
	check(road.enemy.visible and not road.enemy_placeholder.visible, "G3: a bandit shows genuine art")
	check(road.enemy.texture != null and road.enemy.texture != shed.enemy.texture, "G3: a bandit is not drawn as the dog")
	check(road.road_background.visible and not road.shed_background.visible, "G3: the road is not the supply shed")

	# ---- G4 honesty about the stand-in ----
	check(not road.placeholder_note.visible, "G4: genuine bandit art carries no placeholder label")
	check(not shed.placeholder_note.visible, "G4: real dog art carries no placeholder label")

	# ---- G3 a dead enemy disappears in both presentations ----
	road.refresh(false, false)
	check(not road.enemy_placeholder.visible and not road.enemy.visible, "G3: a beaten bandit leaves the stage")
	shed.refresh(false, false)
	check(not shed.enemy.visible, "G3: a beaten dog leaves the stage")

	# ---- G5 the stage moves no combat number ----
	var before := world.to_canonical_json()
	var damage_before: int = Field.attack_damage(world)
	var dressed := stage()
	for weapon_id in ["", "crowbar", "rusted_knife", "hunting_knife", "rebar_club", "scrap_machete"]:
		dressed.configure("bandit", weapon_id, true)
		dressed.configure("feral_dog", weapon_id, false)
	check(world.to_canonical_json() == before, "G5: dressing the stage cannot touch world state")
	check(Field.attack_damage(world) == damage_before, "G5: dressing the stage cannot change damage")

	if failures == 0:
		print("PLAY-1 battle truth: PASS; assertions=%d failures=0" % assertions)
		quit(0)
	else:
		print("PLAY-1 battle truth: FAIL; assertions=%d failures=%d" % [assertions, failures])
		quit(1)
