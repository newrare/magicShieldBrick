# reviewed
extends Control

@onready var player_area		= $GameArea/PlayerContainer
@onready var score_label		= $UI/ScoreLabel
@onready var lives_container	= $UI/LivesContainer
@onready var pause_button		= $UI/PauseButton
@onready var pause_menu			= $UI/PauseMenu

var hearts: 		Array[Control] 	= []
var life_display:	int 			= 3
var life_lost: 		int 			= 0

var player_script
var game_over_screen		= null
var is_paused				= false
var is_pause_enabled		= true
var pause_cooldown_time		= 0.2
var score					= 0
var last_pause_time			= 0



func _ready():
	add_to_group("game_scene")

	# Initialize hearts array dynamically from LivesContainer children
	hearts.clear()
	for child in lives_container.get_children():
		if child is Control:
			hearts.append(child)

	# Check and use bonus life if available
	if BonusLifeManager and BonusLifeManager.use_bonus_life():
		life_display = 4
		_create_additional_heart()

	# Start statistics tracking
	GameStatsManager.start_game(life_display)

	# Setup scene elements
	setup_background()
	player_area.add_to_group("player")
	setup_player()

	# Connect signals
	player_area.body_entered.connect(_on_player_hit)
	pause_button.pressed.connect(_on_pause_pressed)

	# Configure pause button
	pause_button.text					= tr("PAUSE")
	pause_button.custom_minimum_size	= Vector2(60, 30)

	pause_button.add_theme_font_size_override("font_size", 14)

	# Configure pause menu
	if pause_menu:
		pause_menu.visible = false

	# Initialize ScoreManager for this game
	ScoreManager.load_scores()
	ScoreManager.start_game()
	ScoreManager.milestone_crossed.connect(_on_milestone_crossed)

	# Initialize managers (all are autoloads)
	UIManager.initialize(hearts, score_label, player_area)
	UIManager.update_lives_display(life_display)

	PowerUpManager.initialize(self)
	AdManager.initialize(self)
	BallSpawner.initialize(self)

	center_player()

	# Restore pause state if returning from OptionsMenu
	if GameManager.get_was_paused():
		call_deferred("restore_pause_state")


# Called when score milestone is crossed
func _on_milestone_crossed(level: int, milestones_crossed: int):
	increase_ball_speed_for_milestone()


func _exit_tree():
	# Clean up animation timers to prevent lambda errors
	AnimationManager.cleanup_timers()

	# Clean up managers
	PowerUpManager.cleanup()

	# Disconnect signals to prevent memory leaks
	if player_area and player_area.body_entered.is_connected(_on_player_hit):
		player_area.body_entered.disconnect(_on_player_hit)

	if pause_button and pause_button.pressed.is_connected(_on_pause_pressed):
		pause_button.pressed.disconnect(_on_pause_pressed)


func setup_background():
	# Set base color for existing background
	var existing_background = get_node("Background")

	if existing_background:
		existing_background.color = Color(0.1, 0.1, 0.2, 1.0)

	# Load and add background image
	var background_texture = load("res://assets/images/background.png")

	if background_texture:
		var background_sprite			= TextureRect.new()
		background_sprite.texture		= background_texture
		background_sprite.name			= "GameBackgroundImage"
		background_sprite.stretch_mode	= TextureRect.STRETCH_KEEP_ASPECT_COVERED

		background_sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(background_sprite)
		move_child(background_sprite, 1)


func center_player():
	var screen_size			= get_viewport().get_visible_rect().size
	player_area.position	= Vector2(screen_size.x / 2, screen_size.y / 2)


# Create an additional heart dynamically
func _create_additional_heart():
	if hearts.is_empty() or not lives_container:
		return

	var reference_heart = hearts[0]  # Use first heart as template

	# Create heart as TextureRect with same properties as reference
	var new_heart                 = TextureRect.new()
	new_heart.texture             = reference_heart.texture
	new_heart.custom_minimum_size = reference_heart.custom_minimum_size
	new_heart.expand_mode         = reference_heart.expand_mode
	new_heart.stretch_mode        = reference_heart.stretch_mode
	new_heart.name                = "Heart%d" % (hearts.size() + 1)

	lives_container.add_child(new_heart)
	hearts.append(new_heart)
	UIManager.add_heart(new_heart)


func get_player_position():
	return player_area.global_position


func _on_player_hit(body):
	# Check if body is a ball (check if it's in the ball group or has ball methods)
	if body.is_in_group("ball") or body.has_method("bounce_off_player"):
		# Check if it's a bonus ball
		if body.has_method("is_bonus") and body.is_bonus():
			# Play sound effect
			AudioManager.play_sfx_button_click()

			# Create explosion effect before destroying
			var game_area = get_node_or_null("GameArea")
			if game_area:
				AnimationManager.create_bonus_ball_explosion(body.global_position, game_area)

			# Bonus ball disappears without damage
			body.queue_free()
			return

		# Bounce ball off player
		if body.has_method("bounce_off_player"):
			body.bounce_off_player(player_area.global_position)

		call_deferred("player_hit")


