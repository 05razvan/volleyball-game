class_name VolleyPlayer
extends CharacterBody3D

signal meter_changed(player_id: int, stamina_value: float, jump_value: float, action_value: float, action_name: String)

var config: PlayerConfig
var tuning: GameplayTuning
var game: Node
var camera: Camera3D
var aim_target := Vector3.ZERO
var stamina := 100.0
var jump_hold := 0.0
var spike_charge := 0.0
var set_charge := 0.0
var dive_timer := 0.0
var recovery_timer := 0.0
var block_active := false
var action_cooldown := 0.0
var ai_timer := 0.0
var ai_jump_hold := 0.0
var previous_jump := false
var previous_primary := false
var previous_secondary := false
var previous_set := false
var body_root: Node3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var aim_marker: MeshInstance3D
var name_label: Label3D

func setup(player_config: PlayerConfig, gameplay_tuning: GameplayTuning, owner_game: Node) -> void:
	config = player_config
	tuning = gameplay_tuning
	game = owner_game
	stamina = tuning.stamina_max
	_build_body()
	_build_collision()
	aim_target = Vector3(0.0, 0.03, -4.0 if config.team == 0 else 4.0)

func _build_collision() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.36
	capsule.height = 1.5
	shape.shape = capsule
	shape.position.y = 0.78
	add_child(shape)
	collision_layer = 2 if config.team == 0 else 4
	collision_mask = 1 | collision_layer

func _build_body() -> void:
	body_root = Node3D.new()
	body_root.name = "Body"
	add_child(body_root)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color("f2b28f") if config.slot % 3 == 0 else Color("8e5a42") if config.slot % 3 == 1 else Color("d98c68")
	skin.roughness = 0.75
	var uniform := StandardMaterial3D.new()
	uniform.albedo_color = config.primary_color
	uniform.roughness = 0.62
	var dark := StandardMaterial3D.new()
	dark.albedo_color = config.accent_color
	dark.roughness = 0.7

	var torso := MeshInstance3D.new()
	var torso_mesh := CapsuleMesh.new()
	torso_mesh.radius = 0.34
	torso_mesh.height = 0.88
	torso.mesh = torso_mesh
	torso.material_override = uniform
	torso.position.y = 0.94
	body_root.add_child(torso)

	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.31
	head_mesh.height = 0.62
	head.mesh = head_mesh
	head.material_override = skin
	head.position.y = 1.64
	body_root.add_child(head)

	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.325
	hair_mesh.height = 0.36
	hair.mesh = hair_mesh
	hair.material_override = dark
	hair.position = Vector3(0.0, 1.78, 0.0)
	body_root.add_child(hair)

	left_arm = _make_limb(skin, Vector3(-0.42, 1.06, 0.0), Vector3(0.14, 0.62, 0.14))
	right_arm = _make_limb(skin, Vector3(0.42, 1.06, 0.0), Vector3(0.14, 0.62, 0.14))
	body_root.add_child(left_arm)
	body_root.add_child(right_arm)
	for x in [-0.19, 0.19]:
		var leg := _make_limb(dark, Vector3(x, 0.37, 0.0), Vector3(0.18, 0.68, 0.18))
		body_root.add_child(leg)

	name_label = Label3D.new()
	name_label.text = config.display_name
	name_label.position.y = 2.18
	name_label.font_size = 34
	name_label.outline_size = 8
	name_label.modulate = config.primary_color.lightened(0.22)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(name_label)

	aim_marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.32
	ring.outer_radius = 0.39
	ring.rings = 24
	ring.ring_segments = 6
	aim_marker.mesh = ring
	var marker_material := StandardMaterial3D.new()
	marker_material.albedo_color = config.primary_color
	marker_material.emission_enabled = true
	marker_material.emission = config.primary_color * 0.45
	aim_marker.material_override = marker_material
	aim_marker.rotation.x = PI * 0.5
	game.add_child.call_deferred(aim_marker)

func _make_limb(material: Material, position_value: Vector3, size: Vector3) -> MeshInstance3D:
	var limb := MeshInstance3D.new()
	var mesh_value := CapsuleMesh.new()
	mesh_value.radius = size.x
	mesh_value.height = size.y
	limb.mesh = mesh_value
	limb.material_override = material
	limb.position = position_value
	return limb

func _physics_process(delta: float) -> void:
	if config == null or game == null:
		return
	action_cooldown = maxf(action_cooldown - delta, 0.0)
	recovery_timer = maxf(recovery_timer - delta, 0.0)
	var controls := _bot_controls(delta) if not config.is_human else _human_controls(delta)
	_update_aim(delta, controls.aim)
	_update_movement(delta, controls.move, controls.dash, controls.strafe)
	_update_actions(delta, controls)
	_update_pose(delta)
	if is_instance_valid(aim_marker):
		aim_marker.global_position = aim_target + Vector3(0.0, 0.035, 0.0)
	var action_value := spike_charge if spike_charge > 0.0 else set_charge
	var action_name := "SPIKE" if spike_charge > 0.0 else "SET" if set_charge > 0.0 else "READY"
	meter_changed.emit(config.slot, stamina / tuning.stamina_max, clampf(jump_hold / tuning.jump_charge_time, 0.0, 1.0), action_value, action_name)

