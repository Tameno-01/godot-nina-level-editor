class_name NinaChunkManager
extends RefCounted

signal chunk_loaded(chunk: NinaChunk)
signal chunk_unloaded(grid_position: Vector2i)

const SCENE_PATH: String = "scene.scn"

var chunks_folder: String
var chunks_parent: Node

# key: Vector2i grid position of a chunk
# value: NinaChunk in that position
var _loaded_chunks: Dictionary = {}


func get_loaded_chunk(grid_position: Vector2i) -> NinaChunk:
	return _loaded_chunks[grid_position]


func chunk_file_exists(grid_position: Vector2i) -> bool:
	return DirAccess.dir_exists_absolute(_convert_to_folder_path(grid_position))


func is_chunk_loaded(grid_position: Vector2i) -> bool:
	return _loaded_chunks.has(grid_position)


func load_chunk(grid_position: Vector2i) -> void:
	if is_chunk_loaded(grid_position):
		var chunk: NinaChunk = get_loaded_chunk(grid_position)
		chunk.load_count += 1
		return
	_actual_load_chunk(grid_position)


func unload_chunk(grid_position: Vector2i) -> void:
	if not is_chunk_loaded(grid_position):
		push_error("Trying to unload chunk, but chunk is not loaded.")
		return
	var chunk: NinaChunk = get_loaded_chunk(grid_position)
	chunk.load_count -= 1
	if chunk.load_count == 0:
		_actual_unload_chunk(grid_position)


func save_chunk(grid_position: Vector2i, id_manager: NinaIdManager) -> void:
	if not is_chunk_loaded(grid_position):
		push_error("Can't save chunk since it doesn't exist.")
		return
	var chunk: NinaChunk = get_loaded_chunk(grid_position)
	chunk.ids = {}
	for child: Node in chunk.get_children():
		if id_manager.has_node(child):
			var path: NodePath = chunk.get_path_to(child)
			chunk.ids[path] = id_manager.get_id_from_node(child)
	var scene: PackedScene = PackedScene.new()
	scene.pack(chunk)
	var chunk_folder: String = _convert_to_folder_path(grid_position)
	if not DirAccess.dir_exists_absolute(chunk_folder):
		DirAccess.make_dir_absolute(chunk_folder)
	var err: int = ResourceSaver.save(
			scene,
			chunk_folder + "/" + SCENE_PATH,
	)
	if err != OK:
		push_error("Error when saving chunk: " + error_string(err))


func _actual_load_chunk(grid_position: Vector2i) -> void:
	if is_chunk_loaded(grid_position):
		push_error("Can't load chunk, it is alredy loaded.")
		return
	var chunk: NinaChunk
	if chunk_file_exists(grid_position):
		var scene: PackedScene = load(_convert_to_folder_path(grid_position) + "/" + SCENE_PATH)
		chunk = scene.instantiate()
	else:
		chunk = NinaChunk.new()
	chunk.grid_position = grid_position
	_loaded_chunks[grid_position] = chunk
	var siblings: Array[Node] = chunks_parent.get_children()
	chunks_parent.add_child(chunk)
	for i: int in range(siblings.size()):
		if _chunk_should_be_before(chunk, siblings[i]):
			chunks_parent.move_child(chunk, i)
			break
	chunk_loaded.emit(chunk)


func _actual_unload_chunk(grid_position: Vector2i) -> void:
	if not is_chunk_loaded(grid_position):
		push_error("Trying to unload chunk, but chunk is not loaded.")
		return
	var chunk: NinaChunk = get_loaded_chunk(grid_position)
	_loaded_chunks.erase(grid_position)
	chunk.queue_free()
	chunk_unloaded.emit(grid_position)


func _chunk_should_be_before(chunk: NinaChunk, node: Node) -> bool:
	if not node is NinaChunk:
		return true
	if chunk.grid_position.y < node.grid_position.y:
		return true
	if chunk.grid_position.y > node.grid_position.y:
		return false
	if chunk.grid_position.x < node.grid_position.x:
		return true
	return false


func _convert_to_folder_path(grid_position: Vector2i) -> String:
	return "%s/%s,%s" % [chunks_folder, grid_position.x, grid_position.y]
