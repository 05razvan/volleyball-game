class_name PlayerConfig
extends Resource

@export var slot: int = 0
@export var device_id: int = -1
@export var is_human: bool = true
@export var team: int = 0
@export var bot_difficulty: float = 0.65
@export var display_name: String = "Player"
@export var primary_color: Color = Color("3ce381")
@export var accent_color: Color = Color("11253e")

static func human(player_slot: int, player_team: int, joy_id: int = -1) -> PlayerConfig:
	var config := PlayerConfig.new()
	config.slot = player_slot
	config.device_id = joy_id
	config.is_human = true
	config.team = player_team
	config.display_name = "P%d" % (player_slot + 1)
	config.primary_color = Color("48e88c") if player_team == 0 else Color("ff63c7")
	return config

static func bot(player_slot: int, player_team: int, difficulty: float = 0.65) -> PlayerConfig:
	var config := PlayerConfig.new()
	config.slot = player_slot
	config.device_id = -2
	config.is_human = false
	config.team = player_team
	config.bot_difficulty = difficulty
	config.display_name = "BOT %d" % (player_slot + 1)
	config.primary_color = Color("48e88c") if player_team == 0 else Color("ff63c7")
	return config

