# reviewed
extends "res://objects/Ball.gd"

var is_bonus_ball       = true
var collision_disabled  = true  # Start with collisions disabled



func _ready():
	super._ready()

	# Disable collisions at spawn
	disable_collisions()

	# Re-enable collisions after 1 second using Timer node (prevents leaks)
	var timer 		= Timer.new()
	timer.wait_time = 1.0
	timer.one_shot 	= true

	add_child(timer)
	timer.timeout.connect(enable_collisions)
	timer.start()

func is_bonus():
	return true

func disable_collisions():
	collision_disabled = true

	# Disable collision layers to prevent collision with other balls
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

func enable_collisions():
	collision_disabled = false

	# Re-enable collision layers
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

func _draw():
	# Draw bonus ball with brown color instead of cyan
	var ball_color   = Color(0.6, 0.4, 0.2, 0.9)  # Brown
	var ball_outline = Color(0.8, 0.5, 0.3, 1.0)  # Light brown outline

	# Draw core with highlight
	draw_circle(Vector2.ZERO, ball_radius + 2, Color(0.8, 0.5, 0.3, 0.3))
	draw_circle(Vector2.ZERO, ball_radius, ball_color)
	draw_arc(Vector2.ZERO, ball_radius, 0, TAU, 32, ball_outline, 2.0)
	draw_circle(Vector2(-ball_radius * 0.3, -ball_radius * 0.3), ball_radius * 0.2, Color(1, 1, 1, 0.8))

	# Draw brown trail instead of cyan
	if trail_points.size() <= 1:
		return

	for i in range(trail_points.size() - 1):
		var alpha     = float(trail_points.size() - i) / float(trail_points.size())
		var thickness = lerp(2.0, 12.0, alpha)

		var local_start = to_local(trail_points[i])
		var local_end   = to_local(trail_points[i + 1])

		# Brown neon trail effect
		draw_line(local_start, local_end, Color(0.8, 0.5, 0.3, alpha * 0.1), thickness * 2.5)
		draw_line(local_start, local_end, Color(0.8, 0.5, 0.3, alpha * 0.3), thickness)
		draw_line(local_start, local_end, Color(1, 1, 1, alpha * 0.2), thickness * 0.3)
