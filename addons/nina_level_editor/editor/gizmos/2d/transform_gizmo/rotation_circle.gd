extends Sprite2D

const HOVER_LENIENCE: float = 0.2
const COLOR: Color = NinaEditor.COLOR_ROTATION

@onready var _editor: NinaEditor = NinaUtils.get_editor_of(self)
@onready var _level_container: NinaLevelContainer = _editor.level_container


func _ready() -> void:
	_level_container.add_clickable_node(self)
	modulate = COLOR


func _get_hover_priority(new_position: Vector2) -> float:
	var texture_relative_pos: Vector2 = to_local(new_position) / texture.get_size() * 2.0
	var distance_to_center: float = texture_relative_pos.length()
	var distance: float = absf(distance_to_center - 1.0)
	return 1.0 - distance / HOVER_LENIENCE


func _on_hover_enter() -> void:
	modulate = lerp(
			COLOR,
			NinaTransformGizmo2D.HOVER_COLOR,
			NinaTransformGizmo2D.HOVER_COLOR_INTESITY,
	)


func _on_hover_leave() -> void:
	modulate = COLOR


func _on_click() -> void:
	get_parent().component_clicked(NinaTransformGizmo2D.ComponentTypes.ROTATION)


func _exit_tree() -> void:
	_level_container.remove_clickable_node(self)
