class_name NinaEditor
extends Control


@export var editor_viewport: SubViewport
@export var editor_viewport_container: NinaEditorViewportContainer


@onready var _level: NinaLevel = NinaUtils.get_level_of(self)
@onready var _level_viewport: SubViewport = _level.get_level_viewport()
var _editor_level_camera: Camera2D


func _ready() -> void:
	_editor_level_camera = Camera2D.new()
	_level_viewport.add_child(_editor_level_camera)
	editor_viewport_container.editor_level_camera = _editor_level_camera
