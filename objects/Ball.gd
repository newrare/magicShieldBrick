# reviewed
extends CharacterBody2D

@export var speed         		: float = 700.0
@export var max_speed     		: float = 2000.0
@export var bounce_angle  		: float = 35.0
@export var ball_radius   		: float = 10.0
@export var gravity_strength 	: float = 500.0

# Gravity modes
@export var gravity_min_distance		: float = 100.0
@export var gravity_max_distance		: float = 800.0
@export var gravity_multiplier_strong	: float = 10.0
@export var gravity_multiplier_classic	: float = 2.0

# Gravity mode tracking
var gravity_mode			: String 	= "classic"
var consecutive_wall_hits	: int 		= 0

# Anti-orbit timer: increases gravity if no collision for 5 seconds
var no_collision_timer		: float = 0.0
var no_collision_threshold	: float = 5.0
var gravity_boost_multiplier: float = 1.0

var screen_size           : Vector2
var trail_points          : Array = []
var max_trail_length      : int   = 15
var trail_update_distance : float = 5.0
var player_position       : Vector2

func _ready():
	velocity    = Vector2(1, -1).normalized() * speed
	screen_size = get_viewport().get_visible_rect().size

	var ball_sprite = get_node_or_null("BallSprite")
	if ball_sprite:
		ball_sprite.visible = false

	add_to_group("ball")
	trail_points = [global_position]

func _physics_process(delta):
	# Don't move if game is paused
	if get_tree().paused:
		return

	var old_position = global_position

	# Get player position for gravity effect
	update_player_position()

	# Update no-collision timer for gravity boost
	update_no_collision_timer(delta)

	# Apply gravity towards player
	apply_player_gravity(delta)

	# Maintain constant speed and move ball
	velocity = velocity.normalized() * speed
	move_and_slide()

	# Update visual trail and check collisions
	update_trail()
	check_shield_collision(old_position, global_position)
	check_screen_boundaries()
	check_collisions()

func update_player_position():
	# Get player position from game scene
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if game_scene and game_scene.has_method("get_player_position"):
		player_position = game_scene.get_player_position()

# Update no-collision timer - increases gravity if ball orbits without hitting anything
func update_no_collision_timer(delta):
	no_collision_timer += delta

	# Every 5 seconds without collision, double the gravity boost
	if no_collision_timer >= no_collision_threshold:
		gravity_boost_multiplier *= 2.0
		no_collision_timer = 0.0
		print("⚠️ Gravity boost increased to x%s due to no collisions!" % gravity_boost_multiplier)

# Reset the no-collision timer when ball hits wall or shield
func reset_no_collision_timer():
	if gravity_boost_multiplier > 1.0:
		print("⚠️  Gravity boost reset (was x%s)" % gravity_boost_multiplier)

	no_collision_timer 			= 0.0
	gravity_boost_multiplier 	= 1.0

func apply_player_gravity(delta):
	# Calculate direction towards player
	var direction_to_player = (player_position - global_position).normalized()

	# Calculate distance to player
	var distance_to_player = global_position.distance_to(player_position)

	# Select multiplier based on gravity mode
	var multiplier = gravity_multiplier_classic if gravity_mode == "classic" else gravity_multiplier_strong

	# Calculate gravity multiplier based on distance
	var gravity_factor = 1.0

	if distance_to_player < gravity_max_distance:
		if distance_to_player <= gravity_min_distance:
			# At minimum distance: use FULL multiplier
			gravity_factor = multiplier
		else:
			# Between min and max: smooth exponential transition
			var normalized_distance = (distance_to_player - gravity_min_distance) / (gravity_max_distance - gravity_min_distance)

			# Exponential ease-out: starts fast, then slow
			var eased = pow(1.0 - normalized_distance, 2.0)  # Quadratic easing
			gravity_factor = lerp(multiplier, 1.0, eased)

	# Apply gravity force towards player
	var gravity_force = direction_to_player * gravity_strength * gravity_factor * gravity_boost_multiplier * delta

	# Add gravity to velocity (will be normalized after)
	velocity += gravity_force

