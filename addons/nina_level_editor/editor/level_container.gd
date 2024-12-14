class_name NinaLevelContainer
extends SubViewportContainer

signal canvas_transform_updated(new_canvas_transform: Transform2D)

const ZOOM_MULTIPLIER: float = 1.1
const HOVER_PRIORITY_FUCTION_NAME: StringName = &"_get_hover_priority"
const HOVER_ENTER_FUNCTION_NAME: StringName = &"_on_hover_enter"
const HOVER_LEAVE_FUNCTION_NAME: StringName = &"_on_hover_leave"
const CLICK_FUNCTION_NAME: StringName = &"_on_click"
const DRAG_FUNCTION_NAME: StringName = &"_drag"
const DRAG_END_FUNCTION_NAME: StringName = &"_on_drag_end"

@export var editor: NinaEditor
@export var gizmo_layer: CanvasLayer
@export var selection_dot_2d_scene: PackedScene
@export var transform_gizmo_2d_scene: PackedScene

var editor_level_camera: Camera2D
var level_viewport: SubViewport
# key: removed Node
# value: Node paret of remoned node
var orphan_nodes: Dictionary = {}
var undo_redo_manager: NinaUndoRedoManager
var selected_nodes: Array[Node2D] = []

var _mouse_on_self: bool
var _creation_drag_node_2d: Node2D
var _drag_creation_path: String
var _canvas_transform_update_queued: bool = false
var _mouse_position_update_queued: bool = false
var _queded_is_mouse_on_viewport: bool
var _clickable_nodes: Array[Node] = []
var _hovering_node: Node = null
# key: Node
# value: NinaSelctionDot2D that is assigned to that node
var _selection_dots_2d: Dictionary = {}
var _current_transform_gizmo_2d: NinaTransformGizmo2D = null
var _dragging_node: Node = null


func _ready() -> void:
	await get_tree().process_frame
	undo_redo_manager = editor.undo_redo_manager
	undo_redo_manager.undo.connect(_on_undo)
	undo_redo_manager.redo.connect(_on_redo)
	_canvas_transform_update()


func _input(event: InputEvent) -> void:
	if _mouse_on_self:
		if event is InputEventMouseMotion:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
				editor_level_camera.position -= event.relative / editor_level_camera.zoom
				_canvas_transform_update()
			if _creation_drag_node_2d != null:
				_update_creation_drag_2d()
			if _dragging_node:
				_update_drag(event.relative)
			_mouse_position_update(true)
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				editor_level_camera.zoom *= ZOOM_MULTIPLIER
				_canvas_transform_update()
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				editor_level_camera.zoom /= ZOOM_MULTIPLIER
				_canvas_transform_update()
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					if _hovering_node == null:
						deselect_all_nodes()
					else:
						if _hovering_node.has_method(CLICK_FUNCTION_NAME):
							_hovering_node.call(CLICK_FUNCTION_NAME)
						else:
							deselect_all_nodes()
				else: # Not pressed.
					if _creation_drag_node_2d != null:
						_stop_creation_drag_2d()
					if _dragging_node != null:
						_stop_drag()


func add_clickable_node(node: Node) -> void:
	_clickable_nodes.append(node)
	_update_hovering_node()


func remove_clickable_node(node: Node) -> void:
	_clickable_nodes.erase(node)
	_update_hovering_node()


func select_node(node: Node2D) -> void:
	if selected_nodes.has(node):
		push_error("Trying to select ", node, ", but it is alredy selected")
		return
	selected_nodes.append(node)
	_selection_dots_2d[node].node_selected()
	if _current_transform_gizmo_2d == null:
		_create_transform_gizmo_2d()
	_current_transform_gizmo_2d.update_nodes_array()


func deselect_node(node: Node2D) -> void:
	if not selected_nodes.has(node):
		push_error("Trying to deselect ", node, ", but it is not selected")
		return
	selected_nodes.erase(node)
	_selection_dots_2d[node].node_deselected()
	if selected_nodes.is_empty():
		_remove_transform_gizmo_2d()
	else:
		_current_transform_gizmo_2d.update_nodes_array()


func deselect_all_nodes() -> void:
	if selected_nodes.is_empty():
		return
	for node: Node2D in selected_nodes:
		_selection_dots_2d[node].node_deselected()
	selected_nodes = []
	_current_transform_gizmo_2d.queue_free()
	_current_transform_gizmo_2d = null


func get_level_canvas_transform() -> Transform2D:
	return level_viewport.canvas_transform


func get_level_mouse_position() -> Vector2:
	return get_level_canvas_transform().affine_inverse() * get_local_mouse_position()


func start_drag(node: Node) -> void:
	_dragging_node = node


func _update_drag(movement: Vector2):
	if _dragging_node.has_method(DRAG_FUNCTION_NAME):
		_dragging_node.call(DRAG_FUNCTION_NAME, movement)


func _stop_drag() -> void:
	if _dragging_node.has_method(DRAG_END_FUNCTION_NAME):
		_dragging_node.call(DRAG_END_FUNCTION_NAME)
	_dragging_node = null


func _update_hovering_node() -> void:
	if _dragging_node != null or _creation_drag_node_2d != null:
		if _hovering_node != null:
			_unhover_current_hovering_node()
	var new_hovering_node = _get_hovering_node()
	if new_hovering_node == _hovering_node:
		return
	_unhover_current_hovering_node()
	if new_hovering_node:
		if new_hovering_node.has_method(HOVER_ENTER_FUNCTION_NAME):
			new_hovering_node.call(HOVER_ENTER_FUNCTION_NAME)
	_hovering_node = new_hovering_node


