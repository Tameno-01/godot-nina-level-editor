class_name NinaEditorFileDisplay
extends Control


enum types {
	FOLDER,
	SCENE_2D,
	SCENE_3D,
	IMAGE,
	ASSET,
}


const SCENE_FILE_EXTENSIONS: Array[String] = [
	"tscn",
	"scn",
]


signal pressed(file_display)
signal fully_pressed(file_display: NinaEditorFileDisplay)


@export var folder_icon: Texture
@export var scene_2d_icon: Texture
@export var scene_3d_icon: Texture
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
	if SCENE_FILE_EXTENSIONS.has(file_extension):
		var scene: PackedScene = load(path)
		var scene_type: StringName = scene.get_state().get_node_type(0)
		if ClassDB.is_parent_class(scene_type, &"Node2D"):
			_set_type(types.SCENE_2D)
		elif ClassDB.is_parent_class(scene_type, &"Node3D"):
			_set_type(types.SCENE_3D)
		else:
			queue_free()
	else:
		_set_type(types.IMAGE)
		icon_display.texture = load(path)
	name_display.text = path.get_file()


func get_icon() -> Texture:
	return icon_display.texture


func _on_button_down() -> void:
	pressed.emit(self)


func _on_button_pressed() -> void:
	fully_pressed.emit(self)


func _set_type(value: types) -> void:
	type = value
	match type:
		types.FOLDER:
			icon_display.texture = folder_icon
		types.SCENE_2D:
			icon_display.texture = scene_2d_icon
		types.SCENE_3D:
			icon_display.texture = scene_3d_icon
