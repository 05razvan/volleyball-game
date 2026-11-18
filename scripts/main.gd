extends Control

const TITLE_COLOR := Color("f7f3e9")
const INK := Color("17253c")
const HOME := Color("48e88c")
const AWAY := Color("ff63c7")
const GOLD := Color("ffd166")

var game: VolleyballGame
var match_config: MatchConfig
var viewport_one: SubViewport
var viewport_two: SubViewport
var viewport_layout: HBoxContainer
var score_label: Label
var set_label: Label
var message_label: Label
var touch_label: Label
var meter_panels: Array[Dictionary] = []
var setup_team_size: OptionButton
var setup_humans: OptionButton
var setup_difficulty: HSlider
var controller_label: Label
var pause_overlay: Control
var results_overlay: Control
var setup_poll_timer := 0.0
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	set_process_unhandled_input(true)
	theme = _create_theme()
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	show_splash()

func _process(delta: float) -> void:
	if is_instance_valid(game):
		_update_meters()
	setup_poll_timer += delta
	if setup_poll_timer >= 0.35:
		setup_poll_timer = 0.0
		_update_controller_status()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and is_instance_valid(game) and not is_instance_valid(results_overlay):
		if is_instance_valid(pause_overlay):
			_resume_game()
		else:
			_show_pause()

func _create_theme() -> Theme:
	var value := Theme.new()
	value.default_font_size = 22
	value.set_color("font_color", "Label", TITLE_COLOR)
	value.set_color("font_color", "Button", TITLE_COLOR)
	value.set_color("font_hover_color", "Button", INK)
	value.set_color("font_pressed_color", "Button", INK)
	value.set_font_size("font_size", "Button", 22)
	value.set_font_size("font_size", "OptionButton", 20)
	return value

func _clear_screen() -> void:
	get_tree().paused = false
	game = null
	viewport_one = null
	viewport_two = null
	viewport_layout = null
	pause_overlay = null
	results_overlay = null
	meter_panels.clear()
	for child in get_children():
		if child != sfx_player:
			remove_child(child)
			child.queue_free()

func _add_background() -> void:
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("0d1830")
	add_child(background)
	var glow := Panel.new()
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow.position = Vector2(-420, -270)
	glow.size = Vector2(840, 540)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("172b4e")
	style.corner_radius_top_left = 70
	style.corner_radius_top_right = 70
	style.corner_radius_bottom_left = 70
	style.corner_radius_bottom_right = 70
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 24
	glow.add_theme_stylebox_override("panel", style)
	add_child(glow)

