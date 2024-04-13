class_name NinaEditorFileManager
extends PanelContainer


const VALID_FILE_EXTENTIONS: Array[String] = [
	"tscn",
	"bmp",
	"dds",
	"ktx",
	"exr",
	"hdr",
	"jpg",
	"jpeg",
	"png",
	"tga",
	"svg",
	"webp",
]


const ASSET_DISPLAY_SIZE: float = 110.0
const ASSET_DISPLAY_MARGIN: float = 20.0


@export var grid_container: GridContainer
@export var asset_display_container: Control
@export var folder_path_display_label: Label
@export var up_button: Button
@export var file_display_scene: PackedScene


var current_folder: String = "res://"


@onready var _viewport: Viewport = get_viewport()


func _ready():
	_viewport.size_changed.connect(_update_grid_container_size)
	_update_grid_container_size.call_deferred()
	_update_files()


func _update_files():
	folder_path_display_label.text = current_folder
	up_button.disabled = current_folder == "res://"
	for child in asset_display_container.get_children():
		child.queue_free()
	var display_folder_end_idx = 0
	var dir: DirAccess = DirAccess.open(current_folder)
	# TODO handle case where dir is null by displaying error message
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		var full_path = current_folder
		if current_folder != "res://":
			full_path = full_path + "/"
		full_path = full_path + file_name
		if dir.current_is_dir():
			var new_file_display: NinaEditorFileDisplay = file_display_scene.instantiate()
			new_file_display.set_folder(full_path)
			asset_display_container.add_child(new_file_display)
			asset_display_container.move_child(new_file_display, display_folder_end_idx)
			new_file_display.fully_pressed.connect(_on_folder_pressed)
			display_folder_end_idx += 1
		else:
			if VALID_FILE_EXTENTIONS.has(file_name.get_extension()):
				var new_file_display: NinaEditorFileDisplay = file_display_scene.instantiate()
				new_file_display.set_file(full_path)
				asset_display_container.add_child(new_file_display)
				new_file_display.pressed.connect(_on_file_pressed)
		file_name = dir.get_next()


func _on_file_pressed(file: NinaEditorFileDisplay):
	if file.type != NinaEditorFileDisplay.types.SCENE:
		return
		# TODO support assets and images
	


func _on_folder_pressed(folder: NinaEditorFileDisplay):
	current_folder = folder.path
	_update_files()


func _update_grid_container_size():
	await get_tree().process_frame
	var width = grid_container.get_parent().size.x - ASSET_DISPLAY_MARGIN
	grid_container.columns = maxi(int(width / ASSET_DISPLAY_SIZE), 1)


func _on_up_button_pressed():
	current_folder = _get_parent_folder(current_folder)
	_update_files()


func _get_parent_folder(folder: String): # FP
	var path_array: PackedStringArray = folder.split("/")
	path_array.remove_at(path_array.size() - 1)
	var output: String = ""
	for array_folder in path_array:
		output = output + "/" + array_folder
	output = output.erase(0, 1)
	if output == "res:/":
		output = "res://"
	return output
