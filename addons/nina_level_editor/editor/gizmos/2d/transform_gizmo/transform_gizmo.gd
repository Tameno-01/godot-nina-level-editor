class_name NinaTransformGizmo2D
extends Node2D

const SCALING_SPEED: float = 0.05

enum ComponentTypes {
	X_MOVE,
	Y_MOVE,
	X_SCALE,
	Y_SCALE,
	UNIFORM_SCALE,
	XY_MOVE,
	ROTATION,
}

const HOVER_COLOR: Color = Color(1.0, 1.0, 1.0)
const HOVER_COLOR_INTESITY: float = 0.8

var _canvas_transform: Transform2D
# This variable can start as anything but ComponentTypes.ROTATION
var _current_drag_type: ComponentTypes = ComponentTypes.X_MOVE
var _node_starting_transforms: Array[Transform2D]
var _node_starting_relative_positions: Array[Vector2]
var _current_scale: float
var _has_dragged: bool
var _rotation_mouse_pos: Vector2
var _rotation_starting_angle: float
var _scale_gizmo_rotation: float
var _scale_gizmo_arrow_transforms: Array[Transform2D] = []

@export var scale_gizmo_arrows: Array[NinaTransformGizmoArrow2D]

@onready var _editor: NinaEditor = NinaUtils.get_editor_of(self)
@onready var _level_container: NinaLevelContainer = _editor.level_container
@onready var _id_manager: NinaIdManager = _level_container.id_manager


func _ready() -> void:
	_level_container.canvas_transform_updated.connect(_on_canvas_transform_updated)
	_canvas_transform = _level_container.get_level_canvas_transform()
	for scale_gizmo_arrow: NinaTransformGizmoArrow2D in scale_gizmo_arrows:
		_scale_gizmo_arrow_transforms.append(scale_gizmo_arrow.transform)
	_update_size()


func component_clicked(type: ComponentTypes) -> void:
	# Some of the members set here may go unused, but i don't see a reason to
	# put if statements
	_current_drag_type = type
	_node_starting_transforms = []
	_node_starting_relative_positions = []
	for node: Node2D in _get_nodes_array():
		_node_starting_transforms.append(node.transform)
		_node_starting_relative_positions.append(node.position - position)
	_current_scale = 1.0
	_rotation_mouse_pos = to_local(_level_container.get_level_mouse_position())
	_rotation_starting_angle = _rotation_mouse_pos.angle()
	_has_dragged = false
	queue_redraw()
	_level_container.start_drag(self)


func update_nodes_array() -> void:
	if not is_node_ready():
		await ready
	if _get_nodes_array().is_empty():
		return
	var avg_position: Vector2 = Vector2.ZERO
	var avg_rotation: float = 0.0
	for node: Node2D in _get_nodes_array():
		avg_position += node.position
		avg_rotation += fposmod(
				node.rotation + TAU / 8.0,
				TAU / 4.0,
		) - TAU / 8.0
	avg_position /= _get_nodes_array().size()
	avg_rotation /= _get_nodes_array().size()
	position = avg_position
	_scale_gizmo_rotation = avg_rotation
	_update_scale_gizmo_rotation()


