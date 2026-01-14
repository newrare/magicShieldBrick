# reviewed
extends Node2D

@export var orbit_radius: float			= 150.0  # Shield orbit radius
@export var shield_thickness: float		= 20.0   # Shield circle thickness
@export var active_arc_angle: float		= PI / 2 # Active arc angle (90 degrees)
@export var bounce_intensity: float		= 1.2    # Bounce effect intensity (size multiplier)
@export var bounce_duration: float		= 0.3    # Bounce animation duration in seconds
@export var rotation_speed: float		= 8.0    # Speed for zone control mode (radians per second)

var player_position: Vector2
var shield_area: Area2D
var shield_visual: Node2D
var mouse_position: Vector2
var active_angle: float				= 0.0
var bounce_scale: float				= 1.0
var temporary_color: Color			= Color.TRANSPARENT
var is_using_temporary_color: bool	= false
var color_tween: Tween

# Zone control variables
var is_touching: bool = false
var touch_position: Vector2 = Vector2.ZERO



func _ready():
	# Configure process mode to respect pause
	process_mode = Node.PROCESS_MODE_PAUSABLE

	# Add to group so ball can find it
	add_to_group("shield")

	# Create Area2D for collision detection
	create_collision_area()

	# Create visual representation
	create_shield_visual()

	# Force first redraw
	queue_redraw()


func _exit_tree():
	# Disconnect signals to prevent memory leaks
	if shield_area and shield_area.body_entered.is_connected(_on_body_entered):
		shield_area.body_entered.disconnect(_on_body_entered)

	# Kill color tween if it exists
	if color_tween and color_tween.is_valid():
		color_tween.kill()


func get_input_position():
	return get_global_mouse_position()

func _process(delta):
	# Don't update if game is paused
	if get_tree().paused:
		return

	# Get player position
	var game_scene = get_tree().get_first_node_in_group("game_scene")

	if game_scene and game_scene.has_method("get_player_position"):
		player_position = game_scene.get_player_position()
	else:
		# Fallback if method doesn't exist yet
		player_position = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)

	# Update shield angle based on control mode
	if ControlManager.is_direction_mode():
		update_direction_mode()
	else:
		update_zones_mode(delta)

	# Position shield at player center
	global_position = player_position

	# Redraw visual
	if shield_visual:
		shield_visual.queue_redraw()

	queue_redraw()


func update_direction_mode():
	# Original behavior: follow mouse/touch direction
	mouse_position = get_input_position()
	var mouse_direction	= (mouse_position - player_position).normalized()
	active_angle		= atan2(mouse_direction.y, mouse_direction.x)


func update_zones_mode(delta: float):
	# Zone control: detect left/right screen zones
	var screen_width 	= get_viewport().get_visible_rect().size.x
	var screen_center 	= screen_width / 2.0

	# Check for mouse click (PC) or touch (Android)
	# In Godot 4, touch is emulated as mouse events by default
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var input_pos = get_input_position()

		# Check which side of screen (50% split)
		if input_pos.x < screen_center:
			# Left side: rotate counter-clockwise
			active_angle -= rotation_speed * delta
		else:
			# Right side: rotate clockwise
			active_angle += rotation_speed * delta

	# Normalize angle to [-PI, PI]
	while active_angle > PI:
		active_angle -= TAU
	while active_angle < -PI:
		active_angle += TAU

func create_collision_area():
	# Create Area2D for collisions
	shield_area = Area2D.new()
	add_child(shield_area)

	# Create ring-shaped collision (outer circle - inner circle)
	var collision_shape = CollisionShape2D.new()

	# Use outer circle to simulate ring
	# Collision logic is handled in script
	var shape				= CircleShape2D.new()
	shape.radius			= orbit_radius + shield_thickness / 2
	collision_shape.shape	= shape

	shield_area.add_child(collision_shape)

	# Connect collision signal
	shield_area.body_entered.connect(_on_body_entered)

func create_shield_visual():
	# Create shield visual node with its script
	shield_visual			= Node2D.new()
	shield_visual.name		= "ShieldVisual"

	# Place shield behind player but visible
	shield_visual.z_index	= 1
	z_index					= 1

	# Attach visual script
	var visual_script = load("res://objects/visuals/ShieldVisual.gd")
	if visual_script:
		shield_visual.set_script(visual_script)

	add_child(shield_visual)

func _draw():
	# Simplified shield rendering

	# Visible colors
	var shield_color	= Color(1, 1, 1, 0.3)  # Semi-transparent white
	var active_color	= Color(0, 1, 1, 0.8)  # Active cyan

	# Use temporary color if active
	if is_using_temporary_color:
		shield_color = Color(temporary_color.r, temporary_color.g, temporary_color.b, 0.3)
		active_color = Color(temporary_color.r, temporary_color.g, temporary_color.b, 0.8)

	# Draw simple circle first for testing
	draw_circle(Vector2.ZERO, orbit_radius, shield_color)
	draw_circle(Vector2.ZERO, orbit_radius - shield_thickness, Color.TRANSPARENT)

	# Draw active arc (simplified)
	var start_angle	= active_angle - active_arc_angle / 2
	var end_angle	= active_angle + active_arc_angle / 2

	# Simpler active arc
	draw_arc(Vector2.ZERO, orbit_radius, start_angle, end_angle, 32, active_color, shield_thickness)

func _on_body_entered(body):
	if body.name == "Ball":
		# Check if ball is in shield ring
		var ball_distance	= body.global_position.distance_to(player_position)
		var inner_radius	= orbit_radius - shield_thickness / 2
		var outer_radius	= orbit_radius + shield_thickness / 2

		if ball_distance >= inner_radius and ball_distance <= outer_radius:
			# Check if ball is in active arc
			var ball_direction	= (body.global_position - player_position).normalized()
			var ball_angle		= atan2(ball_direction.y, ball_direction.x)

			# Calculate angle difference
			var angle_diff = abs(angle_difference(ball_angle, active_angle))

			if angle_diff <= active_arc_angle / 2:
				bounce_ball_off_shield(body)

func bounce_ball_off_shield(ball):
	if ball.has_method("bounce_off_shield"):
		# Use new signature with center and collision point
		ball.bounce_off_shield(global_position, ball.global_position)

		# Trigger shield bounce effect
		trigger_bounce_effect()

# Trigger shield bounce animation
func trigger_bounce_effect():
	AnimationManager.animate_shield_bounce(
		shield_visual,
		self,
		_update_bounce_scale,
		bounce_intensity,
		bounce_duration,
		0.1  # cooldown
	)

func _update_bounce_scale(scale_value: float):
	bounce_scale = scale_value

	if shield_visual:
		shield_visual.queue_redraw()

	queue_redraw()


func set_temporary_color(color: Color, duration: float):
	# Set temporary color
	temporary_color				= color
	is_using_temporary_color	= true

	# Redraw immediately
	queue_redraw()
	if shield_visual:
		shield_visual.queue_redraw()

	# Cancel existing color tween if any
	if color_tween:
		color_tween.kill()

	# Create tween to reset color after duration
	color_tween = create_tween()
	color_tween.tween_callback(_reset_color).set_delay(duration)


func _reset_color():
	is_using_temporary_color = false

	# Redraw with normal colors
	queue_redraw()
	if shield_visual:
		shield_visual.queue_redraw()