func show_splash() -> void:
	_clear_screen()
	_add_background()
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-340, -190)
	center.size = Vector2(680, 380)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 22)
	add_child(center)
	var kicker := _label("AN ORIGINAL ARCADE SPORTS GAME", 18, GOLD)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(kicker)
	var title := _label("SKYLINE\nVOLLEY", 76, TITLE_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("line_spacing", -18)
	center.add_child(title)
	var subtitle := _label("Read the court. Charge the jump. Choose your shot.", 22, Color("afbed2"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(subtitle)
	var start := _button("CLICK OR PRESS TO START", HOME)
	start.custom_minimum_size = Vector2(420, 62)
	start.pressed.connect(show_home)
	center.add_child(start)

func show_home() -> void:
	_clear_screen()
	_add_background()
	var shell := HBoxContainer.new()
	shell.set_anchors_preset(Control.PRESET_CENTER)
	shell.position = Vector2(-500, -280)
	shell.size = Vector2(1000, 560)
	shell.add_theme_constant_override("separation", 70)
	add_child(shell)
	var brand := VBoxContainer.new()
	brand.custom_minimum_size = Vector2(500, 520)
	brand.alignment = BoxContainer.ALIGNMENT_CENTER
	var eyebrow := _label("BROWSER EDITION  •  LOCAL PLAY", 18, GOLD)
	brand.add_child(eyebrow)
	var title := _label("SKYLINE\nVOLLEY", 86, TITLE_COLOR)
	title.add_theme_constant_override("line_spacing", -22)
	brand.add_child(title)
	var copy := _label("Manual movement and aim-driven touches make every rally yours.", 23, Color("afbed2"))
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.custom_minimum_size = Vector2(460, 70)
	brand.add_child(copy)
	shell.add_child(brand)
	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(350, 520)
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	menu.add_theme_constant_override("separation", 16)
	var play := _button("PLAY MATCH", HOME)
	play.pressed.connect(show_match_setup)
	menu.add_child(play)
	var practice := _button("OPEN GYM", GOLD)
	practice.pressed.connect(_start_practice)
	menu.add_child(practice)
	var how := _button("HOW TO PLAY", Color("6ca8ff"))
	how.pressed.connect(show_how_to_play)
	menu.add_child(how)
	var note := _label("1–2 local humans  •  1v1 / 2v2  •  bots", 17, Color("8192ab"))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu.add_child(note)
	shell.add_child(menu)

func show_match_setup() -> void:
	_clear_screen()
	_add_background()
	var card := _card(Vector2(720, 580))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-360, -290)
	add_child(card)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 38)
	content.add_theme_constant_override("separation", 16)
	card.add_child(content)
	var title := _label("MATCH SETUP", 42, TITLE_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	content.add_child(_label("FORMAT", 16, GOLD))
	setup_team_size = OptionButton.new()
	setup_team_size.add_item("1v1 — pure reads and reactions", 1)
	setup_team_size.add_item("2v2 — receive, set, attack", 2)
	setup_team_size.selected = 1
	setup_team_size.custom_minimum_size.y = 50
	content.add_child(setup_team_size)
	content.add_child(_label("LOCAL HUMANS", 16, GOLD))
	setup_humans = OptionButton.new()
	setup_humans.add_item("1 human + bots", 1)
	setup_humans.add_item("2 humans — controller required", 2)
	setup_humans.custom_minimum_size.y = 50
	content.add_child(setup_humans)
	controller_label = _label("", 16, Color("afbed2"))
	content.add_child(controller_label)
	content.add_child(_label("BOT DIFFICULTY", 16, GOLD))
	setup_difficulty = HSlider.new()
	setup_difficulty.min_value = 0.2
	setup_difficulty.max_value = 1.0
	setup_difficulty.step = 0.05
	setup_difficulty.value = 0.65
	setup_difficulty.custom_minimum_size.y = 34
	content.add_child(setup_difficulty)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 14)
	var back := _button("BACK", Color("52657f"))
	back.pressed.connect(show_home)
	actions.add_child(back)
	var begin := _button("TAKE THE COURT", HOME)
	begin.pressed.connect(_begin_configured_match)
	actions.add_child(begin)
	content.add_child(actions)
	_update_controller_status()

func _update_controller_status() -> void:
	if not is_instance_valid(controller_label):
		return
	var pads := InputRouter.connected_gamepads()
	if pads.is_empty():
		controller_label.text = "No gamepad detected. Press any gamepad button to activate it."
		controller_label.modulate = Color("ff9d9d")
	else:
		controller_label.text = "Gamepad ready: %s" % Input.get_joy_name(pads[0])
		controller_label.modulate = HOME

func _begin_configured_match() -> void:
	var humans := setup_humans.get_item_id(setup_humans.selected)
	if humans == 2 and InputRouter.connected_gamepads().is_empty():
		controller_label.text = "Connect a gamepad and press a button before starting two-player mode."
		controller_label.modulate = Color("ff9d9d")
		_play_tone(150.0, 0.12, 0.25)
		return
	var config := MatchConfig.new()
	config.team_size = setup_team_size.get_item_id(setup_team_size.selected)
	config.human_count = humans
	config.bot_difficulty = setup_difficulty.value
	_start_match(config)

func _start_practice() -> void:
	var config := MatchConfig.new()
	config.team_size = 1
	config.human_count = 1
	config.practice_mode = true
	config.infinite_stamina = true
	config.points_to_win = 99
	_start_match(config)

func _build_player_configs(config: MatchConfig) -> Array[PlayerConfig]:
	var configs: Array[PlayerConfig] = []
	var pads := InputRouter.connected_gamepads()
	configs.append(PlayerConfig.human(0, 0, -1))
	var slot := 1
	if config.human_count == 2:
		configs.append(PlayerConfig.human(slot, 1, pads[0]))
		slot += 1
	var team_counts := [1, 1 if config.human_count == 2 else 0]
	for team in [0, 1]:
		while team_counts[team] < config.team_size:
			configs.append(PlayerConfig.bot(slot, team, config.bot_difficulty))
			slot += 1
			team_counts[team] += 1
	return configs

func _start_match(config: MatchConfig) -> void:
	_clear_screen()
	match_config = config
	viewport_layout = HBoxContainer.new()
	viewport_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_layout.add_theme_constant_override("separation", 2)
	add_child(viewport_layout)
	viewport_one = _make_viewport_container(1280 if config.human_count == 1 else 640)
	viewport_layout.add_child(viewport_one.get_parent())
	game = VolleyballGame.new()
	viewport_one.add_child(game)
	game.setup(config, _build_player_configs(config))
	var camera_one := FollowCamera.new()
	camera_one.team = game.human_players[0].config.team
	camera_one.target = game.human_players[0]
	camera_one.ball = game.ball
	camera_one.current = true
	viewport_one.add_child(camera_one)
	game.human_players[0].camera = camera_one
	if config.human_count == 2:
		viewport_two = _make_viewport_container(640)
		viewport_two.world_3d = viewport_one.world_3d
		viewport_layout.add_child(viewport_two.get_parent())
		var camera_two := FollowCamera.new()
		camera_two.team = game.human_players[1].config.team
		camera_two.target = game.human_players[1]
		camera_two.ball = game.ball
		camera_two.current = true
		viewport_two.add_child(camera_two)
		game.human_players[1].camera = camera_two
	_build_hud()
	game.director.score_changed.connect(_on_score_changed)
	game.director.rally_message.connect(_on_rally_message)
	game.director.touches_changed.connect(_on_touches_changed)
	game.match_ended.connect(_on_match_ended)
	game.impact.connect(_on_impact)
	_on_score_changed(0, 0, 0, 0)

func _make_viewport_container(width: int) -> SubViewport:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	container.add_child(viewport)
	return viewport

func _build_hud() -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	var scoreboard := _card(Vector2(390, 86), Color(0.04, 0.07, 0.12, 0.9))
	scoreboard.set_anchors_preset(Control.PRESET_CENTER_TOP)
	scoreboard.position = Vector2(-195, 18)
	overlay.add_child(scoreboard)
	var score_row := HBoxContainer.new()
	score_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	score_row.alignment = BoxContainer.ALIGNMENT_CENTER
	score_row.add_theme_constant_override("separation", 18)
	scoreboard.add_child(score_row)
	var home_badge := _label("HOME", 15, INK)
	home_badge.add_theme_color_override("font_color", INK)
	var home_panel := _pill(home_badge, HOME)
	score_row.add_child(home_panel)
	score_label = _label("0  —  0", 34, TITLE_COLOR)
	score_row.add_child(score_label)
	var away_badge := _label("AWAY", 15, INK)
	var away_panel := _pill(away_badge, AWAY)
	score_row.add_child(away_panel)
	set_label = _label("SETS  0–0", 15, Color("afbed2"))
	set_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	set_label.position = Vector2(-50, 108)
	set_label.size = Vector2(100, 24)
	set_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(set_label)
	message_label = _label("", 28, TITLE_COLOR)
	message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	message_label.position = Vector2(-280, 142)
	message_label.size = Vector2(560, 44)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 2)
	overlay.add_child(message_label)
	touch_label = _label("○  ○  ○", 20, GOLD)
	touch_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	touch_label.position = Vector2(-90, 184)
	touch_label.size = Vector2(180, 30)
	touch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(touch_label)
	var meter_row := HBoxContainer.new()
	meter_row.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	meter_row.position.y = -114
	meter_row.size.y = 98
	meter_row.alignment = BoxContainer.ALIGNMENT_CENTER
	meter_row.add_theme_constant_override("separation", 28)
	overlay.add_child(meter_row)
	for player in game.human_players:
		var meter := _make_meter_panel(player.config.display_name, player.config.primary_color)
		meter_row.add_child(meter.panel)
		meter_panels.append({"player": player, "stamina": meter.stamina, "jump": meter.jump, "action": meter.action, "label": meter.label})
	var help := _label("WASD move  •  SPACE jump  •  CLICK receive/spike  •  E set  •  RMB dive/block  •  ESC pause", 14, Color("e8edf5"))
	help.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	help.position.y = -26
	help.size.y = 22
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay.add_child(help)

