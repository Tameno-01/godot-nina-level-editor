class_name NinaTransformGizmoArrow2D
extends Sprite2D

const HOVER_LENIENCE: float = 3.0

@export var gizmo_type: NinaTransformGizmo2D.ComponentTypes

var _color: Color

@onready var _editor: NinaEditor = NinaUtils.get_editor_of(self)
@onready var _level_container: NinaLevelContainer = _editor.level_container


func _ready() -> void:
	_level_container.add_clickable_node(self)
	_set_gizmo_type(gizmo_type)


func _get_hover_priority(new_position: Vector2) -> float:
	var texture_relative_pos: Vector2 = to_local(new_position) / texture.get_size() * 2.0
	if abs(texture_relative_pos.x) > 1.0:
		return 0.0
	var distance: float = abs(texture_relative_pos.y)
	return 1.0 - distance / HOVER_LENIENCE


func _on_hover_enter() -> void:
	modulate = lerp(
			_color,
			NinaTransformGizmo2D.HOVER_COLOR,
			NinaTransformGizmo2D.HOVER_COLOR_INTESITY,
	)


func _on_hover_leave() -> void:
	modulate = _color


func _on_click() -> void:
	get_parent().component_clicked(gizmo_type)


func _set_gizmo_type(value: NinaTransformGizmo2D.ComponentTypes) -> void:
	match value:
		NinaTransformGizmo2D.ComponentTypes.X_MOVE:
			_color = NinaEditor.COLOR_X
		NinaTransformGizmo2D.ComponentTypes.Y_MOVE:
			_color = NinaEditor.COLOR_Y
		NinaTransformGizmo2D.ComponentTypes.X_SCALE:
			_color = NinaEditor.COLOR_X
		NinaTransformGizmo2D.ComponentTypes.Y_SCALE:
			_color = NinaEditor.COLOR_Y
		NinaTransformGizmo2D.ComponentTypes.UNIFORM_SCALE:
			_color = NinaEditor.COLOR_XY
		_:
			push_error("Invalid transform gizmo component type for arrow.")
			return
	modulate = _color


func _exit_tree() -> void:
	_level_container.remove_clickable_node(self)
