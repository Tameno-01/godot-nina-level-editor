class_name NinaSelectionDot2D
extends Sprite2D

const HOVER_OFF_SIZE: float = 0.1
const HOVER_ON_SIZE: float = 0.3
const HOVER_DISTANCE: float = 30.0

var _node: Node2D
var _canvas_transform: Transform2D
var _size: float = HOVER_OFF_SIZE

@onready var _editor: NinaEditor = NinaUtils.get_editor_of(self)
@onready var _level_container: NinaLevelContainer = _editor.level_container


func _ready() -> void:
	_level_container.canvas_transform_updated.connect(_on_canvas_transform_updated)
	_level_container.add_clickable_node(self)
	_canvas_transform = _level_container.get_level_canvas_transform()
	_update_size()


func set_node(new_node: Node2D) -> void:
	_node = new_node
	node_updated()


func node_updated() -> void:
	position = _node.position


func node_selected() -> void:
	modulate = NinaEditor.COLOR_SELECTION


func node_deselected() -> void:
	modulate = Color.WHITE


func _on_hover_enter() -> void:
	_size = HOVER_ON_SIZE
	_update_size()


func _on_hover_leave() -> void:
	_size = HOVER_OFF_SIZE
	_update_size()


func _on_click() -> void:
	if Input.is_key_pressed(NinaEditor.KEY_MULTI_SELECT):
		if _level_container.selected_nodes.has(_node):
			_level_container.deselect_node(_node)
		else:
			_level_container.select_node(_node)
	else:
		_level_container.deselect_all_nodes()
		_level_container.select_node(_node)


func _update_size() -> void:
	var actual_size: float = _size
	actual_size /= _get_canvas_scale()
	scale = Vector2(actual_size, actual_size)


func _on_canvas_transform_updated(new_canvas_transform: Transform2D) -> void:
	_canvas_transform = new_canvas_transform
	_update_size()


func _get_hover_priority(mouse_position: Vector2) -> float:
	if not visible:
		return 0.0
	var distance: float = (mouse_position - position).length() * _get_canvas_scale()
	return 1.0 - distance / HOVER_DISTANCE


func _get_canvas_scale() -> float:
	return _canvas_transform.x.length()


func _exit_tree() -> void:
	_level_container.remove_clickable_node(self)