func _make_meter_panel(player_name: String, color: Color) -> Dictionary:
	var panel := _card(Vector2(370, 92), Color(0.04, 0.07, 0.12, 0.86))
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	content.add_theme_constant_override("separation", 3)
	panel.add_child(content)
	var label := _label(player_name + "  •  READY", 15, color)
	content.add_child(label)
	var stamina := _progress(color)
	var jump := _progress(GOLD)
	var action := _progress(Color("6ca8ff"))
	content.add_child(stamina)
	content.add_child(jump)
	content.add_child(action)
	return {"panel": panel, "stamina": stamina, "jump": jump, "action": action, "label": label}

func _update_meters() -> void:
	for meter in meter_panels:
		var player: VolleyPlayer = meter.player
		meter.stamina.value = player.stamina / player.tuning.stamina_max * 100.0
		meter.jump.value = clampf(player.jump_hold / player.tuning.jump_charge_time, 0.0, 1.0) * 100.0
		var action_value := maxf(player.spike_charge, player.set_charge)
		meter.action.value = action_value * 100.0
		var action_name := "SPIKE" if player.spike_charge > 0.0 else "SET" if player.set_charge > 0.0 else "READY"
		meter.label.text = "%s  •  %s" % [player.config.display_name, action_name]

func _on_score_changed(home_score: int, away_score: int, home_sets: int, away_sets: int) -> void:
	if is_instance_valid(score_label):
		score_label.text = "%d  —  %d" % [home_score, away_score]
		set_label.text = "SETS  %d–%d" % [home_sets, away_sets]

