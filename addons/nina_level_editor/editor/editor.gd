class_name NinaEditor
extends Control

signal action_triggered(action: StringName)

const COLOR_SELECTION: Color = Color(0.0, 1.0, 1.0)
const COLOR_X: Color = Color(1.0, 0.1, 0.0)
const COLOR_Y: Color = Color(0.1, 1.0, 0.0)
const COLOR_XY: Color = Color(1.0, 0.9, 0.0)
const COLOR_ROTATION: Color = Color(0.0, 0.5, 1.0)
# This dictionray HAS TO be sorted from longest shortest array
const KEYBOARD_SHORTCUTS: Dictionary = {
	[KEY_CTRL, KEY_SHIFT, KEY_Z]: &"redo",
	[KEY_CTRL, KEY_Z]: &"undo",
	[KEY_CTRL, KEY_Y]: &"redo",
	[KEY_DELETE]: &"delete",
	[KEY_BACKSPACE]: &"delete"
}
const KEY_MULTI_SELECT: int = KEY_SHIFT
const KEY_ORBIT: int = KEY_SHIFT
const KEY_BACK_TO_2D: int = KEY_KP_1

@export var level_viewport: SubViewport
@export var level_container: NinaLevelContainer
@export var drag_preview_scene: PackedScene

var drag_preview: NinaDragPreview = null

var _editor_level_camera: Camera2D

@onready var undo_redo_manager := NinaUndoRedoManager.new()
@onready var _viewport: Viewport = get_viewport()
@onready var _level: NinaLevel = NinaUtils.get_level_of(self)
@onready var _level_viewport: SubViewport = _level.get_level_viewport()


func _ready() -> void:
	_editor_level_camera = Camera2D.new()
	_level_viewport.add_child(_editor_level_camera)
	level_container.editor_level_camera = _editor_level_camera
	level_container.level_viewport = _level_viewport


func _process(delta) -> void:
	if drag_preview != null:
		drag_preview.position = get_local_mouse_position()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if drag_preview != null:
				stop_file_drag()
	if event is InputEventKey:
		if event.pressed:
			_check_for_keyboard_shortcut()


func re_open() -> void:
	level_container.re_open()


func start_file_drag(file: NinaFileDisplay) -> void:
	drag_preview = drag_preview_scene.instantiate()
	drag_preview.file_display = file
	add_child(drag_preview)


func stop_file_drag() -> void:
	drag_preview.queue_free()
	drag_preview = null


func _on_action_triggered(action: StringName):
	match action:
		&"undo":
			undo_redo_manager.undo_current_action()
		&"redo":
			undo_redo_manager.redo_current_action()


func _check_for_keyboard_shortcut() -> void:
	for shortcut in KEYBOARD_SHORTCUTS:
		if _is_shorcut_pressed(shortcut):
			action_triggered.emit(KEYBOARD_SHORTCUTS[shortcut])
			return


func _is_shorcut_pressed(shortcut: Array):
	for key in shortcut:
		if not Input.is_key_pressed(key):
			return false
	return true


func _exit_tree() -> void:
	if drag_preview != null:
		stop_file_drag()
