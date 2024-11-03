class_name NinaEditorDragPreview
extends Control


@export var texture_rect: TextureRect


var file_display: NinaEditorFileDisplay


func _ready():
	texture_rect.texture = file_display.get_icon()
