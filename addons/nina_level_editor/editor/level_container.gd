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
var undo_redo_manager: NinaUndoRedoManager
var id_manager: NinaIdManager
var selected_nodes: Array[Node2D] = []

var _mouse_on_self: bool
var _creation_drag_node_2d: Node2D
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

@onready var _level = NinaUtils.get_level_of(self)
@onready var _chunk_manager: NinaChunkManager = _level.get_chunk_manager()


func _ready() -> void:
	await editor.ready
	editor.action_triggered.connect(_on_action_triggered)
	undo_redo_manager = editor.undo_redo_manager
	undo_redo_manager.undo.connect(_on_undo)
	undo_redo_manager.redo.connect(_on_redo)
	_chunk_manager.chunk_loaded.connect(_on_chunk_loaded)
	_canvas_transform_update()
	_load_id_manager()
	_chunk_manager.load_chunk(Vector2i.ZERO)


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


func re_open() -> void:
	_chunk_manager.load_chunk(Vector2i.ZERO)


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


func _on_chunk_loaded(chunk: NinaChunk) -> void:
	for child: Node in chunk.get_children():
		if child is Node2D:
			_create_selection_dot_2d(child)
	for path: NodePath in chunk.ids:
		id_manager.add_node(chunk.get_node(path), chunk.ids[path])


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
				_start_creation_drag_2d(file.path)
			# TODO support 3d scenes, assets and images
		editor.stop_file_drag()


func _on_mouse_exited() -> void:
	_mouse_on_self = false
	if _creation_drag_node_2d != null:
		_stop_creation_drag_2d()
	_mouse_position_update(false)


func _on_action_triggered(action: StringName) -> void:
	match action:
		&"delete":
			if selected_nodes.is_empty():
				return
			var deleted_nodes: Array[Dictionary] = []
			for node: Node in selected_nodes:
				var node_properties: Dictionary = {}
				if node is Node2D:
					node_properties[&"transform"] = node.transform
				deleted_nodes.append({
					&"id": id_manager.get_id_from_node(node),
					&"scene_path": node.scene_file_path,
					&"properties": node_properties,
				})
				_remove_node(node)
			undo_redo_manager.do_action({
				&"type": &"delete",
				&"nodes": deleted_nodes
			})


func _on_undo(action: Dictionary):
	match action.type:
		&"create":
			var node: Node = id_manager.get_node_from_id(action.id)
			_remove_node(node)
		&"delete":
			for node_dict in action.nodes:
				_create_node_from_dict(node_dict)
		&"transform_2d":
			for node_transformation: Dictionary in action.nodes:
				var node: Node2D = id_manager.get_node_from_id(node_transformation.id)
				node.transform = node_transformation.from
				_update_node_transform(node)


func _on_redo(action: Dictionary):
	match action.type:
		&"create":
			_create_node_from_dict(action.node)
		&"delete":
			for node_dict in action.nodes:
				var node: Node = id_manager.get_node_from_id(node_dict.id)
				_remove_node(node)
		&"transform_2d":
			for node_transformation: Dictionary in action.nodes:
				var node: Node2D = id_manager.get_node_from_id(node_transformation.id)
				node.transform = node_transformation.to
				_update_node_transform(node)


func _remove_node(node: Node) -> void:
	if selected_nodes.has(node):
		deselect_node(node)
	if _selection_dots_2d.has(node):
		var selection_dot: NinaSelectionDot2D = _selection_dots_2d[node]
		_selection_dots_2d.erase(node)
		selection_dot.queue_free()
	id_manager.remove_node(node)
	node.queue_free()


func _create_node_from_dict(dict: Dictionary) -> void:
	var new_node_scene: PackedScene = load(dict.scene_path)
	var new_node: Node = new_node_scene.instantiate()
	for property: String in dict.properties:
		new_node.set(property, dict.properties[property])
	var chunk: NinaChunk = _chunk_manager.get_loaded_chunk(Vector2i.ZERO)
	chunk.add_child(new_node)
	id_manager.add_node(new_node, dict.id)
	_create_selection_dot_2d(new_node)


func _start_creation_drag_2d(scene_path: String) -> void:
	var new_scene: PackedScene = load(scene_path)
	_creation_drag_node_2d = new_scene.instantiate()
	_creation_drag_node_2d.position = get_level_mouse_position()
	var chunk: NinaChunk = _chunk_manager.get_loaded_chunk(Vector2i.ZERO)
	chunk.add_child(_creation_drag_node_2d)
	_creation_drag_node_2d.owner = chunk


func _update_creation_drag_2d() -> void:
	_creation_drag_node_2d.position = get_level_mouse_position()


func _stop_creation_drag_2d() -> void:
	id_manager.add_completely_new_node(_creation_drag_node_2d)
	# TODO: add all propertties that have changed to undo-redo action
	# TODO: add info to undo-redo action needed for knowing which parent to add
	# the node as a child of
	undo_redo_manager.do_action({
		&"type": &"create",
		&"node": {
			&"id": id_manager.get_id_from_node(_creation_drag_node_2d),
			&"scene_path": _creation_drag_node_2d.scene_file_path,
			&"properties": {
				&"transform": _creation_drag_node_2d.transform
			}
		}
	})
	_create_selection_dot_2d(_creation_drag_node_2d)
	_chunk_manager.save_chunk(Vector2i.ZERO, id_manager)
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


func _load_id_manager():
	id_manager = ResourceLoader.load(
			_level.level_folder + "/" + NinaLevel.ID_MANAGER_PATH,
			"",
			ResourceLoader.CACHE_MODE_IGNORE,
	)


func _save_id_manager():
	ResourceSaver.save(id_manager, _level.level_folder + "/" + NinaLevel.ID_MANAGER_PATH)


func _save_everything():
	_chunk_manager.save_chunk(Vector2i.ZERO, id_manager)
	_save_id_manager()


func _exit_tree() -> void:
	deselect_all_nodes()
	for child: Node in gizmo_layer.get_children():
		child.queue_free()
	_save_everything()
	_chunk_manager.unload_chunk(Vector2i.ZERO)