func _human_controls(_delta: float) -> Dictionary:
	return {
		"move": InputRouter.move_vector(config),
		"aim": InputRouter.aim_vector(config),
		"jump": InputRouter.jump_down(config),
		"primary": InputRouter.primary_down(config),
		"secondary": InputRouter.secondary_down(config),
		"set": InputRouter.set_down(config),
		"dash": InputRouter.dash_down(config),
		"strafe": InputRouter.strafe_down(config),
	}

func _bot_controls(delta: float) -> Dictionary:
	var move := Vector2.ZERO
	var jump := false
	var primary := false
	var set_action := false
	var secondary := false
	var ball: VolleyBall = game.ball
	var side := 1.0 if config.team == 0 else -1.0
	var formation_x := -2.1 if config.slot % 2 == 0 else 2.1
	var target := Vector3(formation_x, 0.0, side * (4.4 if game.config.team_size > 1 else 3.4))
	if ball.active:
		var landing := ball.predicted_landing()
		var ball_on_side := landing.z * side > -0.3
		if ball_on_side:
			target = landing
		var distance_to_ball := global_position.distance_to(ball.global_position)
		if ball_on_side and ball.global_position.y > 1.65 and distance_to_ball < 2.3 and is_on_floor():
			ai_jump_hold += delta
			jump = ai_jump_hold < lerpf(0.34, 0.52, 1.0 - config.bot_difficulty)
		else:
			ai_jump_hold = 0.0
		if distance_to_ball <= tuning.contact_radius * 1.05 and action_cooldown <= 0.0:
			if not is_on_floor() and ball.global_position.y > 1.45:
				primary = true
				spike_charge = maxf(spike_charge, 0.58 + 0.35 * config.bot_difficulty)
			elif ball.global_position.y < 2.0:
				if game.director.touches[config.team] == 1 and game.config.team_size > 1:
					set_action = true
					set_charge = 0.45
				else:
					primary = true
	else:
		var server: VolleyPlayer = game.get_server()
		if server == self:
			target = global_position
			ai_timer += delta
			primary = ai_timer > 0.85
	var delta_target := target - global_position
	if delta_target.length() > 0.42:
		var world_move := Vector2(delta_target.x, delta_target.z).normalized()
		move = Vector2(world_move.x, world_move.y / side)
	var aim := Vector2.ZERO
	var desired_aim := Vector3(clampf(-global_position.x * 0.5, -3.8, 3.8), 0.0, -side * 6.5)
	var aim_delta := desired_aim - aim_target
	aim = Vector2(aim_delta.x, aim_delta.z * side).limit_length(1.0)
	return {"move": move, "aim": aim, "jump": jump, "primary": primary, "secondary": secondary, "set": set_action, "dash": move.length() > 0.8 and stamina > 35.0, "strafe": true}

func _update_aim(delta: float, stick_aim: Vector2) -> void:
	var side := 1.0 if config.team == 0 else -1.0
	if config.is_human and config.device_id < 0 and is_instance_valid(camera):
		var mouse := camera.get_viewport().get_mouse_position()
		var origin := camera.project_ray_origin(mouse)
		var direction := camera.project_ray_normal(mouse)
		if absf(direction.y) > 0.0001:
			var distance_to_plane := -origin.y / direction.y
			if distance_to_plane > 0.0:
				aim_target = origin + direction * distance_to_plane
	elif stick_aim.length() > 0.0:
		aim_target += Vector3(stick_aim.x, 0.0, stick_aim.y * side) * delta * 10.5
	aim_target.x = clampf(aim_target.x, -5.0, 5.0)
	aim_target.z = clampf(aim_target.z, -9.6, 9.6)
	aim_target.y = 0.03