func check_shield_collision(old_pos: Vector2, new_pos: Vector2):
	# Find shield in scene
	var shield = get_tree().get_first_node_in_group("shield")
	if not shield:
		return

	# Get shield parameters
	var shield_center    = shield.global_position
	var orbit_radius     = shield.orbit_radius
	var shield_thickness = shield.shield_thickness
	var active_angle     = shield.active_angle
	var active_arc_angle = shield.active_arc_angle

	var inner_radius = orbit_radius - shield_thickness / 2
	var outer_radius = orbit_radius + shield_thickness / 2

	# Check trajectory intersection with shield ring
	var trajectory        = new_pos - old_pos
	var trajectory_length = trajectory.length()

	if trajectory_length < 0.1:
		return

	# Sample points along trajectory (one every 5 pixels)
	var samples = max(int(trajectory_length / 5), 2)

	for i in range(samples + 1):
		var t                  = float(i) / float(samples)
		var sample_pos         = old_pos.lerp(new_pos, t)
		var distance_to_center = sample_pos.distance_to(shield_center)

		# Check if inside shield ring
		if distance_to_center >= inner_radius and distance_to_center <= outer_radius:
			var direction_to_ball = (sample_pos - shield_center).normalized()
			var ball_angle        = atan2(direction_to_ball.y, direction_to_ball.x)
			var angle_diff        = angle_difference(ball_angle, active_angle)

			# Check if inside active arc
			if abs(angle_diff) <= active_arc_angle / 2:
				bounce_off_shield(shield_center, sample_pos)
				return

func bounce_off_shield(shield_center: Vector2, collision_point: Vector2):
	# Calculate bounce direction
	var normal = (collision_point - shield_center).normalized()
	velocity   = velocity.bounce(normal)

	# Switch gravity to classic mode after shield bounce
	gravity_mode = "classic"

	# Reset wall hit counter when bouncing off shield
	consecutive_wall_hits = 0

	# Reset no-collision timer to prevent gravity boost
	reset_no_collision_timer()

	# Reposition ball outside shield to avoid multiple collisions
	var shield = get_tree().get_first_node_in_group("shield")
	if shield:
		var safe_distance = shield.orbit_radius + shield.shield_thickness / 2 + 15
		global_position   = shield_center + normal * safe_distance

		if shield.has_method("trigger_bounce_effect"):
			shield.trigger_bounce_effect()

	# Play sound and notify game scene
	AudioManager.play_sfx_shield()

	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if game_scene and game_scene.has_method("ball_hit_shield"):
		game_scene.ball_hit_shield()

	# Visual feedback
	if shield:
		UIManager.create_shield_floating_text(shield.global_position, get_parent())
	trigger_particle_effect()

func increase_speed_for_milestone():
	speed    *= 1.1
	speed     = min(speed, max_speed)
	velocity  = velocity.normalized() * speed

func angle_difference(angle1: float, angle2: float):
	var diff = angle1 - angle2

	while diff > PI:
		diff -= TAU
	while diff < -PI:
		diff += TAU
	return diff

func check_screen_boundaries():
	var hit_wall  = false
	var wall_side = ""

	# Left and right walls
	if position.x <= ball_radius:
		velocity.x = -velocity.x
		hit_wall   = true
		wall_side  = "left"
		apply_bounce_angle()
		position.x = clamp(position.x, ball_radius, screen_size.x - ball_radius)
	elif position.x >= screen_size.x - ball_radius:
		velocity.x = -velocity.x
		hit_wall   = true
		wall_side  = "right"
		apply_bounce_angle()
		position.x = clamp(position.x, ball_radius, screen_size.x - ball_radius)

	# Top and bottom walls
	if position.y <= ball_radius:
		velocity.y = -velocity.y
		hit_wall   = true
		wall_side  = "top"

		apply_bounce_angle()
		position.y = clamp(position.y, ball_radius, screen_size.y - ball_radius)
	elif position.y >= screen_size.y - ball_radius:
		velocity.y = -velocity.y
		hit_wall   = true
		wall_side  = "bottom"

		apply_bounce_angle()
		position.y = clamp(position.y, ball_radius, screen_size.y - ball_radius)

	if hit_wall:
		# Increment consecutive wall hit counter
		consecutive_wall_hits += 1

		# Switch back to strong gravity mode after 2 consecutive wall hits
		if consecutive_wall_hits >= 2:
			gravity_mode = "strong"
			consecutive_wall_hits = 0  # Reset counter

		# Reset no-collision timer to prevent gravity boost
		reset_no_collision_timer()

		on_wall_hit(wall_side)

func apply_bounce_angle():
	var angle_variation  = deg_to_rad(bounce_angle)
	var current_angle    = atan2(velocity.y, velocity.x)
	var current_speed    = velocity.length()
	var random_variation = randf_range(-angle_variation, angle_variation)

	current_angle += random_variation
	velocity       = Vector2(cos(current_angle), sin(current_angle)) * current_speed

func check_collisions():
	# Check slide collisions (skip player as it's handled separately)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider  = collision.get_collider()

		if collider:
			if collider.name == "PlayerContainer" or collider.has_method("is_invincible"):
				return

			var normal = collision.get_normal()
			velocity   = velocity.bounce(normal)

