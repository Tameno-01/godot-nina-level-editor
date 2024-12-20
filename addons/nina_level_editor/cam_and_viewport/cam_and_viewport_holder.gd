class_name NinaCamAndViewportHolder
extends Node

var viewport_scale: float

@export var level_viewport: SubViewport
@export var quad: MeshInstance3D
@export var camera: Camera3D


func _ready() -> void:
	_update_size()
	get_viewport().size_changed.connect(_on_parent_viewport_size_changed)


func _process(_delta: float) -> void:
	# this function was programmed by trial and error...
	var transform_2d: Transform2D = level_viewport.canvas_transform.inverse()
	var zoom = transform_2d.x.length()
	var quad_transform: Transform3D = Transform3D.IDENTITY
	quad_transform.basis.x *= level_viewport.size.x / zoom
	quad_transform.basis.y *= level_viewport.size.y / zoom
	quad_transform = quad_transform.rotated(Vector3.FORWARD, transform_2d.get_rotation())
	quad_transform = quad_transform.translated(
			Vector3(transform_2d.origin.x, -transform_2d.origin.y, 0.0) / (zoom * zoom)
	)
	quad_transform = quad_transform.scaled(Vector3(viewport_scale, viewport_scale, 1.0))
	quad.transform = quad_transform
	var camera_transform: Transform3D = Transform3D.IDENTITY
	camera_transform.origin = Vector3(
			level_viewport.size.x / 2.0 / zoom,
			-level_viewport.size.y / 2.0 / zoom,
			(level_viewport.size.y / 2.0 / zoom) / tan(deg_to_rad(camera.fov / 2.0)),
	)
	camera_transform = camera_transform.rotated(Vector3.FORWARD, transform_2d.get_rotation())
	camera_transform = camera_transform.translated(
			Vector3(transform_2d.origin.x, -transform_2d.origin.y, 0.0) / (zoom * zoom)
	)
	camera_transform.origin = camera_transform.origin * viewport_scale
	camera.transform = camera_transform


func _on_parent_viewport_size_changed() -> void:
	# I honestly don't know why this check is necessary,
	# but removing it crashes
	if not is_inside_tree():
		return
	_update_size()


func _update_size() -> void:
	level_viewport.size = get_viewport().size