func _get_hovering_node() -> Node:
	if _clickable_nodes.is_empty():
		return null
	var max_priority: float = 0.0
	var max_priority_node: Node = null
	for node: Node in _clickable_nodes:
		var node_priority: float = node.call(
			HOVER_PRIORITY_FUCTION_NAME,
			get_level_mouse_position()
		)
		if node_priority > max_priority:
			max_priority_node = node
			max_priority = node_priority
	return max_priority_node


func _unhover_current_hovering_node():
	if _hovering_node != null:
		if _hovering_node.has_method(HOVER_LEAVE_FUNCTION_NAME):
			_hovering_node.call(HOVER_LEAVE_FUNCTION_NAME)
		_hovering_node = null


func _on_mouse_entered() -> void:
	_mouse_on_self = true
	if editor.drag_preview != null:
		var file: NinaFileDisplay = editor.drag_preview.file_display
		match file.type:
			NinaFileDisplay.types.SCENE_2D:
				var new_scene: PackedScene = load(file.path)
				var new_node: Node2D = new_scene.instantiate()
				new_node.position = get_level_mouse_position()
				level_viewport.add_child(new_node)
				_start_creation_drag_2d(new_node, file.path)
			# TODO support 3d scenes, assets and images
		editor.stop_file_drag()


func _on_mouse_exited() -> void:
	_mouse_on_self = false
	if _creation_drag_node_2d != null:
		_stop_creation_drag_2d()
	_mouse_position_update(false)


func _on_undo(action: Dictionary):
	match action.type:
		"create":
			_remove_node(action.node)
		"transform":
			for node_transformation: Dictionary in action.nodes:
				node_transformation.node.transform = node_transformation.from
				_update_node_transform(node_transformation.node)


func _on_redo(action: Dictionary):
	match action.type:
		"create":
			_add_previously_removed_node(action.node)
		"transform":
			for node_transformation: Dictionary in action.nodes:
				node_transformation.node.transform = node_transformation.to
				_update_node_transform(node_transformation.node)


func _remove_node(node: Node) -> void:
	if selected_nodes.has(node):
		deselect_node(node)
	var parent: Node = node.get_parent()
	parent.remove_child(node)
	orphan_nodes[node] = parent
	if _selection_dots_2d.has(node):
		var selection_dot: NinaSelectionDot2D = _selection_dots_2d[node]
		_selection_dots_2d.erase(node)
		selection_dot.queue_free()


func _add_previously_removed_node(node: Node) -> void:
	orphan_nodes[node].add_child(node)
	orphan_nodes.erase(node)
	_create_selection_dot_2d(node)


func _start_creation_drag_2d(node: Node2D, creation_path: String) -> void:
	_creation_drag_node_2d = node
	_drag_creation_path = creation_path


func _update_creation_drag_2d() -> void:
	_creation_drag_node_2d.position = get_level_mouse_position()


func _stop_creation_drag_2d() -> void:
	if not _drag_creation_path.is_empty():
		undo_redo_manager.do_action({
			"type": "create",
			"node": _creation_drag_node_2d,
		})
	_create_selection_dot_2d(_creation_drag_node_2d)
	_creation_drag_node_2d = null


func _create_selection_dot_2d(node: Node2D) -> void:
	var new_selection_dot_2d: NinaSelectionDot2D = selection_dot_2d_scene.instantiate()
	gizmo_layer.add_child(new_selection_dot_2d)
	new_selection_dot_2d.set_node(node)
	_selection_dots_2d[node] = new_selection_dot_2d


func _create_transform_gizmo_2d() -> void:
	if _current_transform_gizmo_2d != null:
		push_error("Trying to create transform gizmo, but one alredy exists.")
		return
	var new_tranfrom_gizmo_2d: NinaTransformGizmo2D = transform_gizmo_2d_scene.instantiate()
	gizmo_layer.add_child(new_tranfrom_gizmo_2d)
	gizmo_layer.move_child(new_tranfrom_gizmo_2d, 0)
	_current_transform_gizmo_2d = new_tranfrom_gizmo_2d


func _remove_transform_gizmo_2d():
	if _current_transform_gizmo_2d == null:
		push_error("Trying to remove transform gizmo, but none exists.")
		return
	_current_transform_gizmo_2d.queue_free()
	_current_transform_gizmo_2d = null


func _canvas_transform_update() -> void:
	if _canvas_transform_update_queued:
		return
	_canvas_transform_update_queued = true
	await get_tree().process_frame
	gizmo_layer.transform = get_level_canvas_transform()
	canvas_transform_updated.emit(get_level_canvas_transform())
	_instant_mouse_position_update(false)
	_canvas_transform_update_queued = false


func _mouse_position_update(on_viewport: bool) -> void:
	_queded_is_mouse_on_viewport = on_viewport
	if _mouse_position_update_queued:
		return
	_mouse_position_update_queued = true
	await get_tree().process_frame
	_instant_mouse_position_update(_queded_is_mouse_on_viewport)
	_mouse_position_update_queued = false


func _instant_mouse_position_update(on_viewport: bool) -> void:
	if not on_viewport:
		_unhover_current_hovering_node()
		return
	_update_hovering_node()


func _on_sub_viewport_size_changed() -> void:
	# Awaiting here makes things work better for some reason
	await get_tree().process_frame
	_canvas_transform_update()


func _update_node_transform(node: Node2D) -> void:
	if selected_nodes.has(node):
		if _current_transform_gizmo_2d:
			_current_transform_gizmo_2d.update_nodes_array()
	if _selection_dots_2d.has(node):
		_selection_dots_2d[node].node_updated()
