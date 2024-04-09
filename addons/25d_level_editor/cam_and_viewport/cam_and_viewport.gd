extends Node


@export var viewport: SubViewport
@export var quad: CSGMesh3D
@export var camera: Camera3D


var viewport_scale: float


func _ready() -> void:
	_update_size()
	get_viewport().connect("size_changed", _on_parent_viewport_size_changed)


func _process(_delta: float) -> void:
	# this function was programmed by trial and error...
	var transform_2d: Transform2D = viewport.canvas_transform.inverse()
	var zoom = transform_2d.x.length()
	var quad_transform: Transform3D = Transform3D.IDENTITY
	quad_transform.basis.x *= viewport.size.x / zoom
	quad_transform.basis.y *= viewport.size.y / zoom
	quad_transform = quad_transform.rotated(Vector3.FORWARD, transform_2d.get_rotation())
	quad_transform = quad_transform.translated(
			Vector3(transform_2d.origin.x, -transform_2d.origin.y, 0.0) / (zoom * zoom)
	)
	quad_transform = quad_transform.scaled(Vector3(viewport_scale, viewport_scale, 1.0))
	quad.transform = quad_transform
	var camera_transform: Transform3D = Transform3D.IDENTITY
	camera_transform.origin = Vector3(
			viewport.size.x / 2.0 / zoom,
			-viewport.size.y / 2.0 / zoom,
			(viewport.size.y / 2.0 / zoom) / tan(deg_to_rad(camera.fov / 2.0)),
	)
	camera_transform = camera_transform.rotated(Vector3.FORWARD, transform_2d.get_rotation())
	camera_transform = camera_transform.translated(
			Vector3(transform_2d.origin.x, -transform_2d.origin.y, 0.0) / (zoom * zoom)
	)
	camera_transform.origin = camera_transform.origin * viewport_scale
	camera.transform = camera_transform


func _on_parent_viewport_size_changed() -> void:
	_update_size()


func _update_size() -> void:
	viewport.size = get_viewport().size
