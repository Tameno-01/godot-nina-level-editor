class_name NinaEditorUndoRedoManager
extends RefCounted

signal undo(action: Dictionary)
signal redo(action: Dictionary)

const MAX_UNDO_STEPS: int = 100

var _history: Array[Dictionary] = []
var _current_action_idx = -1


func do_action(action: Dictionary) -> void:
	_history = _history.slice(0, _current_action_idx + 1)
	_history.append(action)
	if _history.size() > MAX_UNDO_STEPS:
		_history.pop_front()
	else:
		_current_action_idx += 1


func undo_current_action() -> void:
	if _current_action_idx == -1:
		return
	undo.emit(_history[_current_action_idx])
	_current_action_idx -= 1


func redo_current_action() -> void:
	if _current_action_idx == _history.size() - 1:
		return
	_current_action_idx += 1
	redo.emit(_history[_current_action_idx])
