extends Node

const CreationScreen = preload("res://ui/character_creation_screen.gd")
var engine: SimulationEngine
var world: WorldState
var creation: Control
var shell: PlayableShell

func _ready() -> void:
	engine = SimulationEngine.new()
	world = S1WorldData.create_s1_world()
	creation = CreationScreen.new()
	creation.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(creation)
	creation.setup(world, engine)
	creation.journey_requested.connect(_enter_wasteland)

func _enter_wasteland() -> void:
	if not creation.committed or world.player == null or shell != null:
		return
	shell = PlayableShell.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shell)
	shell.setup(world, engine)
	creation.hide()
