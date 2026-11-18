class_name VolleyBall
extends Node3D

signal landed(position: Vector3)

const RADIUS := 0.19
const COURT_HALF_WIDTH := 4.5
const COURT_HALF_LENGTH := 9.0
const NET_HEIGHT := 2.43

var velocity := Vector3.ZERO
var active := false
var last_position := Vector3.ZERO
var trail_points: Array[Vector3] = []
var last_team := -1
var gravity := 13.5
var mesh: MeshInstance3D
var shadow: Decal

func _ready() -> void:
	mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = RADIUS
	sphere.height = RADIUS * 2.0
	sphere.radial_segments = 20
	sphere.rings = 10
	mesh.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("f5f3e9")
	material.roughness = 0.42
	material.metallic = 0.0
	mesh.material_override = material
	add_child(mesh)
	var seam := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS * 0.91
	torus.outer_radius = RADIUS
	torus.rings = 18
	torus.ring_segments = 5
	seam.mesh = torus
	var seam_mat := StandardMaterial3D.new()
	seam_mat.albedo_color = Color("365779")
	seam.material_override = seam_mat
	seam.rotation.x = PI * 0.5
	add_child(seam)

func _physics_process(delta: float) -> void:
	if not active:
		return
	for _substep in range(2):
		_simulate(delta * 0.5)
	mesh.rotation.x += velocity.z * delta * 0.7
	mesh.rotation.z -= velocity.x * delta * 0.7

func _simulate(delta: float) -> void:
	last_position = global_position
	velocity.y -= gravity * delta
	global_position += velocity * delta
	_handle_net(last_position, global_position)
	if global_position.y <= RADIUS:
		global_position.y = RADIUS
		active = false
		velocity = Vector3.ZERO
		landed.emit(global_position)
	trail_points.push_front(global_position)
	if trail_points.size() > 16:
		trail_points.pop_back()

func _handle_net(previous: Vector3, current: Vector3) -> void:
	if previous.z * current.z > 0.0:
		return
	if current.y > NET_HEIGHT + RADIUS or absf(current.x) > COURT_HALF_WIDTH + 0.25:
		return
	global_position.z = signf(previous.z) * (RADIUS + 0.05)
	velocity.z *= -0.48
	velocity.x *= 0.86
	velocity.y = maxf(velocity.y * 0.72, 0.5)

func reset_to(position: Vector3) -> void:
	global_position = position
	velocity = Vector3.ZERO
	active = false
	trail_points.clear()
	last_team = -1

func launch(new_velocity: Vector3, team: int) -> void:
	velocity = new_velocity
	active = true
	last_team = team

func target_velocity(target: Vector3, flight_time: float) -> Vector3:
	var time := maxf(flight_time, 0.18)
	var displacement := target - global_position
	return Vector3(
		displacement.x / time,
		(displacement.y + 0.5 * gravity * time * time) / time,
		displacement.z / time
	)

func predicted_landing() -> Vector3:
	if not active:
		return global_position
	var a := -0.5 * gravity
	var b := velocity.y
	var c := global_position.y - RADIUS
	var discriminant := b * b - 4.0 * a * c
	if discriminant < 0.0:
		return global_position
	var t1 := (-b - sqrt(discriminant)) / (2.0 * a)
	var t2 := (-b + sqrt(discriminant)) / (2.0 * a)
	var t := maxf(t1, t2)
	if t < 0.0:
		t = minf(t1, t2)
	return Vector3(global_position.x + velocity.x * t, RADIUS, global_position.z + velocity.z * t)

