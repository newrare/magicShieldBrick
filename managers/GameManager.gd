# reviewed
extends Node

var current_scene_path:  String     = ""
var previous_scene_path: String     = ""
var saved_game_state:    Dictionary = {}
var was_paused:          bool       = false
var is_free_mode:        bool       = false



# Scene navigation
func change_scene(scene_path: String):
	previous_scene_path = current_scene_path
	current_scene_path  = scene_path
	get_tree().change_scene_to_file(scene_path)


func set_previous_scene(scene_path: String):
	previous_scene_path = scene_path


func go_to_previous_scene():
	if previous_scene_path != "":
		change_scene(previous_scene_path)
	else:
		change_scene("res://scenes/MainMenu.tscn")


func quit_game():
	get_tree().quit()


func get_current_scene_name():
	var scene = get_tree().current_scene
	if scene:
		return scene.name

	return ""


# Pause state management
func set_was_paused(paused: bool):
	was_paused = paused


func get_was_paused():
	return was_paused


func clear_was_paused():
	was_paused = false


# Free mode management
func set_free_mode(enabled: bool):
	is_free_mode = enabled

	if not enabled:
		GameConstant.reset_to_defaults()

func get_is_free_mode():
	return is_free_mode


func clear_free_mode():
	is_free_mode = false


# Game state save/restore for OptionsMenu transitions
func save_game_state(game_scene):
	# Store complete game state
	saved_game_state = {
		"score":           game_scene.score,
		"lives":           game_scene.lives,
		"ball_position":   game_scene.ball.position,
		"ball_velocity":   game_scene.ball.velocity,
		"player_position": game_scene.player_area.position,
		"is_paused":       game_scene.is_paused
	}


func restore_game_state(game_scene):
	if not saved_game_state.is_empty():
		# Restore game values
		game_scene.score = saved_game_state.get("score", 0)
		game_scene.lives = saved_game_state.get("lives", 3)

		# Wait for ball and player_area to be initialized
		await game_scene.get_tree().process_frame

		# Restore positions and velocities
		if game_scene.ball:
			game_scene.ball.position = saved_game_state.get("ball_position", Vector2.ZERO)
			game_scene.ball.velocity = saved_game_state.get("ball_velocity", Vector2.ZERO)

		if game_scene.player_area:
			game_scene.player_area.position = saved_game_state.get("player_position", Vector2.ZERO)

		# Update UI displays
		game_scene.update_score_display()
		#game_scene.update_lives_display()

		# Restore pause state
		game_scene.set_pause_state(true)

		# Cleanup
		saved_game_state.clear()
		clear_was_paused()


func return_to_game_with_pause():
	if not saved_game_state.is_empty():
		# Reload scene with saved state
		set_was_paused(true)
		change_scene("res://scenes/GameScene.tscn")
	else:
		# Fallback behavior
		if previous_scene_path == "res://scenes/GameScene.tscn":
			set_was_paused(true)
			change_scene(previous_scene_path)
		else:
			go_to_previous_scene()
