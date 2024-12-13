class_name NinaLevel
extends Node

enum Modes {
	PLAY,
	EDIT,
}

const _EDITOR_SCENE: PackedScene = preload(
		"res://addons/nina_level_editor/editor/editor.tscn"
)
const _CAM_AND_VIEWPORT_SCENE: PackedScene = preload(
		"res://addons/nina_level_editor/cam_and_viewport/cam_and_viewport.tscn"
)

var _current_mode: Modes = Modes.PLAY
var _editor: NinaEditor = null
var _nodes_for_current_mode: Array[Node] = []
var _level_viewport: SubViewport

@export var viewport_scale: float = 0.01
@export var swicth_modes_action: String = ""


func swicth_mode() -> void:
	match _current_mode:
		Modes.PLAY:
			_switch_to_edit_mode()
		Modes.EDIT:
			_switch_to_play_mode()


func get_current_mode() -> Modes:
	return _current_mode


func get_level_viewport() -> SubViewport:
	return _level_viewport


func _ready() -> void:
	_setup_play_mode()


func _unhandled_input(event):
	if swicth_modes_action.is_empty():
		return
	if event.is_action_pressed(swicth_modes_action):
		swicth_mode()


func _add_node_for_current_mode(node: Node, parent: Node) -> void:
	parent.add_child(node)
	_nodes_for_current_mode.append(node)


func _setup_cam_and_viewport(parent: Node, delete_on_mode_switch: bool = true) -> void:
	var cam_and_viewport: NinaCamAndViewportHolder = _CAM_AND_VIEWPORT_SCENE.instantiate()
	cam_and_viewport.viewport_scale = viewport_scale
	_level_viewport = cam_and_viewport.level_viewport
	if delete_on_mode_switch:
		_add_node_for_current_mode(cam_and_viewport, parent)
	else:
		parent.add_child(cam_and_viewport)


func _switch_to_edit_mode() -> void:
	if _current_mode == Modes.EDIT:
		return
	_delete_nodes_for_current_mode()
	_setup_edit_mode()
	_current_mode = Modes.EDIT


func _setup_edit_mode() -> void:
	if _editor == null:
		_editor = _EDITOR_SCENE.instantiate()
		_setup_cam_and_viewport(_editor.level_viewport, false)
	add_child(_editor)


func _switch_to_play_mode() -> void:
	if _current_mode == Modes.PLAY:
		return
	_delete_nodes_for_current_mode()
	if _editor != null:
		remove_child(_editor)
	_setup_play_mode()
	_current_mode = Modes.PLAY


func _setup_play_mode():
	_setup_cam_and_viewport(self)


func _delete_nodes_for_current_mode() -> void:
	for node in _nodes_for_current_mode:
		node.queue_free()
	_nodes_for_current_mode.clear()


func _exit_tree() -> void:
	if _editor != null:
		_editor.free()
