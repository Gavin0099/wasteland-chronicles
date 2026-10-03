extends SceneTree

const Base = preload("res://tests/fixtures/gear2c_world.gd")
const Sheet = preload("res://ui/components/character_sheet.gd")
const CASES := {
	"inventory_weapon": ["rusted_knife", "balanced_combat_knife"],
	"inventory_tool": ["precision_repair_toolbox"],
	"inventory_supply": ["bandage", "first_aid_kit"],
	"inventory_back": ["expedition_travel_backpack"],
	"inventory_flavor": ["flashlight"],
	"empty": [], "market_gun": [], "market_bandage": [],
	"market_long": [],
	"market_long_full": ["sledgehammer", "military_backpack", "rope", "reinforced_saber", "old_world_saber", "wrench"],
}
var output_dir: String = OS.get_user_data_dir().path_join("captures/visible-item-descriptions")
var captures: int = 0

func _init() -> void: call_deferred("capture")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1152, 648)]:
		root.size = resolution
		for mode: String in CASES:
			var world: WorldState = Base.fresh("settlement:new_hope" if mode == "market_gun" else "settlement:gray_valley")
			var engine: SimulationEngine = SimulationEngine.new()
			for id: String in CASES[mode]: assert(world.player.item_inventory.pickup_item(id, 1).success)
			var unchanged: String = world.to_canonical_json()
			var shell: PlayableShell = PlayableShell.new()
			root.add_child(shell)
			shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			shell.setup(world, engine)
			if mode.begins_with("market"):
				shell._show_local_market()
				await process_frame
				var selected: String = "police_revolver" if mode == "market_gun" else ("expedition_travel_backpack" if mode.begins_with("market_long") else "bandage")
				shell.market_window.row_buttons[selected].pressed.emit()
				if mode == "market_long_full":
					shell.market_window.buy_button.pressed.emit()
					print("LONG MARKET NOTICE: " + shell.market_window.notice_label.text)
					assert(shell.market_window.notice_label.visible)
			else:
				shell._show_character()
				await process_frame
				for child: Node in shell.get_children():
					if child.get_script() == Sheet: child.inventory_jump.pressed.emit()
			for tick: int in range(12): await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [output_dir, mode, root.size.x, root.size.y]) == OK)
			assert(world.to_canonical_json() == unchanged and engine.validate_invariants(world) == "")
			captures += 1
			shell.queue_free()
			await process_frame
			await process_frame
	print("ITEM-DESC CAPTURE: %d actual frames -> %s" % [captures, output_dir])
	quit(0)