func _on_rally_message(text: String, color: Color) -> void:
	if is_instance_valid(message_label):
		message_label.text = text
		message_label.modulate = color
		var tween := create_tween()
		message_label.modulate.a = 1.0
		tween.tween_interval(1.0)
		tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	_play_tone(460.0 if color == HOME else 350.0, 0.1, 0.18)

func _on_touches_changed(team: int, touches: int, _last_player: int) -> void:
	if is_instance_valid(touch_label):
		var dots := []
		for index in range(3):
			dots.append("●" if index < touches else "○")
		touch_label.text = "%s  %s" % ["HOME" if team == 0 else "AWAY", "  ".join(dots)]
		touch_label.modulate = HOME if team == 0 else AWAY

func _on_impact(strength: float) -> void:
	_play_tone(lerpf(220.0, 105.0, strength), 0.045 + strength * 0.04, 0.12 + strength * 0.18)
	for viewport in [viewport_one, viewport_two]:
		if is_instance_valid(viewport):
			var active_camera := viewport.get_camera_3d()
			if active_camera is FollowCamera:
				active_camera.punch(strength * 0.025)

func _on_match_ended(winning_team: int) -> void:
	get_tree().paused = true
	results_overlay = _modal_overlay()
	add_child(results_overlay)
	var card := _card(Vector2(520, 390))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-260, -195)
	results_overlay.add_child(card)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 34)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	card.add_child(content)
	var kicker := _label("MATCH COMPLETE", 18, GOLD)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(kicker)
	var title := _label("%s WINS" % ("HOME" if winning_team == 0 else "AWAY"), 54, HOME if winning_team == 0 else AWAY)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var rematch := _button("REMATCH", HOME)
	rematch.pressed.connect(_rematch)
	content.add_child(rematch)
	var menu := _button("MAIN MENU", Color("52657f"))
	menu.pressed.connect(show_home)
	content.add_child(menu)

