class_name NinaUi
extends Control


@export var editor_viewport: SubViewport
@export var editor_viewport_container: NinaEditorViewportContainer


var _level_viewport: SubViewport
var _editor_level_camera: Camera2D


func _ready() -> void:
	_level_viewport = get_parent().get_level_viewport()
	_editor_level_camera = Camera2D.new()
	_level_viewport.add_child(_editor_level_camera)
	editor_viewport_container.editor_level_camera = _editor_level_camera
