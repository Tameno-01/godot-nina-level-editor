class_name NinaLevel
extends Node


enum modes {
	PLAY,
	EDIT,
}


@export var viewport_scale: float = 0.01
@export var swicth_modes_action: String = ""


var current_mode: modes = modes.PLAY


var _ui_scene: PackedScene = preload(
		"res://addons/nina_level_editor/ui/ui.tscn"
)
var _play_cam_and_viewport_scene: PackedScene = preload(
		"res://addons/nina_level_editor/cam_and_viewport/cam_and_viewport.tscn"
)
var _nodes_for_current_mode: Array = []


func swicth_mode() -> void:
	match current_mode:
		modes.PLAY:
			_switch_to_edit_mode()
		modes.EDIT:
			_switch_to_play_mode()


func _ready() -> void:
	_setup_play_mode()


func _switch_to_edit_mode() -> void:
	if current_mode == modes.EDIT:
		return
	_delete_nodes_for_current_mode()
	var ui_node = _ui_scene.instantiate()
	add_child(ui_node)
	_nodes_for_current_mode.append(ui_node)
	current_mode = modes.EDIT


func _switch_to_play_mode() -> void:
	if current_mode == modes.PLAY:
		return
	_delete_nodes_for_current_mode()
	_setup_play_mode()
	current_mode = modes.PLAY


func _setup_play_mode():
	var play_cam_and_viewport_node = _play_cam_and_viewport_scene.instantiate()
	play_cam_and_viewport_node.viewport_scale = viewport_scale
	add_child(play_cam_and_viewport_node)
	_nodes_for_current_mode.append(play_cam_and_viewport_node)


func _delete_nodes_for_current_mode() -> void:
	for node in _nodes_for_current_mode:
		node.queue_free()
	_nodes_for_current_mode.clear()


func _unhandled_input(event):
	if swicth_modes_action == "":
		return
	if event.is_action_pressed(swicth_modes_action):
		swicth_mode()
