extends SceneTree

# Hand-play, more than once: "人物戰鬥裝備沒裝好" - the weapon floated beside the
# fighter. This holds the fix: every weapon hangs off the body, is drawn behind
# it, and its grip lands on the front fist of the drifter art.

const Stage = preload("res://ui/components/battle_stage.gd")

var assertions := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures += 1
		push_error("WEAPON-GRIP: " + label)

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var stage = Stage.new()
	stage.size = Vector2(800, 450)
	root.add_child(stage)
	await process_frame
	var hand_uv: Vector2 = Stage.VISUAL_PROFILES.drifter.hand_uv
	for weapon_id in Stage.WEAPON_GRIPS.keys():
		check(stage.configure("bandit", weapon_id, true), "%s: stage configures" % weapon_id)
		stage.refresh(true, true)
		await process_frame
		var actor = stage.hero_actor
		var weapon: Sprite2D = actor.weapon
		check(weapon.visible and weapon.texture != null, "%s: the weapon is shown" % weapon_id)
		check(weapon.get_parent() == actor.body, "%s: it hangs off the body, so it follows every pose" % weapon_id)
		check(weapon.show_behind_parent, "%s: drawn behind the body, so the fist covers the handle" % weapon_id)
		# Where the grip is on screen, against where the fist is on screen.
		var w_size := Vector2(weapon.texture.get_width(), weapon.texture.get_height())
		var source_grip: Vector2 = Stage.WEAPON_GRIPS[weapon_id].grip
		var displayed_grip := Vector2(1.0 - source_grip.x, source_grip.y) if weapon.flip_h else source_grip
		var grip_px: Vector2 = w_size * displayed_grip
		var grip_screen: Vector2 = weapon.get_global_transform() * (weapon.offset + grip_px)
		var b_size := Vector2(actor.body.texture.get_width(), actor.body.texture.get_height())
		var fist_screen: Vector2 = actor.body.get_global_transform() * (actor.body.offset + b_size * hand_uv)
		check(grip_screen.distance_to(fist_screen) < 2.0, "%s: the grip is in the fist (%.1f px off)" % [weapon_id, grip_screen.distance_to(fist_screen)])
		var length_on_screen: float = w_size.x * weapon.get_global_transform().get_scale().x
		check(length_on_screen > actor.target_height * 0.15 and length_on_screen < actor.target_height * 0.45,
			"%s: a believable size next to the fighter (%.0f px on a %.0f px fighter)" % [weapon_id, length_on_screen, actor.target_height])
	print("WEAPON-GRIP: %s; assertions=%d failures=%d" % ["PASS" if failures == 0 else "FAIL", assertions, failures])
	quit(1 if failures > 0 else 0)
