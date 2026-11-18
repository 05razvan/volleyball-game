class_name MatchDirector
extends Node

signal score_changed(home: int, away: int, home_sets: int, away_sets: int)
signal touches_changed(team: int, touches: int, last_player: int)
signal rally_message(text: String, color: Color)
signal rally_reset(serving_team: int)
signal match_finished(winning_team: int)

enum Phase { SERVE_READY, RALLY, POINT_PAUSE, MATCH_OVER, PRACTICE }

var config: MatchConfig
var phase := Phase.SERVE_READY
var score := [0, 0]
var sets := [0, 0]
var touches := [0, 0]
var last_touch_player := [-1, -1]
var serving_team := 0
var last_touch_team := -1
var reset_timer := 0.0
var winning_team := -1

func setup(match_config: MatchConfig) -> void:
	config = match_config
	phase = Phase.PRACTICE if config.practice_mode else Phase.SERVE_READY
	score = [0, 0]
	sets = [0, 0]
	touches = [0, 0]
	last_touch_player = [-1, -1]
	serving_team = 0
	winning_team = -1

func _physics_process(delta: float) -> void:
	if phase == Phase.POINT_PAUSE:
		reset_timer -= delta
		if reset_timer <= 0.0:
			begin_next_rally()

func start_serve() -> void:
	if phase == Phase.SERVE_READY:
		phase = Phase.RALLY
		rally_message.emit("SERVE!", Color("ffffff"))

func register_touch(team: int, player_id: int, is_block: bool = false) -> bool:
	if phase == Phase.PRACTICE:
		last_touch_team = team
		return true
	if phase != Phase.RALLY and phase != Phase.SERVE_READY:
		return false
	if phase == Phase.SERVE_READY:
		start_serve()
	if is_block:
		last_touch_team = team
		touches[1 - team] = 0
		last_touch_player[1 - team] = -1
		touches_changed.emit(team, touches[team], player_id)
		return true
	if last_touch_team != team:
		touches[team] = 0
		last_touch_player[team] = -1
		touches[1 - team] = 0
		last_touch_player[1 - team] = -1
	if config.team_size > 1 and last_touch_player[team] == player_id:
		award_point(1 - team, "DOUBLE TOUCH")
		return false
	touches[team] += 1
	last_touch_player[team] = player_id
	last_touch_team = team
	touches_changed.emit(team, touches[team], player_id)
	if touches[team] > 3:
		award_point(1 - team, "FOUR TOUCHES")
		return false
	return true

func ball_landed(position: Vector3) -> void:
	if phase == Phase.PRACTICE:
		rally_message.emit("BALL DOWN — R TO RECALL", Color("ffd166"))
		return
	if phase != Phase.RALLY:
		return
	var inside_width := absf(position.x) <= 4.5
	var inside_length := absf(position.z) <= 9.0
	if not inside_width or not inside_length:
		var point_team := 1 - last_touch_team if last_touch_team >= 0 else 1 - serving_team
		award_point(point_team, "OUT")
		return
	var landed_team := 0 if position.z > 0.0 else 1
	award_point(1 - landed_team, "BALL DOWN")

func player_invaded(team: int) -> void:
	if phase == Phase.RALLY:
		award_point(1 - team, "COURT INVASION")

func award_point(team: int, reason: String) -> void:
	if phase == Phase.POINT_PAUSE or phase == Phase.MATCH_OVER:
		return
	score[team] += 1
	serving_team = team
	phase = Phase.POINT_PAUSE
	reset_timer = 1.65
	rally_message.emit("%s  •  %s" % ["HOME" if team == 0 else "AWAY", reason], Color("48e88c") if team == 0 else Color("ff63c7"))
	if _set_is_won(team):
		sets[team] += 1
		rally_message.emit("%s WINS THE SET" % ("HOME" if team == 0 else "AWAY"), Color("ffffff"))
		if sets[team] >= config.sets_to_win:
			winning_team = team
			phase = Phase.MATCH_OVER
			match_finished.emit(team)
		else:
			score = [0, 0]
	score_changed.emit(score[0], score[1], sets[0], sets[1])

func _set_is_won(team: int) -> bool:
	if score[team] < config.points_to_win:
		return false
	return not config.win_by_two or score[team] - score[1 - team] >= 2

func begin_next_rally() -> void:
	touches = [0, 0]
	last_touch_player = [-1, -1]
	last_touch_team = -1
	phase = Phase.SERVE_READY
	touches_changed.emit(0, 0, -1)
	touches_changed.emit(1, 0, -1)
	rally_reset.emit(serving_team)

func reset_match() -> void:
	setup(config)
	score_changed.emit(0, 0, 0, 0)
	rally_reset.emit(serving_team)

