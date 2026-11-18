class_name VolleyballGame
extends Node3D

signal match_ended(winning_team: int)
signal impact(strength: float)

var config: MatchConfig
var tuning := GameplayTuning.new()
var director: MatchDirector
var ball: VolleyBall
var players: Array[VolleyPlayer] = []
var human_players: Array[VolleyPlayer] = []
var landing_marker: MeshInstance3D
var serve_timeout := 0.0

func setup(match_config: MatchConfig, player_configs: Array[PlayerConfig]) -> void:
	config = match_config
	_build_environment()
	director = MatchDirector.new()
	add_child(director)
	director.setup(config)
	director.rally_reset.connect(_reset_rally)
	director.match_finished.connect(_on_match_finished)
	ball = VolleyBall.new()
	ball.name = "Ball"
	add_child(ball)
	ball.landed.connect(director.ball_landed)
	_build_landing_marker()
	for player_config in player_configs:
		var player := VolleyPlayer.new()
		player.name = player_config.display_name.replace(" ", "_")
		add_child(player)
		player.setup(player_config, tuning, self)
		players.append(player)
		if player_config.is_human:
			human_players.append(player)
	_reset_rally(0)

func _physics_process(_delta: float) -> void:
	if config.practice_mode and Input.is_key_pressed(KEY_R) and not ball.active:
		_reset_rally(0)
	if is_instance_valid(landing_marker):
		landing_marker.visible = config.show_ball_indicator and ball.active
		if landing_marker.visible:
			landing_marker.global_position = ball.predicted_landing() + Vector3(0.0, 0.025, 0.0)
	if director.phase == MatchDirector.Phase.SERVE_READY:
		serve_timeout += get_physics_process_delta_time()
		if serve_timeout > 8.0:
			var server := get_server()
			if is_instance_valid(server):
				perform_serve_toss(server)

func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("ded9cf")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("fff3df")
	environment.ambient_light_energy = 0.82
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	sun.light_color = Color("fff0d5")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	_add_box("Floor", Vector3(18.0, 0.18, 26.0), Vector3(0.0, -0.12, 0.0), Color("d49258"), true)
	_add_box("Court", Vector3(9.2, 0.06, 18.2), Vector3(0.0, 0.01, 0.0), Color("efb56f"), false)
	_add_box("ApronNorth", Vector3(18.0, 0.08, 3.2), Vector3(0.0, 0.0, -10.8), Color("d85f78"), false)
	_add_box("ApronSouth", Vector3(18.0, 0.08, 3.2), Vector3(0.0, 0.0, 10.8), Color("d85f78"), false)
	for line in [
		[Vector3(9.08, 0.025, 0.055), Vector3(0.0, 0.075, -9.0)],
		[Vector3(9.08, 0.025, 0.055), Vector3(0.0, 0.075, 9.0)],
		[Vector3(0.055, 0.025, 18.0), Vector3(-4.5, 0.075, 0.0)],
		[Vector3(0.055, 0.025, 18.0), Vector3(4.5, 0.075, 0.0)],
		[Vector3(9.0, 0.025, 0.045), Vector3(0.0, 0.075, -3.0)],
		[Vector3(9.0, 0.025, 0.045), Vector3(0.0, 0.075, 3.0)],
	]:
		_add_box("CourtLine", line[0], line[1], Color("fff5e8"), false)
	_build_net()
	_build_gym_shell()

func _build_net() -> void:
	for x in [-4.85, 4.85]:
		_add_cylinder(Vector3(x, 1.35, 0.0), 0.09, 2.7, Color("cb315e"))
	for y_index in range(7):
		var y := 1.12 + y_index * 0.22
		_add_box("NetHorizontal", Vector3(9.55, 0.018, 0.018), Vector3(0.0, y, 0.0), Color("273248"), false)
	for x_index in range(20):
		var x := -4.5 + x_index * (9.0 / 19.0)
		_add_box("NetVertical", Vector3(0.018, 1.36, 0.018), Vector3(x, 1.77, 0.0), Color("273248"), false)
	_add_box("NetTape", Vector3(9.65, 0.07, 0.07), Vector3(0.0, 2.46, 0.0), Color("fff7ed"), false)