func bounce_off_player(player_position: Vector2):
	# Calculate bounce direction from player center
	var ball_to_player = global_position - player_position
	var normal         = ball_to_player.normalized()

	# Bounce and move away to avoid multiple collisions
	velocity         = velocity.bounce(normal)
	global_position += normal * 15.0

func on_wall_hit(wall_side: String):
	# Visual feedback
	trigger_particle_effect()

	# Get points and create floating text
	var game_scene = get_tree().get_first_node_in_group("game_scene")
	if game_scene and game_scene.has_method("get_wall_points"):
		var points = game_scene.get_wall_points()
		create_floating_text(wall_side, points)
	else:
		create_floating_text(wall_side, 10)

	# Notify game scene for score
	if game_scene and game_scene.has_method("ball_hit_wall"):
		game_scene.ball_hit_wall()

func update_trail():
	# Add new trail point if ball moved enough
	if trail_points.size() == 0 or global_position.distance_to(trail_points[0]) >= trail_update_distance:
		trail_points.push_front(global_position)

		# Limit trail length
		while trail_points.size() > max_trail_length:
			trail_points.pop_back()

	queue_redraw()

func trigger_particle_effect():
	# Temporarily increase trail length on collision
	max_trail_length = 25

	var tween = create_tween()
	tween.tween_method(_reset_trail_length, 25, 15, 0.5)

func _reset_trail_length(length: int):
	max_trail_length = length



func create_floating_text(wall_side: String, points: int):
	# Fixed font size (no scaling with score)
	var font_size = 24

	var floating_label = Label.new()
	floating_label.text = "+" + str(points)
	floating_label.add_theme_font_size_override("font_size", font_size)
	floating_label.add_theme_color_override("font_color", Color.YELLOW)

	# Position offset based on wall side
	var offset = Vector2.ZERO
	match wall_side:
		"top":    offset = Vector2(0, 40)
		"bottom": offset = Vector2(0, -40)
		"left":   offset = Vector2(40, 0)
		"right":  offset = Vector2(-40, 0)
		_:        offset = Vector2(30, -20)

	floating_label.position = position + offset

	# Add label to parent (safer)
	var parent = get_parent()

	if not parent:
		return

	parent.add_child(floating_label)

	# Animate movement away from wall
	var movement_offset = Vector2.ZERO
	match wall_side:
		"top":    movement_offset = Vector2(0, 50)
		"bottom": movement_offset = Vector2(0, -50)
		"left":   movement_offset = Vector2(50, 0)
		"right":  movement_offset = Vector2(-50, 0)
		_:        movement_offset = Vector2(0, -50)

	# Create tween and bind it to the label
	var tween = floating_label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(floating_label, "position", floating_label.position + movement_offset, 1.0)
	tween.tween_property(floating_label, "modulate:a", 0.0, 1.0)
	tween.chain()
	tween.tween_callback(floating_label.queue_free)

	# Safety timer to force cleanup after 2 seconds (in case tween fails)
	var safety_timer 		= Timer.new()
	safety_timer.wait_time 	= 2.0
	safety_timer.one_shot 	= true

	floating_label.add_child(safety_timer)
	safety_timer.timeout.connect(func():
		if is_instance_valid(floating_label) and floating_label.get_parent():
			floating_label.queue_free()
	)

	safety_timer.start()

func _draw():
	# Draw ball core with highlight
	var ball_color   = Color(1, 1, 1, 0.9)
	var ball_outline = Color(0, 1, 1, 1.0)

	draw_circle(Vector2.ZERO, ball_radius + 2, Color(0, 1, 1, 0.3))
	draw_circle(Vector2.ZERO, ball_radius, ball_color)
	draw_arc(Vector2.ZERO, ball_radius, 0, TAU, 32, ball_outline, 2.0)
	draw_circle(Vector2(-ball_radius * 0.3, -ball_radius * 0.3), ball_radius * 0.2, Color(1, 1, 1, 0.8))

	# Draw neon trail behind ball
	if trail_points.size() <= 1:
		return

	for i in range(trail_points.size() - 1):
		var alpha     = float(trail_points.size() - i) / float(trail_points.size())
		var thickness = lerp(2.0, 12.0, alpha)

		var local_start = to_local(trail_points[i])
		var local_end   = to_local(trail_points[i + 1])

		# Draw multiple layers for neon effect
		draw_line(local_start, local_end, Color(0, 1, 1, alpha * 0.1), thickness * 2.5)
		draw_line(local_start, local_end, Color(0, 1, 1, alpha * 0.3), thickness)
		draw_line(local_start, local_end, Color(1, 1, 1, alpha * 0.2), thickness * 0.3)
