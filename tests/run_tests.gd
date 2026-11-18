extends SceneTree

var failures := 0

func _init() -> void:
	print("Running Skyline Volley tests…")
	_test_match_defaults()
	_test_rally_scoring()
	_test_win_by_two()
	_test_touch_rules()
	_test_ball_targeting()
	if failures == 0:
		print("All tests passed.")
		quit(0)
	else:
		push_error("%d test(s) failed." % failures)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("  PASS  ", message)
	else:
		failures += 1
		push_error("  FAIL  " + message)

func _test_match_defaults() -> void:
	var config := MatchConfig.new()
	_expect(config.points_to_win == 15, "matches default to 15 points")
	_expect(config.sets_to_win == 2, "matches default to best of three")
	_expect(config.win_by_two, "sets require a two-point lead")

func _test_rally_scoring() -> void:
	var director := MatchDirector.new()
	var config := MatchConfig.new()
	director.setup(config)
	director.phase = MatchDirector.Phase.RALLY
	director.last_touch_team = 0
	director.ball_landed(Vector3(0.0, 0.19, -4.0))
	_expect(director.score[0] == 1, "ball down awards the opposite side")
	_expect(director.serving_team == 0, "point winner gains serve")

func _test_win_by_two() -> void:
	var director := MatchDirector.new()
	var config := MatchConfig.new()
	config.points_to_win = 3
	director.setup(config)
	director.score = [3, 2]
	_expect(not director._set_is_won(0), "one-point lead does not win at deuce")
	director.score = [4, 2]
	_expect(director._set_is_won(0), "two-point lead wins after deuce")

func _test_touch_rules() -> void:
	var director := MatchDirector.new()
	var config := MatchConfig.new()
	config.team_size = 2
	director.setup(config)
	director.phase = MatchDirector.Phase.RALLY
	_expect(director.register_touch(0, 0), "first touch is legal")
	_expect(not director.register_touch(0, 0), "consecutive touch faults in 2v2")
	var solo := MatchDirector.new()
	var solo_config := MatchConfig.new()
	solo_config.team_size = 1
	solo.setup(solo_config)
	solo.phase = MatchDirector.Phase.RALLY
	_expect(solo.register_touch(0, 0) and solo.register_touch(0, 0), "consecutive touches are legal in 1v1")
	var block_test := MatchDirector.new()
	block_test.setup(config)
	block_test.phase = MatchDirector.Phase.RALLY
	block_test.register_touch(0, 0, true)
	_expect(block_test.touches[0] == 0, "blocks do not consume a touch")

func _test_ball_targeting() -> void:
	var ball := VolleyBall.new()
	ball.global_position = Vector3(0.0, 1.0, 0.0)
	var velocity := ball.target_velocity(Vector3(2.0, 0.2, -4.0), 1.0)
	_expect(is_equal_approx(velocity.x, 2.0), "ball targeting solves horizontal X velocity")
	_expect(is_equal_approx(velocity.z, -4.0), "ball targeting solves horizontal Z velocity")
	_expect(velocity.y > 0.0, "ball targeting adds a gravity-compensating arc")

