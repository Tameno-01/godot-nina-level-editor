class_name NinaUtils
extends Object


static func get_level_of(node: Node) -> NinaLevel:
	var possible_level: Node = node
	while true: # returned out of
		possible_level = possible_level.get_parent()
		if possible_level is NinaLevel:
			return possible_level
		elif possible_level == null:
			push_error("Level not found.")
			return null
	return null # Unreachable


static func get_editor_of(node: Node) -> NinaEditor:
	var possible_editor: Node = node
	while true: # returned out of
		possible_editor = possible_editor.get_parent()
		if possible_editor is NinaEditor:
			return possible_editor
		elif possible_editor == null:
			push_error("Editor not found.")
			return null
	return null # Unreachable
