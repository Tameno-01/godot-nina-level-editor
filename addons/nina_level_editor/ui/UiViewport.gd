class_name NinaEditorViewportContainer
extends SubViewportContainer


const ZOOM_MULTIPLIER: float = 1.1


var editor_level_camera: Camera2D


var _mouse_on_self: bool


func _input(event: InputEvent) -> void:
	if _mouse_on_self:
		if event is InputEventMouseMotion:
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
				editor_level_camera.position -= event.relative / editor_level_camera.zoom
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				editor_level_camera.zoom *= ZOOM_MULTIPLIER
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				editor_level_camera.zoom /= ZOOM_MULTIPLIER


func _on_mouse_entered():
	_mouse_on_self = true


func _on_mouse_exited():
	_mouse_on_self = false