func player_hit():
	# Check invincibility state
	if player_script and player_script.has_method("is_invincible") and player_script.is_invincible():
		return

	# Play damage effects IMMEDIATELY
	AudioManager.play_sfx_player()
	screen_shake()

	# Activate hurt state IMMEDIATELY (invincibility period + visual feedback)
	if player_script and player_script.has_method("set_hurt"):
		player_script.set_hurt()

	# Update game state
	var life_before_hit = life_display - life_lost

	life_lost += 1

	var life_remaining = life_display - life_lost

	GameStatsManager.record_life_lost()

	# Game Over
	if life_remaining <= 0:
		UIManager.update_lives_display(0)
		start_death_effect_early()

		# need wait for dramatic effect before Game Over screen
		for i in range(120):
			await get_tree().process_frame  # Wait ~ 1s (120 frames at 60fps)

		finish_game_over()
	else:
		UIManager.heart_loss(life_before_hit)


func screen_shake():
	# Delegate animation to AnimationManager
	AnimationManager.animate_shake(self, 15.0, 0.3, 8)


func add_score(points):
	score += points
	ScoreManager.add_points(points)


func get_score():
	return score


func increase_ball_speed_for_milestone():
	var ball = get_tree().get_first_node_in_group("ball")

	if ball and ball.has_method("increase_speed_for_milestone"):
		ball.increase_speed_for_milestone()


func ball_hit_wall():
	var points = ScoreManager.get_wall_points()
	add_score(points)


func ball_hit_shield():
	add_score(100)

	# Increment shield hit counter and spawn bonus ball every 5 hits
	BallSpawner.increment_shield_hit_counter()


func setup_player():
	var script_resource = load("res://objects/Player.gd")

	if script_resource:
		player_area.set_script(script_resource)
		player_script = player_area

		if player_script and player_script.has_method("_ready"):
			player_script._ready()


func _on_pause_pressed():
	toggle_pause()


func toggle_pause():
	# Check pause cooldown
	var current_time_ms	= Time.get_ticks_msec()
	var cooldown_ms		= pause_cooldown_time * 1000.0

	if current_time_ms - last_pause_time < cooldown_ms:
		return

	# Toggle pause state
	last_pause_time		= current_time_ms
	is_paused			= !is_paused
	get_tree().paused	= is_paused

	# Update audio based on pause state
	#if !is_paused:
		# Unpause: restore music state from user settings (don't force unmute)
		#AudioManager.update_music_state(AudioManager.is_music_muted)

	# Update pause menu visibility
	if pause_menu:
		pause_menu.visible = is_paused


func set_pause_state(paused: bool):
	is_paused			= paused
	get_tree().paused	= is_paused

	if pause_menu:
		pause_menu.visible = is_paused


func restore_pause_state():
	if not GameManager.saved_game_state.is_empty():
		GameManager.restore_game_state(self)
	else:
		is_paused			= true
		get_tree().paused	= true

		# Restore music state from user settings (don't force unmute)
		AudioManager.update_music_state(AudioManager.is_music_muted)

		if pause_menu:
			pause_menu.visible = true

		GameManager.clear_was_paused()


func _input(event):
	if AdManager.is_pause_disabled() or not is_pause_enabled:
		return

	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
	elif event is InputEventKey and event.keycode == KEY_SPACE and event.pressed and not event.echo:
		toggle_pause()


func restore_game_after_ad():
	var restored = AdManager.restore_game_state_from_ad()

	# Restore game values
	score = restored["score"]

	ScoreManager.set_score(score)
	ScoreManager.update_last_milestone_score(restored["last_bounce_score"])

	# Restore positions
	var ball = get_tree().get_first_node_in_group("ball")

	if ball:
		ball.position = restored["ball_position"]
		ball.velocity = restored["ball_velocity"]

	if player_area:
		player_area.position = restored["player_position"]

	# Update life display
	UIManager.update_lives_display(1)

	# Restore pause
	if pause_button:
		pause_button.visible 	= true
		pause_button.disabled 	= false

	is_pause_enabled = true
	AdManager.set_pause_disabled(false)
	get_tree().paused = false



