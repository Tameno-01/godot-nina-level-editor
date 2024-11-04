class_name NinaEditorViewportContainer
extends SubViewportContainer

const ZOOM_MULTIPLIER: float = 1.1

@export var editor: NinaEditor

var editor_level_camera: Camera2D
var level_viewport: SubViewport
# this dictionary contains all removed nodes as keys and their parents as values
var orphan_nodes: Dictionary = {}
var undo_redo_manager: NinaEditorUndoRedoManager

var _mouse_on_self: bool
var _dragging_node_2d: Node2D
var _drag_offset: Vector2
var _drag_creation_path: String


func _ready():
	await get_tree().process_frame
	undo_redo_manager = editor.undo_redo_manager
	undo_redo_manager.undo.connect(_on_undo)
	undo_redo_manager.redo.connect(_on_redo)


func _input(event: InputEvent) -> void:
	if _mouse_on_self:
		if event is InputEventMouseMotion:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
				editor_level_camera.position -= event.relative / editor_level_camera.zoom
			if _dragging_node_2d:
				_update_2d_drag()
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				editor_level_camera.zoom *= ZOOM_MULTIPLIER
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				editor_level_camera.zoom /= ZOOM_MULTIPLIER
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					pass
				else:
					if _dragging_node_2d:
						_stop_2d_drag()


func _on_mouse_entered() -> void:
	_mouse_on_self = true
	if editor.drag_preview:
		var file: NinaEditorFileDisplay = editor.drag_preview.file_display
		match file.type:
			NinaEditorFileDisplay.types.SCENE_2D:
				var new_scene: PackedScene = load(file.path)
				var new_node: Node2D = new_scene.instantiate()
				new_node.position = _get_level_mouse_pos()
				level_viewport.add_child(new_node)
				_start_2d_drag(new_node, file.path)
			# TODO support 3d scenes, assets and images
		editor.stop_file_drag()


func _on_mouse_exited() -> void:
	_mouse_on_self = false
	if _dragging_node_2d:
		_stop_2d_drag()


func _on_undo(action: Dictionary):
	match action.type:
		"create":
			_remove_node(action.node)


func _on_redo(action: Dictionary):
	match action.type:
		"create":
			_add_previously_removed_node(action.node)


func _remove_node(node: Node) -> void:
	var parent: Node = node.get_parent()
	parent.remove_child(node)
	orphan_nodes[node] = parent


func _add_previously_removed_node(node: Node) -> void:
	orphan_nodes[node].add_child(node)
	orphan_nodes.erase(node)


func _get_level_mouse_pos() -> Vector2:
	return level_viewport.canvas_transform.affine_inverse() * get_local_mouse_position()


func _start_2d_drag(node: Node2D, creation_path: String = "") -> void:
	_dragging_node_2d = node
	if creation_path:
		_drag_offset = Vector2.ZERO
		_drag_creation_path = creation_path
	else:
		_drag_offset = _dragging_node_2d.position - _get_level_mouse_pos()
		_drag_creation_path = ""


func _update_2d_drag() -> void:
	_dragging_node_2d.position = _get_level_mouse_pos() + _drag_offset


func _stop_2d_drag() -> void:
	if _drag_creation_path:
		undo_redo_manager.do_action({
			"type": "create",
			"node": _dragging_node_2d,
		})
	_dragging_node_2d = null
