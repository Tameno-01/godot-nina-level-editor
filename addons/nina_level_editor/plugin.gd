@tool
extends EditorPlugin


func _enter_tree():
	# TODO: make the following commented out code work
	#if not InputMap.has_action(&"open_level_editor"):
		#InputMap.add_action(&"open_level_editor")
		#var f5_input_event: InputEventKey = InputEventKey.new()
		#f5_input_event.keycode = KEY_F5
		#f5_input_event.pressed = true
		#InputMap.action_add_event(&"open_level_editor", f5_input_event)
	if not ProjectSettings.has_setting("editor/nina_level_editor/open_level_editor_action"):
		ProjectSettings.set_setting(
				"editor/nina_level_editor/open_level_editor_action",
				&"open_level_editor",
		)


func _exit_tree():
	# TODO: should i undo everything the _enter_tree function does?
	pass