func _build_gym_shell() -> void:
	_add_box("BackWall", Vector3(22.0, 8.0, 0.3), Vector3(0.0, 4.0, -14.0), Color("d9d4cb"), false)
	_add_box("FrontWall", Vector3(22.0, 8.0, 0.3), Vector3(0.0, 4.0, 14.0), Color("d9d4cb"), false)
	_add_box("LeftWall", Vector3(0.3, 8.0, 28.0), Vector3(-11.0, 4.0, 0.0), Color("e1ddd4"), false)
	_add_box("RightWall", Vector3(0.3, 8.0, 28.0), Vector3(11.0, 4.0, 0.0), Color("e1ddd4"), false)
	for side in [-1.0, 1.0]:
		for row in range(5):
			var x := side * (6.5 + row * 0.62)
			var height := 0.32 + row * 0.34
			_add_box("Bleacher", Vector3(0.62, 0.22, 18.0), Vector3(x, height, 0.0), Color("c94f68") if row % 2 == 0 else Color("e1687e"), false)
	for z in [-13.82, 13.82]:
		for x in [-7.2, -2.4, 2.4, 7.2]:
			_add_box("Window", Vector3(2.7, 1.1, 0.05), Vector3(x, 5.8, z - signf(z) * 0.19), Color("f8f2d9"), false, true)

func _add_box(node_name: String, size: Vector3, position_value: Vector3, color: Color, collision: bool, emission: bool = false) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	if emission:
		material.emission_enabled = true
		material.emission = color * 0.55
	mesh_instance.material_override = material
	mesh_instance.position = position_value
	add_child(mesh_instance)
	if collision:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.position = position_value
		body.add_child(shape)
		add_child(body)
	return mesh_instance