func _drag(movement: Vector2):
	_has_dragged = true
	var level_space_movement =  movement * _get_size()
	match _current_drag_type:
		ComponentTypes.X_MOVE:
			position.x += level_space_movement.x
			for node: Node2D in _get_nodes_array():
				node.position.x += level_space_movement.x
		ComponentTypes.Y_MOVE:
			position.y += level_space_movement.y
			for node: Node2D in _get_nodes_array():
				node.position.y += level_space_movement.y
		ComponentTypes.X_SCALE:
			var arrow_angle: float = _scale_gizmo_rotation + TAU / 2
			var arrow_dir: Vector2 = Vector2.from_angle(arrow_angle)
			_current_scale += _project_to_line(movement, arrow_dir) * SCALING_SPEED
			for i in _get_nodes_array().size():
				var node: Node2D = _get_nodes_array()[i]
				node.position = (
						position
						+ _node_starting_relative_positions[i].project(arrow_dir) * _current_scale
						+ _node_starting_relative_positions[i].project(arrow_dir.rotated(TAU / 4.0))
				)
				var angle_diff = abs(angle_difference(node.rotation, arrow_angle))
				if TAU / 8 < angle_diff and angle_diff < TAU / 8 * 3:
					node.scale.y = _node_starting_transforms[i].get_scale().y * _current_scale
				else:
					node.scale.x = _node_starting_transforms[i].get_scale().x * _current_scale
		ComponentTypes.Y_SCALE:
			var arrow_angle: float = _scale_gizmo_rotation + TAU / 4
			var arrow_dir: Vector2 = Vector2.from_angle(arrow_angle)
			_current_scale += _project_to_line(movement, arrow_dir) * SCALING_SPEED
			for i in _get_nodes_array().size():
				var node: Node2D = _get_nodes_array()[i]
				node.position = (
						position
						+ _node_starting_relative_positions[i].project(arrow_dir) * _current_scale
						+ _node_starting_relative_positions[i].project(arrow_dir.rotated(TAU / 4.0))
				)
				var angle_diff = abs(angle_difference(node.rotation, arrow_angle))
				if TAU / 8 < angle_diff and angle_diff < TAU / 8 * 3:
					node.scale.y = _node_starting_transforms[i].get_scale().y * _current_scale
				else:
					node.scale.x = _node_starting_transforms[i].get_scale().x * _current_scale
		ComponentTypes.UNIFORM_SCALE:
			var arrow_angle: float = _scale_gizmo_rotation + TAU / 8 * 3
			var arrow_dir: Vector2 = Vector2.from_angle(arrow_angle)
			_current_scale += _project_to_line(movement, arrow_dir) * SCALING_SPEED
			for i in _get_nodes_array().size():
				var node: Node2D = _get_nodes_array()[i]
				node.position = position + _node_starting_relative_positions[i] * _current_scale
				node.scale = _node_starting_transforms[i].get_scale() * _current_scale
		ComponentTypes.XY_MOVE:
			position += level_space_movement
			for node: Node2D in _get_nodes_array():
				node.position += level_space_movement
		ComponentTypes.ROTATION:
			_rotation_mouse_pos += movement
			var current_rotation: float = _rotation_mouse_pos.angle() - _rotation_starting_angle
			for i in _get_nodes_array().size():
				var node: Node2D = _get_nodes_array()[i]
				var node_relative_position: Vector2 = _node_starting_relative_positions[i]
				node_relative_position = node_relative_position.rotated(current_rotation)
				node.position = position + node_relative_position
				node.rotation = _node_starting_transforms[i].get_rotation() + current_rotation
			queue_redraw()


func _on_drag_end() -> void:
	if _current_drag_type == ComponentTypes.ROTATION:
		_current_drag_type = ComponentTypes.X_MOVE
		queue_redraw()
	if not _has_dragged:
		return
	var node_ending_transforms: Array[Transform2D] = []
	for node: Node2D in _get_nodes_array():
		node_ending_transforms.append(node.transform)
	var node_transforms: Array[Dictionary] = []
	for i: int in range(_get_nodes_array().size()):
		node_transforms.append({
			&"id": _id_manager.get_id_from_node(_get_nodes_array()[i]),
			&"from": _node_starting_transforms[i],
			&"to": node_ending_transforms[i],
		})
		_level_container._update_node_transform(_get_nodes_array()[i])
	_editor.undo_redo_manager.do_action({
		&"type": &"transform_2d",
		&"nodes": node_transforms,
	})


func _draw() -> void:
	if _current_drag_type != ComponentTypes.ROTATION:
		return
	draw_line(Vector2.ZERO, _rotation_mouse_pos, NinaEditor.COLOR_ROTATION, 1.0, true)
	draw_circle(_rotation_mouse_pos, 2.0, NinaEditor.COLOR_ROTATION, true, -1.0, true)


func _update_scale_gizmo_rotation() -> void:
	for i: int in range(scale_gizmo_arrows.size()):
		scale_gizmo_arrows[i].transform = _scale_gizmo_arrow_transforms[i].rotated(
				_scale_gizmo_rotation
		)


func _on_canvas_transform_updated(new_canvas_transform: Transform2D) -> void:
	_canvas_transform = new_canvas_transform
	_update_size()


func _get_size() -> float:
	return 1.0 / _get_canvas_scale()


func _update_size() -> void:
	scale = Vector2(_get_size(), _get_size())


func _get_canvas_scale() -> float:
	return _canvas_transform.x.length()


func _get_nodes_array() -> Array[Node2D]:
	return _level_container.selected_nodes


func _project_to_line(vec: Vector2, line_direction: Vector2) -> float:
	return cos(vec.angle_to(line_direction))
