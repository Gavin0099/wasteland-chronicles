extends Node

const CreationScreen = preload("res://ui/character_creation_screen.gd")
const PlayableWorld = preload("res://game_data/playable_world.gd")
const SaveStore = preload("res://game_data/journey_save_store.gd")
const SaveDialog = preload("res://ui/components/save_game_dialog.gd")
const Backdrop = preload("res://ui/components/desktop_backdrop.gd")
var save_store: RefCounted = SaveStore.new()
var save_dialog: AcceptDialog
var opening_backdrop: Control
var engine: SimulationEngine
var world: WorldState
var creation: Control
var shell: PlayableShell

func _ready() -> void:
	engine = SimulationEngine.new()
	world = PlayableWorld.create_world()
	creation = CreationScreen.new()
	creation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(creation)
	creation.setup(world, engine)
	creation.journey_requested.connect(_enter_wasteland)
	creation.hide()
	opening_backdrop = Backdrop.new()
	opening_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(opening_backdrop)
	_open_save_menu(true)

func _enter_wasteland() -> void:
	if not creation.committed or world.player == null or shell != null:
		return
	_install_shell()
	creation.hide()

func _install_shell() -> void:
	shell = PlayableShell.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shell)
	shell.setup(world, engine)
	shell.save_menu_requested.connect(_open_save_menu)
	if not world.field_state.battle.is_empty() or world.field_state.receipt >= 0:
		shell._show_field()

func _begin_new_journey() -> void:
	_close_save_menu()
	opening_backdrop.hide()
	creation.show()

func _close_save_menu() -> void:
	if is_instance_valid(save_dialog):
		save_dialog.hide()
		save_dialog.queue_free()
	save_dialog = null

func _open_save_menu(opening: bool = false) -> void:
	if is_instance_valid(save_dialog):
		return
	save_dialog = SaveDialog.new()
	add_child(save_dialog)
	save_dialog.setup(opening, save_store.load_game())
	save_dialog.save_requested.connect(_save_game)
	save_dialog.load_requested.connect(_request_load)
	if opening:
		save_dialog.confirmed.connect(_begin_new_journey)
		save_dialog.canceled.connect(_begin_new_journey)
	else:
		save_dialog.confirmed.connect(_close_save_menu)
		save_dialog.canceled.connect(_close_save_menu)
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	save_dialog.popup_centered(Vector2i(mini(640, int(viewport.x) - 40), mini(380, int(viewport.y) - 40)))
	if opening and not save_dialog.load_button.disabled:
		save_dialog.load_button.grab_focus()
	else:
		save_dialog.get_ok_button().grab_focus()

func _save_game() -> void:
	var result: Dictionary = save_store.save_game(world)
	if result.success:
		save_dialog.update_slot(save_store.load_game())
		save_dialog.message.text = "已存檔。離開後可從主畫面繼續這段旅程。"
	else:
		save_dialog.message.text = "存檔失敗，原存檔未覆寫。請確認存檔資料夾可寫入後再試。"

func _request_load() -> void:
	var stored: Dictionary = save_store.load_game()
	save_dialog.update_slot(stored)
	if not stored.success:
		save_dialog.message.text = "讀檔失敗，目前進度仍保留。"
		return
	if save_dialog.opening:
		_load_game(stored.fingerprint)
	else:
		save_dialog.show_load_confirmation(stored, func() -> void: _load_game(stored.fingerprint))

func _load_game(expected_fingerprint: String) -> void:
	var stored: Dictionary = save_store.load_game()
	if not stored.success or stored.fingerprint != expected_fingerprint:
		save_dialog.update_slot(stored)
		save_dialog.message.text = "讀檔失敗或存檔已變更，目前進度仍保留。請重新選擇讀檔。"
		return
	# Complete validation precedes the only live-world handoff.
	if is_instance_valid(shell):
		shell.hide()
		remove_child(shell)
		shell.queue_free()
	world = stored.world
	creation.hide()
	opening_backdrop.hide()
	_close_save_menu()
	_install_shell()