func _add_cylinder(position_value: Vector3, radius: float, height: float, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	instance.mesh = cylinder
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	instance.material_override = material
	instance.position = position_value
	add_child(instance)

func _build_landing_marker() -> void:
	landing_marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.48
	ring.outer_radius = 0.56
	ring.rings = 28
	ring.ring_segments = 6
	landing_marker.mesh = ring
	landing_marker.rotation.x = PI * 0.5
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("ffe16a")
	material.emission_enabled = true
	material.emission = Color("ffe16a") * 0.5
	landing_marker.material_override = material
	landing_marker.visible = false
	add_child(landing_marker)

func _reset_rally(serving_team: int) -> void:
	serve_timeout = 0.0
	var team_indices := [0, 0]
	for player in players:
		var side := 1.0 if player.config.team == 0 else -1.0
		var index: int = team_indices[player.config.team]
		team_indices[player.config.team] += 1
		var x := 0.0 if config.team_size == 1 else (-2.15 if index == 0 else 2.15)
		var z := side * (5.7 if index == 0 else 3.7)
		player.reset_player(Vector3(x, 0.05, z))
	var server := get_server()
	if is_instance_valid(server):
		var side := 1.0 if serving_team == 0 else -1.0
		ball.reset_to(server.global_position + Vector3(0.0, 1.25, -side * 0.72))

func get_server() -> VolleyPlayer:
	for player in players:
		if player.config.team == director.serving_team:
			return player
	return null

func _ball_in_reach(player: VolleyPlayer, bonus: float = 0.0) -> bool:
	return player.contact_point().distance_to(ball.global_position) <= tuning.contact_radius + bonus

func try_receive(player: VolleyPlayer) -> void:
	if player.action_cooldown > 0.0:
		return
	if director.phase == MatchDirector.Phase.PRACTICE and not ball.active:
		var practice_side := 1.0 if player.config.team == 0 else -1.0
		ball.global_position = player.global_position + Vector3(0.0, 1.25, -practice_side * 0.65)
		ball.launch(Vector3(player.velocity.x * 0.25, 5.7, -practice_side * 1.1), player.config.team)
		player.action_cooldown = 0.28
		return
	if director.phase == MatchDirector.Phase.SERVE_READY and get_server() == player:
		perform_serve_toss(player)
		return
	if not ball.active or not _ball_in_reach(player, 0.15):
		return
	if not director.register_touch(player.config.team, player.config.slot):
		return
	var target := player.aim_target
	target.y = 0.25
	ball.launch(ball.target_velocity(target, tuning.receive_time), player.config.team)
	player.action_cooldown = 0.22
	impact.emit(0.25)

func perform_serve_toss(player: VolleyPlayer) -> void:
	if director.phase != MatchDirector.Phase.SERVE_READY and director.phase != MatchDirector.Phase.PRACTICE:
		return
	var side := 1.0 if player.config.team == 0 else -1.0
	ball.global_position = player.global_position + Vector3(0.0, 1.25, -side * 0.65)
	ball.launch(Vector3(player.velocity.x * 0.25, 5.7, -side * 1.1), player.config.team)
	if director.phase == MatchDirector.Phase.SERVE_READY:
		director.start_serve()
	director.last_touch_team = player.config.team
	player.action_cooldown = 0.28

func try_set(player: VolleyPlayer, charge: float) -> void:
	if not ball.active or not _ball_in_reach(player, 0.2) or player.action_cooldown > 0.0:
		return
	if not director.register_touch(player.config.team, player.config.slot):
		return
	var target := player.aim_target
	var distance := Vector2(target.x - ball.global_position.x, target.z - ball.global_position.z).length()
	var flight_time := lerpf(1.15, 0.56, charge) if distance > 2.4 else lerpf(0.9, 1.35, charge)
	target.y = 0.35
	ball.launch(ball.target_velocity(target, flight_time), player.config.team)
	player.action_cooldown = 0.24
	impact.emit(0.2)

func try_spike(player: VolleyPlayer, charge: float) -> void:
	if not ball.active or not _ball_in_reach(player, 0.38) or player.action_cooldown > 0.0:
		return
	if not director.register_touch(player.config.team, player.config.slot):
		return
	var target := player.aim_target + Vector3(0.0, 0.18, 0.0)
	var direction := (target - ball.global_position).normalized()
	var approach := Vector2(player.velocity.x, player.velocity.z).length() / tuning.dash_speed
	var speed := lerpf(tuning.spike_min_speed, tuning.spike_max_speed, charge) * (1.0 + approach * 0.14)
	var lateral := Vector3(player.velocity.x, 0.0, 0.0) * 0.24
	ball.launch(direction * speed + lateral, player.config.team)
	player.action_cooldown = 0.32
	impact.emit(clampf(speed / tuning.spike_max_speed, 0.25, 1.0))

func try_block(player: VolleyPlayer) -> void:
	if not ball.active or player.action_cooldown > 0.0:
		return
	var block_point := player.global_position + Vector3(0.0, 1.85, 0.0)
	if block_point.distance_to(ball.global_position) > tuning.block_radius:
		return
	if not director.register_touch(player.config.team, player.config.slot, true):
		return
	var side := 1.0 if player.config.team == 0 else -1.0
	ball.launch(Vector3(ball.velocity.x * 0.6, absf(ball.velocity.y) * 0.45 + 1.0, -side * maxf(absf(ball.velocity.z) * 0.72, 7.0)), player.config.team)
	player.action_cooldown = 0.38
	impact.emit(0.72)

func try_dive_contact(player: VolleyPlayer) -> void:
	if not ball.active or not _ball_in_reach(player, 0.75):
		return
	if not director.register_touch(player.config.team, player.config.slot):
		return
	var target := player.aim_target + Vector3(0.0, 0.2, 0.0)
	ball.launch(ball.target_velocity(target, 1.18), player.config.team)
	player.action_cooldown = 0.4
	impact.emit(0.35)

func _on_match_finished(team: int) -> void:
	match_ended.emit(team)

