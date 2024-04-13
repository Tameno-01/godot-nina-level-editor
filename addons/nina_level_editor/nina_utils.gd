class_name NinaUtils
extends Object


# FP stands for Fake Private.
# This means that this member is accessed from outside this script,
# but should be hidden from the end user.


static func get_level_of(node: Node):
	var possible_level: Node = node
	while true: # returned out of
		possible_level = possible_level.get_parent()
		if possible_level is NinaLevel:
			return possible_level
		elif not possible_level:
			_print_detailed_err("Level not found.")
			return null


static func _print_detailed_err(error: String): # FP
	var stack: Array[Dictionary] = get_stack()
	stack.pop_front()
	printerr("(Nina Level Editor) " + error)
	print(_get_stack_string(stack))


static func _repeat_str(input: String, count: int) -> String:
	var output: String = ""
	for i in range(count):
		output = output + input
	return output


static func _get_stack_string(stack: Array[Dictionary]) -> String:
	var output: String = ""
	var longest_line_number_length: int = 0
	var longest_function_name_length: int = 0
	for call in stack:
		var line_number_length = str(call.line).length()
		if line_number_length > longest_line_number_length:
			longest_line_number_length = line_number_length
		var function_name_length = str(call.function).length()
		if function_name_length > longest_function_name_length:
			longest_function_name_length = function_name_length
	for call in stack:
		output = (
				output + 
				"	Line %s%s in %s%s in %s\n" %
				[
						call.line,
						_repeat_str(" ", longest_line_number_length - str(call.line).length()),
						call.function,
						_repeat_str(" ", longest_function_name_length - str(call.function).length()),
						call.source,
				]
		)
	return output
