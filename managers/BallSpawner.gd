# reviewed
extends Node

var shield_hit_counter: int = 0
var game_scene: Node        = null
var bonus_ball_scene        = preload("res://objects/BonusBall.tscn")



func initialize(scene: Node):
	game_scene = scene
	shield_hit_counter = 0


func increment_shield_hit_counter():
	shield_hit_counter += 1

	if shield_hit_counter >= GameConstant.SHIELD_HITS_FOR_BONUS_BALL:
		shield_hit_counter = 0
		spawn_bonus_ball()

func get_shield_hit_counter():
	return shield_hit_counter

func spawn_bonus_ball():
	# Count current balls (1 principal + bonus balls)
	var game_area = game_scene.get_node_or_null("GameArea")

	if not game_area:
		return

	# Count all balls in the scene by checking the ball group
	var ball_count = game_scene.get_tree().get_nodes_in_group("ball").size()

	# Check if we've reached the maximum
	if ball_count >= GameConstant.MAX_BALLS_IN_SCENE:
		return

	# Get main ball position
	var main_ball = game_scene.get_tree().get_first_node_in_group("ball")

	if not main_ball:
		return

	# Instantiate bonus ball scene
	var bonus_ball = bonus_ball_scene.instantiate()

	# Spawn at main ball position
	bonus_ball.position = main_ball.global_position

	# Random velocity direction (all directions)
	var angle           = randf_range(0, TAU)
	var bonus_speed     = 700.0
	bonus_ball.velocity = Vector2(cos(angle), sin(angle)) * bonus_speed

	# which occurs when spawning during physics collision callbacks
	game_area.add_child.call_deferred(bonus_ball)
	bonus_ball.name = "BonusBall"

	# Change shield color to brown for 1 second
	var shield = game_scene.get_tree().get_first_node_in_group("shield")

	if not shield:
		return

	var color_brown = Color(0.6, 0.4, 0.2, 0.9)
	AnimationManager.animate_color_change(shield, "modulate", color_brown, 0.5, Color.WHITE)