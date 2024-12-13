class_name NinaDragPreview
extends Control

@export var texture_rect: TextureRect

var file_display: NinaFileDisplay


func _ready():
	texture_rect.texture = file_display.get_icon()
