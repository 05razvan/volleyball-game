class_name MatchConfig
extends Resource

@export_range(1, 2) var team_size: int = 1
@export_range(1, 2) var human_count: int = 1
@export var points_to_win: int = 15
@export var sets_to_win: int = 2
@export var win_by_two: bool = true
@export var teammate_collisions: bool = true
@export var show_ball_indicator: bool = true
@export var practice_mode: bool = false
@export var infinite_stamina: bool = false
@export_range(0.0, 1.0) var bot_difficulty: float = 0.65

func duplicate_config() -> MatchConfig:
	var copy := MatchConfig.new()
	copy.team_size = team_size
	copy.human_count = human_count
	copy.points_to_win = points_to_win
	copy.sets_to_win = sets_to_win
	copy.win_by_two = win_by_two
	copy.teammate_collisions = teammate_collisions
	copy.show_ball_indicator = show_ball_indicator
	copy.practice_mode = practice_mode
	copy.infinite_stamina = infinite_stamina
	copy.bot_difficulty = bot_difficulty
	return copy

