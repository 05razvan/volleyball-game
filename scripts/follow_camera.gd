class_name FollowCamera
extends Camera3D

var target: Node3D
var ball: Node3D
var team := 0
var distance := 8.3
var height := 5.1
var shake := 0.0

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var side := 1.0 if team == 0 else -1.0
	var focus := target.global_position
	if is_instance_valid(ball):
		var ball_weight := clampf(1.0 - target.global_position.distance_to(ball.global_position) / 18.0, 0.12, 0.42)
		focus = focus.lerp(ball.global_position, ball_weight)
		focus.y = maxf(focus.y, 1.15)
	var desired := target.global_position + Vector3(0.0, height, side * distance)
	desired.x += (focus.x - target.global_position.x) * 0.18
	global_position = global_position.lerp(desired, 1.0 - exp(-delta * 7.0))
	look_at(focus, Vector3.UP)
	if shake > 0.001:
		h_offset = randf_range(-shake, shake)
		v_offset = randf_range(-shake, shake)
		shake = move_toward(shake, 0.0, delta * 0.8)
	else:
		h_offset = 0.0
		v_offset = 0.0

func punch(amount: float) -> void:
	shake = maxf(shake, amount)

