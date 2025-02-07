class_name NinaOrbitCamera
extends Node3D

const ORBIT_SPEED = 0.02

var distance: float = 0.0:
		set = set_distance

@export var camera: Camera3D


func set_fov(value: float) -> void:
	if not is_node_ready():
		await ready
	camera.fov = value


func make_current() -> void:
	if not is_node_ready():
		await ready
	camera.current = true


func pan(input: Vector2) -> void:
	position += (
			-transform.basis.x * input.x
			+ transform.basis.y * input.y
	)


func orbit(input: Vector2) -> void:
	rotation.y -= input.x * ORBIT_SPEED
	rotation.x -= input.y * ORBIT_SPEED
	rotation.x = clampf(rotation.x, -TAU / 4.0, TAU / 4.0)


func set_distance(value) -> void:
	if not is_node_ready():
		await ready
	distance = value
	camera.position.z = distance


func get_fov_tan() -> float:
	return tan(deg_to_rad(camera.fov / 2.0))
