class_name GameplayTuning
extends Resource

@export_group("Movement")
@export var walk_speed := 5.2
@export var dash_speed := 8.4
@export var ground_acceleration := 24.0
@export var air_acceleration := 7.0
@export var braking := 30.0
@export var gravity := 18.0
@export var dive_speed := 10.5
@export var dive_duration := 0.42
@export var exhausted_recovery := 2.2

@export_group("Jump")
@export var jump_charge_time := 0.72
@export var jump_min_speed := 6.4
@export var jump_max_speed := 10.1
@export var perfect_window := 0.16
@export var perfect_jump_speed := 12.4

@export_group("Ball Actions")
@export var contact_radius := 1.28
@export var receive_height := 5.2
@export var receive_time := 1.05
@export var set_charge_time := 0.75
@export var spike_charge_time := 0.62
@export var spike_min_speed := 11.0
@export var spike_max_speed := 23.0
@export var block_radius := 1.05

@export_group("Stamina")
@export var stamina_max := 100.0
@export var stamina_regen := 25.0
@export var dash_drain := 28.0
@export var dive_cost := 38.0

