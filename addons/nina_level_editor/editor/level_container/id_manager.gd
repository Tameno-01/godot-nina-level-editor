class_name NinaIdManager
extends Resource

# key: int id
# value: Node that is assigned that id
var _id_to_node: Dictionary = {}
# key: Node
# value: int id that is assigned to that node
var _node_to_id: Dictionary = {}

@export var _largest_id: int = 0


func get_node_from_id(id: int) -> Node:
	var output: Node = _id_to_node[id]
	if output == null:
		push_error("ID does not exist.")
	return output


func get_id_from_node(node: Node) -> int:
	var output: int = _node_to_id[node]
	if output == null:
		push_error("Node has no ID.")
	return output


func add_node(node: Node, id: int) -> void:
	_id_to_node[id] = node
	_node_to_id[node] = id


func add_completely_new_node(node: Node) -> void:
	add_node(node, _get_new_id())


func remove_node(node: Node) -> void:
	var id: int = _node_to_id[node]
	_node_to_id.erase(node)
	_id_to_node.erase(id)


func has_node(node: Node) -> bool:
	return _node_to_id.has(node)


func _get_new_id() -> int:
	_largest_id += 1
	return _largest_id
