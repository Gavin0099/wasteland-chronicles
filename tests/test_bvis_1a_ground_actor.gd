extends SceneTree

# ==============================================================================
# BVIS-1A: GROUND ACTOR CONTRACT TEST SUITE
# ==============================================================================
# Verifies the foundational 2.5D actor grounding invariants:
#   G1: Ground Anchor & Local Shadow Invariant (Shadow position is local ZERO)
#   G2: Foot Anchor Mapping (Authored foot UV maps strictly to local (0, 0))
#   G3: ActorLayer Y-Sorting & Hierarchy (Native Y-sort enabled, matching z_index)
#   G4: Unified Tween Motion (ActorRoot moves; Shadow stays at local ZERO after motion)
#   G5: Fail-Closed Security Boundary (Unregistered enemy IDs are rejected)
# ==============================================================================

const Stage = preload("res://ui/components/battle_stage.gd")

var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("BVIS-1A FAIL: " + label)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var stage := Stage.new()
	stage.size = Vector2(640, 360)
	root.add_child(stage)
	check(stage.configure("feral_dog", "scrap_machete", false), "G5: valid feral_dog config succeeds")

	# ---- G1 Ground Anchor & Local Shadow Invariant ----
	check(stage.hero_actor.position == stage.hero_origin, "G1: hero_actor sits at authoritative ground position")
	check(stage.enemy_actor.position == stage.enemy_origin, "G1: enemy_actor sits at authoritative ground position")
	check(stage.hero_actor.shadow.position == Vector2.ZERO, "G1: hero shadow is anchored at local Vector2.ZERO")
	check(stage.enemy_actor.shadow.position == Vector2.ZERO, "G1: enemy shadow is anchored at local Vector2.ZERO")
	check(stage.hero_shadow.position == Vector2.ZERO, "G1: hero_shadow alias points to local Vector2.ZERO")
	check(stage.enemy_shadow.position == Vector2.ZERO, "G1: enemy_shadow alias points to local Vector2.ZERO")

	# ---- G2 Foot Anchor Mapping ----
	var hero_foot_local: Vector2 = stage.hero_actor.get_local_foot_anchor()
	check(hero_foot_local.length() < 0.001, "G2: hero authored foot anchor maps exactly to Actor local (0, 0)")
	var enemy_foot_local: Vector2 = stage.enemy_actor.get_local_foot_anchor()
	check(enemy_foot_local.length() < 0.001, "G2: enemy authored foot anchor maps exactly to Actor local (0, 0)")

	# ---- G3 ActorLayer Y-Sorting & Hierarchy ----
	check(stage.actor_layer != null, "G3: actor_layer exists")
	check(stage.actor_layer.y_sort_enabled, "G3: actor_layer has native y_sort_enabled = true")
	check(stage.hero_actor.get_parent() == stage.actor_layer, "G3: hero_actor is direct child of actor_layer")
	check(stage.enemy_actor.get_parent() == stage.actor_layer, "G3: enemy_actor is direct child of actor_layer")
	check(stage.hero_actor.z_index == stage.enemy_actor.z_index, "G3: actors share same z_index for valid Y-sorting")

	# Normalized duel band check:
	# Hero Y should be deeper than Enemy Y by approx 7% of stage height
	var y_delta: float = stage.hero_origin.y - stage.enemy_origin.y
	var y_ratio: float = y_delta / stage.size.y
	check(y_ratio >= 0.05 and y_ratio <= 0.12, "G3: duel band vertical offset is normalized (7%%-11%% of height, got %.3f)" % y_ratio)

	# ---- G4 Unified Tween Motion ----
	# Run a turn animation with reduced_motion = false and verify coordinates
	stage.reduced_motion = false
	await stage.animate_turn("ATTACK", 4, 1)

	check(stage.hero_actor.position.distance_to(stage.hero_origin) < 0.01,
		"G4: hero_actor returns precisely to ground origin after ATTACK tween")
	check(stage.enemy_actor.position.distance_to(stage.enemy_origin) < 0.01,
		"G4: enemy_actor returns precisely to ground origin after ATTACK tween")
	check(stage.hero_actor.shadow.position == Vector2.ZERO,
		"G4: hero shadow remains strictly at local Vector2.ZERO after tween")
	check(stage.enemy_actor.shadow.position == Vector2.ZERO,
		"G4: enemy shadow remains strictly at local Vector2.ZERO after tween")

	# Test DEFEND motion
	await stage.animate_turn("DEFEND", 0, 0)
	check(stage.hero_actor.position.distance_to(stage.hero_origin) < 0.01,
		"G4: hero_actor at ground origin after DEFEND tween")
	check(stage.hero_actor.shadow.position == Vector2.ZERO,
		"G4: hero shadow remains at local Vector2.ZERO after DEFEND")

	# ---- G5 Fail-Closed Security Boundary ----
	var reject_result: bool = stage.configure("mutant_boss_unknown_999", "", false)
	check(not reject_result, "G5: unknown enemy_id is rejected by configure()")

	stage.free()

	if failures == 0:
		print("BVIS-1A ground actor contract: PASS; assertions=%d failures=0" % assertions)
		quit(0)
	else:
		print("BVIS-1A ground actor contract: FAIL; assertions=%d failures=%d" % [assertions, failures])
		quit(1)
