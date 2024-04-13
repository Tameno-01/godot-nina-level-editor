class_name NinaEditorFileDisplay
extends Control


enum types {
	FOLDER,
	SCENE,
	IMAGE,
	ASSET,
}


signal pressed(file_display)
signal fully_pressed(file_display: NinaEditorFileDisplay)


@export var folder_icon: Texture
@export var scene_icon: Texture
@export var icon_display: TextureRect
@export var name_display: Label


var path: String


var type: types


func set_folder(new_path: String) -> void:
	path = new_path
	_set_type(types.FOLDER)
	name_display.text = path.get_slice("/", path.get_slice_count("/") - 1)


func set_file(new_path: String) -> void:
	path = new_path
	var file_extension: String = path.get_extension()
	if file_extension == "tscn":
		_set_type(types.SCENE)
	else:
		_set_type(types.IMAGE)
		icon_display.texture = load(path)
	name_display.text = path.get_file()


func _on_button_down():
	pressed.emit(self)


func _on_button_pressed():
	fully_pressed.emit(self)


func _set_type(value: types) -> void:
	type = value
	match type:
		types.FOLDER:
			icon_display.texture = folder_icon
		types.SCENE:
			icon_display.texture = scene_icon
