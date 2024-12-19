class_name NinaLevel
extends Node

const CHUNKS_FOLDER_PATH = "chunks"
const ID_MANAGER_PATH = "id_manager.tres"

enum Modes {
	PLAY,
	EDIT,
}

const _EDITOR_SCENE: PackedScene = preload(
		"res://addons/nina_level_editor/editor/editor.tscn"
)
const _CAM_AND_VIEWPORT_SCENE: PackedScene = preload(
		"res://addons/nina_level_editor/cam_and_viewport/cam_and_viewport.tscn"
)

var _current_mode: Modes = Modes.PLAY
var _editor: NinaEditor = null
var _nodes_for_current_mode: Array[Node] = []
var _level_viewport: SubViewport
var _chunk_manager: NinaChunkManager

@export_dir var level_folder: String = ""
@export var viewport_scale: float = 0.01
@export var swicth_modes_action: String = ""


func _ready() -> void:
	_assert_valid_configuration()
	_create_necessary_files_and_folders()
	_setup_play_mode()


func swicth_mode() -> void:
	match _current_mode:
		Modes.PLAY:
			_switch_to_edit_mode()
		Modes.EDIT:
			_switch_to_play_mode()


func get_current_mode() -> Modes:
	return _current_mode


func get_level_viewport() -> SubViewport:
	return _level_viewport


func get_chunk_manager() -> NinaChunkManager:
	return _chunk_manager


func _assert_valid_configuration() -> void:
	assert(
			level_folder.is_absolute_path(),
			"Level Folder isn't a valid path.",
	)
	assert(
			DirAccess.dir_exists_absolute(level_folder),
			"Level Folder does not exist.",
	)


func _create_necessary_files_and_folders() -> void:
	# TODO: Move this code to the classes that actually need these files
	if not DirAccess.dir_exists_absolute(level_folder + "/" + CHUNKS_FOLDER_PATH):
		DirAccess.make_dir_absolute(level_folder + "/" + CHUNKS_FOLDER_PATH)
	if not FileAccess.file_exists(level_folder + "/" + ID_MANAGER_PATH):
		ResourceSaver.save(NinaIdManager.new(), level_folder + "/" + ID_MANAGER_PATH)


func _reset_chunk_manager() -> void:
	_chunk_manager = NinaChunkManager.new()
	_chunk_manager.chunks_folder = level_folder + "/" + CHUNKS_FOLDER_PATH
	_chunk_manager.chunks_parent = get_level_viewport()


func _unhandled_input(event):
	if swicth_modes_action.is_empty():
		return
	if event.is_action_pressed(swicth_modes_action):
		swicth_mode()


func _add_node_for_current_mode(node: Node, parent: Node) -> void:
	parent.add_child(node)
	_nodes_for_current_mode.append(node)


func _setup_cam_and_viewport(parent: Node, delete_on_mode_switch: bool = true) -> void:
	var cam_and_viewport: NinaCamAndViewportHolder = _CAM_AND_VIEWPORT_SCENE.instantiate()
	cam_and_viewport.viewport_scale = viewport_scale
	_level_viewport = cam_and_viewport.level_viewport
	if delete_on_mode_switch:
		_add_node_for_current_mode(cam_and_viewport, parent)
	else:
		parent.add_child(cam_and_viewport)


func _switch_to_edit_mode() -> void:
	if _current_mode == Modes.EDIT:
		return
	_delete_nodes_for_current_mode()
	_setup_edit_mode()
	_current_mode = Modes.EDIT


func _setup_edit_mode() -> void:
	var first_time_opening_editor: bool = false
	if _editor == null:
		_editor = _EDITOR_SCENE.instantiate()
		_setup_cam_and_viewport(_editor.level_viewport, false)
		first_time_opening_editor = true
	_reset_chunk_manager()
	add_child(_editor)
	if not first_time_opening_editor:
		_editor.re_open()


func _switch_to_play_mode() -> void:
	if _current_mode == Modes.PLAY:
		return
	_delete_nodes_for_current_mode()
	if _editor != null:
		remove_child(_editor)
	_setup_play_mode()
	_current_mode = Modes.PLAY


func _setup_play_mode():
	_setup_cam_and_viewport(self)
	_reset_chunk_manager()
	_chunk_manager.load_chunk(Vector2i.ZERO)


func _delete_nodes_for_current_mode() -> void:
	for node in _nodes_for_current_mode:
		node.queue_free()
	_nodes_for_current_mode.clear()


func _exit_tree() -> void:
	if _editor != null:
		_editor.free()