func _update_movement(delta: float, move_input: Vector2, dashing: bool, _strafing: bool) -> void:
	if recovery_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, tuning.braking * delta * 0.4)
		velocity.z = move_toward(velocity.z, 0.0, tuning.braking * delta * 0.4)
		_apply_gravity(delta)
		move_and_slide()
		return
	var side := 1.0 if config.team == 0 else -1.0
	var desired_direction := Vector3(move_input.x, 0.0, move_input.y * side)
	if desired_direction.length() > 1.0:
		desired_direction = desired_direction.normalized()
	var can_dash := dashing and stamina > 1.0 and is_on_floor()
	var speed := tuning.dash_speed if can_dash else tuning.walk_speed
	if can_dash:
		stamina = maxf(stamina - tuning.dash_drain * delta, 0.0)
	var target_velocity := desired_direction * speed
	var acceleration := tuning.ground_acceleration if is_on_floor() else tuning.air_acceleration
	if desired_direction.length_squared() < 0.01:
		acceleration = tuning.braking if is_on_floor() else tuning.air_acceleration * 0.3
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	_apply_gravity(delta)
	if is_on_floor() and not can_dash and recovery_timer <= 0.0 and not game.config.infinite_stamina:
		stamina = minf(stamina + tuning.stamina_regen * delta, tuning.stamina_max)
	elif game.config.infinite_stamina:
		stamina = tuning.stamina_max
	move_and_slide()
	for collision_index in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		var other := collision.get_collider()
		if other is VolleyPlayer and other.config.team == config.team:
			var closing_speed := Vector2(velocity.x - other.velocity.x, velocity.z - other.velocity.z).length()
			if closing_speed > 7.5 and game.config.teammate_collisions:
				recovery_timer = maxf(recovery_timer, 0.48)
				other.recovery_timer = maxf(other.recovery_timer, 0.48)
	if global_position.z * side < -0.35:
		game.director.player_invaded(config.team)
		global_position.z = side * 0.4

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= tuning.gravity * delta
	else:
		velocity.y = maxf(velocity.y, -0.5)

func _update_actions(delta: float, controls: Dictionary) -> void:
	var jump_now: bool = controls.jump
	var primary_now: bool = controls.primary
	var secondary_now: bool = controls.secondary
	var set_now: bool = controls.set
	if jump_now and is_on_floor() and recovery_timer <= 0.0:
		jump_hold += delta
	if previous_jump and not jump_now and is_on_floor() and jump_hold > 0.0:
		var normalized := clampf(jump_hold / tuning.jump_charge_time, 0.0, 1.0)
		var perfect := jump_hold >= tuning.jump_charge_time and jump_hold <= tuning.jump_charge_time + tuning.perfect_window
		velocity.y = tuning.perfect_jump_speed if perfect and stamina > 45.0 else lerpf(tuning.jump_min_speed, tuning.jump_max_speed, normalized)
		if perfect:
			stamina = 0.0
		jump_hold = 0.0
	if not is_on_floor() and primary_now:
		spike_charge = minf(spike_charge + delta / tuning.spike_charge_time, 1.0)
	if previous_primary and not primary_now:
		if not is_on_floor() and spike_charge > 0.0:
			game.try_spike(self, spike_charge)
			spike_charge = 0.0
		elif is_on_floor():
			game.try_receive(self)
	if primary_now and not previous_primary and is_on_floor():
		game.try_receive(self)
	if set_now:
		set_charge = minf(set_charge + delta / tuning.set_charge_time, 1.0)
	if previous_set and not set_now and set_charge > 0.0:
		game.try_set(self, set_charge)
		set_charge = 0.0
	if secondary_now and not previous_secondary:
		if is_on_floor() and stamina > 2.0:
			var direction := (aim_target - global_position).normalized()
			velocity.x = direction.x * tuning.dive_speed
			velocity.z = direction.z * tuning.dive_speed
			stamina = maxf(stamina - tuning.dive_cost, 0.0)
			recovery_timer = tuning.dive_duration if stamina > 0.0 else tuning.exhausted_recovery
			game.try_dive_contact(self)
		else:
			block_active = true
	if is_on_floor() and block_active:
		block_active = false
	if block_active:
		game.try_block(self)
	previous_jump = jump_now
	previous_primary = primary_now
	previous_secondary = secondary_now
	previous_set = set_now

func _update_pose(delta: float) -> void:
	var desired_yaw := atan2(aim_target.x - global_position.x, aim_target.z - global_position.z)
	body_root.rotation.y = lerp_angle(body_root.rotation.y, desired_yaw, 1.0 - exp(-delta * 11.0))
	var arm_angle := -2.35 if block_active else -1.55 if spike_charge > 0.0 or set_charge > 0.0 else -0.15
	left_arm.rotation.x = lerp_angle(left_arm.rotation.x, arm_angle, delta * 12.0)
	right_arm.rotation.x = lerp_angle(right_arm.rotation.x, arm_angle, delta * 12.0)
	var squash := 0.9 if recovery_timer > 0.0 else 1.0
	body_root.scale.y = lerpf(body_root.scale.y, squash, delta * 10.0)

func reset_player(position_value: Vector3) -> void:
	global_position = position_value
	velocity = Vector3.ZERO
	jump_hold = 0.0
	spike_charge = 0.0
	set_charge = 0.0
	recovery_timer = 0.0
	block_active = false
	action_cooldown = 0.0
	ai_timer = 0.0
	stamina = tuning.stamina_max

func contact_point() -> Vector3:
	return global_position + Vector3(0.0, 1.25 if is_on_floor() else 1.55, 0.0)