func _show_pause() -> void:
	get_tree().paused = true
	pause_overlay = _modal_overlay()
	add_child(pause_overlay)
	var card := _card(Vector2(440, 360))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-220, -180)
	pause_overlay.add_child(card)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 34)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(_label("PAUSED", 48, TITLE_COLOR))
	var resume := _button("RESUME", HOME)
	resume.pressed.connect(_resume_game)
	content.add_child(resume)
	var restart := _button("RESTART", GOLD)
	restart.pressed.connect(_rematch)
	content.add_child(restart)
	var menu := _button("MAIN MENU", Color("52657f"))
	menu.pressed.connect(show_home)
	content.add_child(menu)
	card.add_child(content)

func _resume_game() -> void:
	if is_instance_valid(pause_overlay):
		pause_overlay.queue_free()
	pause_overlay = null
	get_tree().paused = false

func _rematch() -> void:
	var config := match_config.duplicate_config()
	get_tree().paused = false
	_start_match(config)

func show_how_to_play() -> void:
	_clear_screen()
	_add_background()
	var card := _card(Vector2(930, 600))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-465, -300)
	add_child(card)
	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 34)
	content.add_theme_constant_override("separation", 13)
	card.add_child(content)
	var title := _label("THE WHOLE COURT IS YOUR CONTROLLER", 38, TITLE_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var guide := _label("MOVE + AIM\nWASD moves your player while the mouse selects a landing point. Hold Shift to keep facing your target.\n\nBUILD THE PLAY\nLeft click receives. Hold E to shape a set: nearby charged sets rise higher; distant charged sets travel faster.\n\nCHARGE THE ATTACK\nHold Space and release to jump. A full meter opens a brief perfect window. Hold left click in the air, aim, then release to spike. Your approach changes the shot.\n\nSAVE THE RALLY\nRight click dives on the floor and blocks in the air. Dash and dives consume stamina. Each side gets three touches; blocks are free.", 20, Color("c5d0df"))
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.custom_minimum_size = Vector2(850, 390)
	content.add_child(guide)
	var back := _button("GOT IT", HOME)
	back.pressed.connect(show_home)
	content.add_child(back)

func _modal_overlay() -> ColorRect:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.02, 0.035, 0.07, 0.82)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	return overlay

func _card(size_value: Vector2, color: Color = Color("172b4e")) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = size_value
	panel.size = size_value
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1, 1, 1, 0.08)
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 18
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _button(text_value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(330, 56)
	var normal := StyleBoxFlat.new()
	normal.bg_color = color.darkened(0.45)
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.border_color = color
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = color
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	return button

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _pill(content: Control, color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(content)
	return panel

func _progress(color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(340, 13)
	var background := StyleBoxFlat.new()
	background.bg_color = Color(1, 1, 1, 0.12)
	background.corner_radius_top_left = 6
	background.corner_radius_top_right = 6
	background.corner_radius_bottom_left = 6
	background.corner_radius_bottom_right = 6
	var fill: StyleBoxFlat = background.duplicate()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _play_tone(frequency: float, duration: float, volume: float) -> void:
	var sample_rate := 11025
	var frame_count := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(frame_count)
	for index in range(frame_count):
		var envelope := 1.0 - float(index) / float(frame_count)
		var wave := sin(TAU * frequency * float(index) / float(sample_rate))
		data[index] = int(clampf(128.0 + wave * envelope * volume * 127.0, 0.0, 255.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	sfx_player.stream = stream
	sfx_player.play()

