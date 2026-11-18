class_name InputRouter
extends RefCounted

const DEADZONE := 0.18

static func move_vector(config: PlayerConfig) -> Vector2:
	if config.device_id < 0:
		return Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return Vector2(
		Input.get_joy_axis(config.device_id, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(config.device_id, JOY_AXIS_LEFT_Y)
	).limit_length(1.0) if _joy_active(config.device_id) else Vector2.ZERO

static func aim_vector(config: PlayerConfig) -> Vector2:
	if config.device_id < 0:
		return Vector2.ZERO
	var value := Vector2(
		Input.get_joy_axis(config.device_id, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(config.device_id, JOY_AXIS_RIGHT_Y)
	)
	return value.limit_length(1.0) if value.length() >= DEADZONE else Vector2.ZERO

static func jump_pressed(config: PlayerConfig) -> bool:
	return Input.is_action_just_pressed("jump") if config.device_id < 0 else Input.is_joy_button_pressed(config.device_id, JOY_BUTTON_A)

static func jump_down(config: PlayerConfig) -> bool:
	return Input.is_action_pressed("jump") if config.device_id < 0 else Input.is_joy_button_pressed(config.device_id, JOY_BUTTON_A)

static func primary_down(config: PlayerConfig) -> bool:
	return Input.is_action_pressed("primary") if config.device_id < 0 else Input.is_joy_button_pressed(config.device_id, JOY_BUTTON_X)

static func secondary_down(config: PlayerConfig) -> bool:
	return Input.is_action_pressed("secondary") if config.device_id < 0 else Input.is_joy_button_pressed(config.device_id, JOY_BUTTON_B)

static func set_down(config: PlayerConfig) -> bool:
	return Input.is_action_pressed("set_ball") if config.device_id < 0 else Input.is_joy_button_pressed(config.device_id, JOY_BUTTON_Y)

static func dash_down(config: PlayerConfig) -> bool:
	return Input.is_action_pressed("dash") if config.device_id < 0 else (
		Input.is_joy_button_pressed(config.device_id, JOY_BUTTON_RIGHT_SHOULDER)
		or Input.get_joy_axis(config.device_id, JOY_AXIS_TRIGGER_RIGHT) > 0.35
	)

static func strafe_down(config: PlayerConfig) -> bool:
	return Input.is_action_pressed("strafe") if config.device_id < 0 else Input.is_joy_button_pressed(config.device_id, JOY_BUTTON_LEFT_SHOULDER)

static func connected_gamepads() -> PackedInt32Array:
	return Input.get_connected_joypads()

static func _joy_active(device_id: int) -> bool:
	var x := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	var y := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	return Vector2(x, y).length() >= DEADZONE