# Calculate scores and show game over screen (called after await)
func finish_game_over():
	# Hide pause button
	if pause_button:
		pause_button.visible = false

	# Calculate final stats using lives_lost (total hits taken)
	var game_stats		= GameStatsManager.end_game()
	var final_score		= ScoreManager.calculate_final_score(score, game_stats.time_bonus)
	var is_high_score	= false
	var player_rank		= 0

	if ScoreManager:
		is_high_score = ScoreManager.is_new_high_score(final_score)
		player_rank   = ScoreManager.get_rank_preview(final_score)

	# Cleanup death effect (restore time scale and remove overlay)
	AnimationManager.cleanup_death_effect(self)

	get_tree().paused = true
	show_game_over_screen(is_high_score, player_rank, game_stats)

# Start death effect early (visual only, no score calculation)
func start_death_effect_early():
	# Disable pause button and space key
	is_pause_enabled = false

	if pause_button:
		pause_button.disabled = true

	# Delegate animation to AnimationManager
	AnimationManager.animate_death_effect(self)

func show_game_over_screen(is_high_score: bool = false, player_rank: int = 0, game_stats: Dictionary = {}):
	AdManager.set_pause_disabled(true)

	# Save final score to ranking
	var final_score	= ScoreManager.calculate_final_score(score, game_stats.time_bonus)

	if ScoreManager:
		ScoreManager.add_score(score, game_stats.lives_used, game_stats.time_bonus, game_stats.initial_lives)

	# Play game over sound
	var is_top3 = player_rank > 0 and player_rank <= 3
	AudioManager.play_game_over(is_top3)

	# Create and setup game over menu
	var game_over_scene		= preload("res://scenes/GameOverMenu.tscn")
	var game_over_instance	= game_over_scene.instantiate()

	game_over_instance.setup(score, is_high_score, player_rank, game_stats, AdManager.is_ad_continue_used())

	# Connect signals
	game_over_instance.replay_requested.connect(_on_replay_game)
	game_over_instance.ranking_requested.connect(_on_show_ranking)
	game_over_instance.menu_requested.connect(_on_game_over_continue)
	game_over_instance.last_chance_requested.connect(_on_last_chance_pressed)

	add_child(game_over_instance)
	game_over_screen = game_over_instance

func _on_show_ranking():
	if game_over_screen:
		game_over_screen.queue_free()

	if pause_button:
		pause_button.visible = true

	AdManager.set_pause_disabled(false)
	get_tree().paused = false
	GameManager.clear_free_mode()
	GameManager.call_deferred("change_scene", "res://scenes/RankingScene.tscn")


func _on_replay_game():
	if game_over_screen:
		game_over_screen.queue_free()

	if pause_button:
		pause_button.visible 	= true
		pause_button.disabled 	= false

	is_pause_enabled = true
	AdManager.set_pause_disabled(false)
	get_tree().paused = false

	if not GameManager.get_is_free_mode():
		GameManager.set_free_mode(false)

	GameManager.call_deferred("change_scene", "res://scenes/GameScene.tscn")


func _on_game_over_continue():
	if game_over_screen:
		game_over_screen.queue_free()

	if pause_button:
		pause_button.visible 	= true
		pause_button.disabled 	= false

	is_pause_enabled = true
	AdManager.set_pause_disabled(false)
	get_tree().paused = false
	GameManager.clear_free_mode()
	GameManager.call_deferred("change_scene", "res://scenes/MainMenu.tscn")


func _on_last_chance_pressed():
	# Save current game state (including initial lives count and total hits)
	AdManager.save_game_state_for_ad(score, player_area.position, ScoreManager.get_last_milestone_score(), life_display, life_lost)

	if game_over_screen:
		game_over_screen.queue_free()
		game_over_screen = null

	# Show ad screen
	AdManager.show_ad_simulation()


func resume_game():
	toggle_pause()


func go_to_options():
	# Create options menu overlay
	var options_scene			= preload("res://scenes/OptionsMenu.tscn")
	var options_instance		= options_scene.instantiate()
	options_instance.name		= "OptionsMenuOverlay"
	options_instance.z_index	= 1000

	add_child(options_instance)
	set_process_input(false)

	# Hide pause UI
	if pause_menu:
		pause_menu.visible = false

	if pause_button:
		pause_button.disabled   = true
		pause_button.modulate   = Color(0.5, 0.5, 0.5, 0.6)
		pause_button.focus_mode = Control.FOCUS_NONE

	options_instance.connect("tree_exiting", _on_options_menu_exiting)


func _on_options_menu_exiting():
	set_process_input(true)

	# Restore pause UI
	if pause_menu:
		pause_menu.visible = true

	if pause_button:
		pause_button.disabled   = false
		pause_button.modulate   = Color(1.0, 1.0, 1.0, 1.0)
		pause_button.focus_mode = Control.FOCUS_ALL

	get_tree().paused = true


func go_to_main_menu():
	get_tree().paused = false
	GameManager.clear_free_mode()
	GameManager.change_scene("res://scenes/MainMenu.tscn")
