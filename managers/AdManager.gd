# reviewed
extends Node

var saved_game_state_for_ad: Dictionary = {}
var ad_continue_used: bool              = false
var pause_disabled: bool                = false
var game_scene: Node                    = null



func initialize(scene: Node):
	game_scene       = scene
	ad_continue_used = false

	saved_game_state_for_ad.clear()

func is_ad_continue_used():
	return ad_continue_used


func set_pause_disabled(disabled: bool):
	pause_disabled = disabled


func is_pause_disabled():
	return pause_disabled


func save_game_state_for_ad(score: int, player_position: Vector2, last_bounce_score: int, initial_lives: int, lives_lost: int):
	var ball = game_scene.get_tree().get_first_node_in_group("ball")

	saved_game_state_for_ad = {
		"score":            score,
		"lives_lost":       lives_lost,
		"initial_lives":    initial_lives,
		"ball_position":    ball.position if ball else Vector2.ZERO,
		"ball_velocity":    ball.velocity if ball else Vector2.ZERO,
		"player_position":  player_position,
		"last_bounce_score": last_bounce_score
	}

	print("💾 Game state saved for ad continue")


func restore_game_state_from_ad():
	var restored = {
		"score"             : 0,
		"last_bounce_score" : 0,
		"lives_lost"        : 0,
		"initial_lives"     : 3,
		"ball_position"     : Vector2.ZERO,
		"ball_velocity"     : Vector2.ZERO,
		"player_position"   : Vector2.ZERO
	}

	if not saved_game_state_for_ad.is_empty():
		restored["score"]             = saved_game_state_for_ad.get("score", 0)
		restored["last_bounce_score"] = saved_game_state_for_ad.get("last_bounce_score", 0)
		restored["lives_lost"]        = saved_game_state_for_ad.get("lives_lost", 0)
		restored["initial_lives"]     = saved_game_state_for_ad.get("initial_lives", 3)
		restored["ball_position"]     = saved_game_state_for_ad.get("ball_position", Vector2.ZERO)
		restored["ball_velocity"]     = saved_game_state_for_ad.get("ball_velocity", Vector2.ZERO)
		restored["player_position"]   = saved_game_state_for_ad.get("player_position", Vector2.ZERO)

		saved_game_state_for_ad.clear()
		print("💾 Game state restored from ad continue")

	return restored

func show_ad_simulation():
	pause_disabled = true

	# Create ad screen container
	var ad_screen         = Control.new()
	ad_screen.name        = "AdScreen"
	ad_screen.z_index     = 150
	ad_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Black background
	var background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color.BLACK
	ad_screen.add_child(background)

	# Centered content container
	var center_container = CenterContainer.new()
	center_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ad_screen.add_child(center_container)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	center_container.add_child(vbox)

	# Ad title
	var ad_title                   = Label.new()
	ad_title.text                  = tr("ADVERTISEMENT")
	ad_title.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER

	ad_title.add_theme_color_override("font_color", Color.YELLOW)
	ad_title.add_theme_font_size_override("font_size", 36)

	# Ad content
	var ad_content                   = Label.new()
	ad_content.text                  = tr("AD_CONTENT")
	ad_content.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER

	ad_content.add_theme_color_override("font_color", Color.WHITE)
	ad_content.add_theme_font_size_override("font_size", 20)

	# Countdown timer
	var countdown_label                   = Label.new()
	countdown_label.text                  = tr("AD_ENDS_IN") + ": 5s"
	countdown_label.name                  = "CountdownLabel"
	countdown_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER

	countdown_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
	countdown_label.add_theme_font_size_override("font_size", 16)

	# Menu button
	var button_container = CenterContainer.new()
	var menu_button      = TextureButton.new()
	var ui_button_script = load("res://menus/widgets/UIButton.gd")

	menu_button.custom_minimum_size = Vector2(280, 60)
	menu_button.set_script(ui_button_script)
	menu_button.text = tr("BACK_TO_MENU")
	menu_button.pressed.connect(_on_ad_menu_pressed.bind(ad_screen))

	button_container.add_child(menu_button)

	# Build UI hierarchy
	vbox.add_child(ad_title)
	vbox.add_child(ad_content)
	vbox.add_child(countdown_label)
	vbox.add_child(button_container)

	game_scene.add_child(ad_screen)
	start_ad_countdown(ad_screen, countdown_label)

	print("📺 Ad simulation started (5 seconds)")

	return ad_screen


func start_ad_countdown(ad_screen: Control, countdown_label: Label):
	_run_countdown(ad_screen, countdown_label, 5)


func _run_countdown(ad_screen: Control, countdown_label: Label, countdown_remaining: int):
	if countdown_remaining > 0:
		# Update countdown display
		countdown_label.text = tr("AD_ENDS_IN") + ": " + str(countdown_remaining) + "s"

		# Schedule next second
		var timer       = Timer.new()
		timer.wait_time = 1.0
		timer.one_shot  = true

		timer.timeout.connect(func():
			timer.queue_free()
			_run_countdown(ad_screen, countdown_label, countdown_remaining - 1)
		)

		game_scene.add_child(timer)
		timer.start()
	else:
		# Ad finished
		countdown_label.text = tr("AD_FINISHED")

		# Resume game after 1 second
		var final_timer       = Timer.new()
		final_timer.wait_time = 1.0
		final_timer.one_shot  = true

		final_timer.timeout.connect(func():
			final_timer.queue_free()
			finish_ad_and_continue(ad_screen)
		)

		game_scene.add_child(final_timer)
		final_timer.start()


func finish_ad_and_continue(ad_screen: Control):
	ad_continue_used  = true
	ad_screen.queue_free()

	pause_disabled                  = false
	game_scene.get_tree().paused    = false

	# Signal GameScene to restore state
	if game_scene.has_method("restore_game_after_ad"):
		game_scene.restore_game_after_ad()


func _on_ad_menu_pressed(ad_screen: Control):
	ad_screen.queue_free()
	pause_disabled                  = false
	game_scene.get_tree().paused    = false

	GameManager.call_deferred("change_scene", "res://scenes/MainMenu.tscn")
