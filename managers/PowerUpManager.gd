# reviewed
extends Node

var original_shield_arc_angle: float	= 0.0
var shield_boost_active: bool			= false
var shield_boost_timer: Timer			= null
var shield_warning_timer: Timer			= null
var game_scene: Node					= null
var green_star_spawn_timer: Timer		= null
var green_star_script					= preload("res://objects/GreenStar.gd")


func initialize(scene: Node):
	game_scene = scene
	setup_green_star_system()


func cleanup():
	if green_star_spawn_timer:
		green_star_spawn_timer.queue_free()
		green_star_spawn_timer = null

	if shield_boost_timer:
		shield_boost_timer.queue_free()
		shield_boost_timer = null

	if shield_warning_timer:
		shield_warning_timer.queue_free()
		shield_warning_timer = null

func setup_green_star_system():
	# Create spawn timer (every 10 seconds)
	green_star_spawn_timer               = Timer.new()
	green_star_spawn_timer.name          = "GreenStarSpawnTimer"
	green_star_spawn_timer.wait_time     = GameConstant.GREEN_STAR_SPAWN_INTERVAL
	green_star_spawn_timer.one_shot      = false

	green_star_spawn_timer.timeout.connect(_on_green_star_spawn_timer_timeout)
	green_star_spawn_timer.process_mode	= Node.PROCESS_MODE_PAUSABLE
	game_scene.add_child(green_star_spawn_timer)
	green_star_spawn_timer.start()

	# Create shield boost timer (30 seconds duration)
	shield_boost_timer                  = Timer.new()
	shield_boost_timer.name             = "ShieldBoostTimer"
	shield_boost_timer.wait_time        = GameConstant.SHIELD_BOOST_DURATION
	shield_boost_timer.one_shot         = true

	shield_boost_timer.timeout.connect(_on_shield_boost_timeout)
	shield_boost_timer.process_mode		= Node.PROCESS_MODE_PAUSABLE
	game_scene.add_child(shield_boost_timer)

	# Create shield warning timer (triggers 2 seconds before boost ends)
	shield_warning_timer         	= Timer.new()
	shield_warning_timer.name    	= "ShieldWarningTimer"
	shield_warning_timer.one_shot	= true

	shield_warning_timer.timeout.connect(_on_shield_warning_timeout)
	shield_warning_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	game_scene.add_child(shield_warning_timer)

	# Save original shield size
	var shield = game_scene.get_tree().get_first_node_in_group("shield")

	if shield:
		original_shield_arc_angle = shield.active_arc_angle

func _on_green_star_spawn_timer_timeout():
	# Create green star instance
	var star = Area2D.new()

	star.set_script(green_star_script)
	star.name = "GreenStar"

	# Get game area bounds
	var game_area = game_scene.get_node("GameArea")
	var game_size = game_area.size

	# Choose random edge (0=top, 1=right, 2=bottom, 3=left)
	var edge		= randi() % 4
	var margin		= 50.0  # Distance from edge
	var position	= Vector2.ZERO

	match edge:
		0:  # Top
			position = Vector2(randf_range(margin, game_size.x - margin), margin)
		1:  # Right
			position = Vector2(game_size.x - margin, randf_range(margin, game_size.y - margin))
		2:  # Bottom
			position = Vector2(randf_range(margin, game_size.x - margin), game_size.y - margin)
		3:  # Left
			position = Vector2(margin, randf_range(margin, game_size.y - margin))

	star.position = position

	# Connect collected signal
	star.collected.connect(_on_green_star_collected)

	# Add to game area
	game_area.add_child(star)

func _on_green_star_collected():
	activate_shield_boost()

	# Animate ball and shield to green
	var ball 	= game_scene.get_tree().get_first_node_in_group("ball")
	var shield 	= game_scene.get_tree().get_first_node_in_group("shield")

	if ball:
		AnimationManager.animate_color_change(ball, "modulate", Color.GREEN, 0.5, Color.WHITE)

	if shield:
		AnimationManager.animate_color_change(shield, "modulate", Color.GREEN, 0.5, Color.WHITE)

func activate_shield_boost():
	var shield = game_scene.get_tree().get_first_node_in_group("shield")

	if not shield:
		return

	# Calculate new angle with 50% boost from CURRENT angle (not original)
	var current_angle    = shield.active_arc_angle
	var new_angle        = current_angle * (1.0 + float(GameConstant.SHIELD_BOOST_PERCENT) / 100.0)

	# Limit defined as percent of full circle (360°)
	var max_angle = deg_to_rad(360.0 * float(GameConstant.SHIELD_MAX_ARC_PERCENT) / 100.0)

	if new_angle > max_angle:
		new_angle = max_angle

	shield.active_arc_angle = new_angle

	# Restart or start boost timer
	shield_boost_active = true
	shield_boost_timer.start()

	# Start warning timer (triggers 2 seconds before boost ends)
	var warning_delay = max(0.1, GameConstant.SHIELD_BOOST_DURATION - 2.0)
	shield_warning_timer.wait_time = warning_delay
	shield_warning_timer.start()

func _on_shield_warning_timeout():
	# Flash shield green for 2 seconds before boost ends
	var shield = game_scene.get_tree().get_first_node_in_group("shield")

	if not shield:
		return

	# Create blinking effect (green to white to green) for 2 seconds
	var warning_tween = shield.create_tween()
	warning_tween.set_loops(4)
	warning_tween.tween_method(shield.set_temporary_color.bind(2.0), Color(0.2, 1.0, 0.3, 1.0), Color(1.0, 1.0, 1.0, 1.0), 0.25)
	warning_tween.tween_method(shield.set_temporary_color.bind(2.0), Color(1.0, 1.0, 1.0, 1.0), Color(0.2, 1.0, 0.3, 1.0), 0.25)


func _on_shield_boost_timeout():
	# Deactivate boost shield
	var shield = game_scene.get_tree().get_first_node_in_group("shield")

	if not shield:
		return

	shield_boost_active = false

	# Restore original shield size
	shield.active_arc_angle = original_shield_arc_angle
