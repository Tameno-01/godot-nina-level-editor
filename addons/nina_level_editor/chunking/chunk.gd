class_name NinaChunk
extends Node

var grid_position: Vector2i = Vector2i.ZERO
var load_count: int = 1

# Only read/written when saving/loading
# key: NodePath to node
# value: int id of that node
@export var ids: Dictionary = {}
