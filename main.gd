extends Node

# ==============================================================================
# WASTELAND CHRONICLES - PLAYABLE DESKTOP ENTRY POINT
# ==============================================================================
# Launches the interactive Survivor PDA UI Shell directly in a Godot window
# for hands-on First Playable playtesting.
# ==============================================================================

func _ready() -> void:
	var engine := SimulationEngine.new()
	var world := S1WorldData.create_s1_world()

	# Start player at Gray Valley with standard gear
	engine.materialize_player(world, &"settlement:gray_valley", "Drifter", 26)

	var shell := PlayableShell.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shell)
	shell.setup(world, engine)
