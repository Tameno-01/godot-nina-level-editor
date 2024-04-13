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
		"res://addons/nina_level_editor/editor/editor.tscn"
)
var _cam_and_viewport_scene: PackedScene = preload(
		"res://addons/nina_level_editor/cam_and_viewport/cam_and_viewport.tscn"
)
var _nodes_for_current_mode: Array = []
var _level_viewport: SubViewport


func swicth_mode() -> void:
	match current_mode:
		modes.PLAY:
			_switch_to_edit_mode()
		modes.EDIT:
			_switch_to_play_mode()


func get_level_viewport() -> SubViewport:
	return _level_viewport


func _ready() -> void:
	_setup_play_mode()


func _unhandled_input(event):
	if swicth_modes_action == "":
		return
	if event.is_action_pressed(swicth_modes_action):
		swicth_mode()


func _add_node_for_current_mode(node: Node, parent: Node) -> void:
	parent.add_child(node)
	_nodes_for_current_mode.append(node)


func _setup_cam_and_viewport(parent: Node) -> void:
	var cam_and_viewport: NinaCamAndViewportHolder = _cam_and_viewport_scene.instantiate()
	cam_and_viewport.viewport_scale = viewport_scale
	_level_viewport = cam_and_viewport.level_viewport
	_add_node_for_current_mode(cam_and_viewport, parent)


func _switch_to_edit_mode() -> void:
	if current_mode == modes.EDIT:
		return
	_delete_nodes_for_current_mode()
	_setup_edit_mode()
	current_mode = modes.EDIT


func _setup_edit_mode() -> void:
	var ui: NinaEditor = _ui_scene.instantiate()
	_setup_cam_and_viewport(ui.editor_viewport)
	_add_node_for_current_mode(ui, self)


func _switch_to_play_mode() -> void:
	if current_mode == modes.PLAY:
		return
	_delete_nodes_for_current_mode()
	_setup_play_mode()
	current_mode = modes.PLAY


func _setup_play_mode():
	_setup_cam_and_viewport(self)


func _delete_nodes_for_current_mode() -> void:
	for node in _nodes_for_current_mode:
		node.queue_free()
	_nodes_for_current_mode.clear()
