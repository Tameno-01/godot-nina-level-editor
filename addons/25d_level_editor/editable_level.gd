class_name EditableLevel
extends Node


enum modes {
	PLAY,
	EDIT,
}


@export var swicth_modes_action: String = ""


var current_mode: modes = modes.PLAY


var _ui_scene: PackedScene = preload("res://addons/25d_level_editor/ui/ui.tscn")
var _nodes_for_current_mode: Array = []


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
	pass


func swicth_mode() -> void:
	match current_mode:
		modes.PLAY:
			_switch_to_edit_mode()
		modes.EDIT:
			_switch_to_play_mode()


func _delete_nodes_for_current_mode() -> void:
	for node in _nodes_for_current_mode:
		node.queue_free()


func _unhandled_input(event: InputEvent):
	if event is InputEventAction:
		if event.action == swicth_modes_action:
			if event.pressed:
				swicth_mode()
