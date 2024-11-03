class_name NinaEditor
extends Control


enum actions {
	UNDO,
	REDO,
}


const keyboard_shortcuts: Dictionary = {
	[KEY_CTRL, KEY_SHIFT, KEY_Z]: actions.REDO,
	[KEY_CTRL, KEY_Z]: actions.UNDO,
	[KEY_CTRL, KEY_Y]: actions.REDO,
}


signal action_triggered(action: actions)


@export var editor_viewport: SubViewport
@export var editor_viewport_container: NinaEditorViewportContainer
@export var drag_preview_scene: PackedScene


@onready var undo_redo_manager := NinaEditorUndoRedoManager.new()


@onready var _viewport: Viewport = get_viewport()
@onready var _level: NinaLevel = NinaUtils.get_level_of(self)
@onready var _level_viewport: SubViewport = _level.get_level_viewport()
var _editor_level_camera: Camera2D
var drag_preview: NinaEditorDragPreview = null


func start_file_drag(file: NinaEditorFileDisplay) -> void:
	drag_preview = drag_preview_scene.instantiate()
	drag_preview.file_display = file
	add_child(drag_preview)


func stop_file_drag() -> void:
	drag_preview.queue_free()
	drag_preview = null


func _ready() -> void:
	action_triggered.connect(_on_action_triggered)
	_editor_level_camera = Camera2D.new()
	_level_viewport.add_child(_editor_level_camera)
	editor_viewport_container.editor_level_camera = _editor_level_camera
	editor_viewport_container.level_viewport = _level_viewport


func _process(delta) -> void:
	if drag_preview:
		drag_preview.position = get_local_mouse_position()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if drag_preview:
				stop_file_drag()
	if event is InputEventKey:
		if event.pressed:
			_check_for_keyboard_shortcut(event)


func _on_action_triggered(action: actions):
	match action:
		actions.UNDO:
			undo_redo_manager.undo_current_action()
		actions.REDO:
			undo_redo_manager.redo_current_action()


func _check_for_keyboard_shortcut(event: InputEventKey) -> void:
	if not event.pressed:
		return
	for shortcut in keyboard_shortcuts:
		if shortcut.has(event.keycode):
			if _is_shorcut_pressed(shortcut):
				action_triggered.emit(keyboard_shortcuts[shortcut])
				return


func _is_shorcut_pressed(shortcut: Array):
	for key in shortcut:
		if not Input.is_key_pressed(key):
			return false
	return true
