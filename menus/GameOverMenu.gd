# reviewed
extends Control

signal replay_requested
signal ranking_requested
signal menu_requested
signal last_chance_requested

var score: int              = 0
var is_high_score: bool     = false
var player_rank: int        = 0
var game_stats: Dictionary  = {}
var ad_continue_used: bool  = false

func _ready():
	z_index = 100
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

	# Reduce music volume when game over screen appears
	AudioManager.reduce_music_for_overlay()


# Restore music when exiting the game over screen
func _exit_tree():
	AudioManager.restore_music_after_overlay()
	print("✅ GameOverMenu closed - music restored")

func setup(p_score: int, p_is_high_score: bool, p_player_rank: int, p_game_stats: Dictionary, p_ad_used: bool):
	# Init
	score            = p_score
	is_high_score    = p_is_high_score
	player_rank      = p_player_rank
	game_stats       = p_game_stats
	ad_continue_used = p_ad_used

func _build_ui():
	# Semi-transparent background
	var background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0, 0, 0, 0.8)
	add_child(background)

	# Centered container
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 200)
	center_container.add_child(vbox)

	# Title (same style as OptionsMenu)
	var title_label = Label.new()
	if is_high_score:
		title_label.text = tr("NEW_RECORD")
	else:
		title_label.text = tr("GAME_OVER")

	title_label.add_theme_font_size_override("font_size", 56)
	title_label.add_theme_color_override("font_color", Color.GOLD)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Base score
	var score_label_go = Label.new()
	score_label_go.text = tr("SCORE") + ": " + str(score)
	score_label_go.add_theme_font_size_override("font_size", 24)
	score_label_go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label_go.add_theme_color_override("font_color", Color.WHITE)

	# Time bonus
	var time_bonus_label = Label.new()
	var time_bonus = game_stats.get("time_bonus", 0)
	var duration = game_stats.get("game_duration_seconds", 0)
	time_bonus_label.text = tr("TIME_BONUS") + ": +" + str(time_bonus) + " (" + str(duration) + "s)"
	time_bonus_label.add_theme_font_size_override("font_size", 18)
	time_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_bonus_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)

	# Final score
	var final_score_label = Label.new()
	var final_score = score + time_bonus
	final_score_label.text = tr("FINAL_SCORE") + ": " + str(final_score)
	final_score_label.add_theme_font_size_override("font_size", 28)
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_score_label.add_theme_color_override("font_color", Color.GOLD)

	# Lives statistics (display only lives used, not the fraction)
	var lives_stats_label = Label.new()
	var lives_used        = game_stats.get("lives_used", 0)

	lives_stats_label.text = tr("LIVES_USED") + ": " + str(lives_used)
	lives_stats_label.add_theme_font_size_override("font_size", 16)
	lives_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lives_stats_label.add_theme_color_override("font_color", Color.LIGHT_BLUE)

	# Player rank (only create if in top 10)
	var rank_label: Label = null
	if player_rank > 0:
		rank_label = Label.new()
		rank_label.text = tr("POSITION") + ": " + str(player_rank)
		rank_label.add_theme_color_override("font_color", Color.GOLD if player_rank == 1 else Color.CYAN)
		rank_label.add_theme_font_size_override("font_size", 18)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Spacers
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.y = 30

	var spacer2 = Control.new()
	spacer2.custom_minimum_size.y = 40

	var spacer_mini = Control.new()
	spacer_mini.custom_minimum_size.y = 10

	# Button container
	var button_center_container = CenterContainer.new()
	var button_vbox             = VBoxContainer.new()
	button_vbox.add_theme_constant_override("separation", 15)

	# Load UIButton script
	var ui_button_script = preload("res://menus/widgets/UIButton.gd")

	# "Last chance" button if ad not used
	if not ad_continue_used:
		var last_chance_button = TextureButton.new()
		last_chance_button.custom_minimum_size = Vector2(280, 50)
		last_chance_button.set_script(ui_button_script)
		last_chance_button.text = "🎬 " + tr("LAST_CHANCE_AD")
		last_chance_button.pressed.connect(_on_last_chance_pressed)
		button_vbox.add_child(last_chance_button)

		# Pulsation effect
		var tween = create_tween()
		tween.set_loops(10)
		tween.tween_property(last_chance_button, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.6)
		tween.tween_property(last_chance_button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6)

	# Replay button
	var replay_button = TextureButton.new()
	replay_button.custom_minimum_size = Vector2(250, 50)
	replay_button.set_script(ui_button_script)
	replay_button.text = tr("REPLAY")
	replay_button.pressed.connect(_on_replay_pressed)
	button_vbox.add_child(replay_button)

	# Other buttons (horizontal)
	var button_hbox = HBoxContainer.new()
	button_hbox.add_theme_constant_override("separation", 20)

	var ranking_button = TextureButton.new()
	ranking_button.custom_minimum_size = Vector2(180, 50)
	ranking_button.set_script(ui_button_script)
	ranking_button.text = tr("RANKING_TITLE")
	ranking_button.pressed.connect(_on_ranking_pressed)
	button_hbox.add_child(ranking_button)

	var continue_button = TextureButton.new()
	continue_button.custom_minimum_size = Vector2(180, 50)
	continue_button.set_script(ui_button_script)
	continue_button.text = tr("MENU")
	continue_button.pressed.connect(_on_menu_pressed)
	button_hbox.add_child(continue_button)

	button_vbox.add_child(button_hbox)

	button_center_container.add_child(button_vbox)

	# Assemble layout
	vbox.add_child(title_label)
	vbox.add_child(spacer1)
	vbox.add_child(score_label_go)
	vbox.add_child(time_bonus_label)
	vbox.add_child(final_score_label)
	vbox.add_child(spacer_mini)
	vbox.add_child(lives_stats_label)

	if rank_label:
		vbox.add_child(rank_label)

	vbox.add_child(spacer2)
	vbox.add_child(button_center_container)

	# Add confetti animation for first place
	if player_rank == 1:
		print("🎉 Rank 1 detected, launching confetti animation!")
		AnimationManager.animate_victory_confetti(self)

func _on_replay_pressed():
	emit_signal("replay_requested")

func _on_ranking_pressed():
	emit_signal("ranking_requested")

func _on_menu_pressed():
	emit_signal("menu_requested")

func _on_last_chance_pressed():
	emit_signal("last_chance_requested")
