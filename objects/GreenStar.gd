# reviewed
extends Area2D

signal collected

@export var lifetime: float			= GameConstant.GREEN_STAR_LIFETIME
@export var star_size: float		= 40.0
@export var glow_intensity: float	= 2.0

var lifetime_timer: Timer
var particle_scene: CPUParticles2D
var pulse_tween: Tween
var fade_tween: Tween
var is_fading: bool	= false



func _ready():
	add_to_group("green_star")
	create_star_visual()
	create_collision()
	create_particles()

	# Auto-destroy timer after lifetime expires
	lifetime_timer				= Timer.new()
	lifetime_timer.wait_time	= lifetime
	lifetime_timer.one_shot		= true

	lifetime_timer.timeout.connect(_on_lifetime_timeout)
	add_child(lifetime_timer)
	lifetime_timer.start()
	body_entered.connect(_on_body_entered)


func create_star_visual():
	var star			= Polygon2D.new()
	star.name			= "StarVisual"
	var points			= PackedVector2Array()
	var num_points		= 5
	var outer_radius	= star_size / 2
	var inner_radius	= outer_radius * 0.4

	# Generate 5-pointed star by alternating outer and inner radius points
	for i in range(num_points * 2):
		var angle	= deg_to_rad(i * 360.0 / (num_points * 2) - 90)
		var radius	= outer_radius if i % 2 == 0 else inner_radius
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	star.polygon	= points
	star.color		= Color(0.2, 1.0, 0.3, 1.0)

	add_child(star)
	create_pulse_animation(star)


func create_pulse_animation(star: Polygon2D):
	# Infinite pulsating effect (1.0 → 1.2 → 1.0 scale)
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(star, "scale", Vector2(1.2, 1.2), 0.5)
	pulse_tween.tween_property(star, "scale", Vector2(1.0, 1.0), 0.5)


func create_collision():
	var collision		= CollisionShape2D.new()
	collision.name		= "CollisionShape"

	# Large hitbox (1.5x star size) for easier ball collection
	var shape			= CircleShape2D.new()
	shape.radius		= star_size * 1.5
	collision.shape		= shape

	add_child(collision)


func create_particles():
	particle_scene                        = CPUParticles2D.new()
	particle_scene.name                   = "ExplosionParticles"
	particle_scene.emitting               = false
	particle_scene.one_shot               = true
	particle_scene.amount                 = 30
	particle_scene.lifetime               = 1.0
	particle_scene.explosiveness          = 1.0
	particle_scene.randomness             = 0.5
	particle_scene.color                  = Color(0.2, 1.0, 0.3, 1.0)
	particle_scene.scale_amount_min       = 3.0
	particle_scene.scale_amount_max       = 8.0
	particle_scene.emission_shape         = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particle_scene.emission_sphere_radius = 10.0
	particle_scene.direction              = Vector2(0, -1)
	particle_scene.spread                 = 180.0
	particle_scene.gravity                = Vector2(0, 200)
	particle_scene.initial_velocity_min   = 100.0
	particle_scene.initial_velocity_max   = 200.0
	particle_scene.angular_velocity_min   = -360.0
	particle_scene.angular_velocity_max   = 360.0
	particle_scene.z_index                = 10  # Ensure particles are drawn above other elements

	add_child(particle_scene)


func _on_body_entered(body: Node2D):
	if body.is_in_group("ball"):
		collect()


func collect():
	# Prevent double collection
	if is_fading:
		return

	is_fading = true

	if AudioManager:
		AudioManager.play_sfx_button_hover()

	# Notify GameScene to activate shield boost
	collected.emit()
	explode()


func _on_lifetime_timeout():
	fade_out()


func explode():
	# Stop all timers and animations
	if lifetime_timer and not lifetime_timer.is_stopped():
		lifetime_timer.stop()

	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
		pulse_tween = null

	# Disable collision detection (deferred to avoid errors during signal)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	hide_visuals()

	if particle_scene:
		particle_scene.emitting = true
		particle_scene.restart()  # Force restart the particle system

	# Use Timer node instead of SceneTreeTimer to prevent memory leaks
	var cleanup_timer			= Timer.new()
	cleanup_timer.wait_time		= 1.5
	cleanup_timer.one_shot		= true

	cleanup_timer.timeout.connect(queue_free)
	add_child(cleanup_timer)
	cleanup_timer.start()


func fade_out():
	# Prevent multiple fade out calls
	if is_fading:
		return

	is_fading = true

	# Stop all timers and animations
	if lifetime_timer and not lifetime_timer.is_stopped():
		lifetime_timer.stop()

	# Kill and clear all tweens - IMPORTANT: do this BEFORE resetting scale
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
		pulse_tween = null

	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
		fade_tween = null

	# Disable collision detection immediately
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	# Reset StarVisual scale to 1.0 and keep it visible for fade animation
	var star_visual = get_node_or_null("StarVisual")
	if star_visual:
		star_visual.scale = Vector2.ONE

		# Disable processing on StarVisual to prevent any script interference
		star_visual.set_process(false)
		star_visual.set_physics_process(false)

	# Important: wait one frame to ensure tween is fully killed
	await get_tree().process_frame

	# Delegate fade animation to AnimationManager with safety mechanisms
	AnimationManager.animate_star_fadeout(self, 1.5)


func hide_visuals():
	# Hide all children except particle system
	for child in get_children():
		if child.name != "ExplosionParticles" and "visible" in child:
			child.visible = false

	# Ensure particles remain visible
	if particle_scene:
		particle_scene.visible = true
		particle_scene.show()


func _exit_tree():
	# Clean up tweens
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()

	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()

	# Clean up signal connections to prevent memory leaks
	if lifetime_timer and lifetime_timer.timeout.is_connected(_on_lifetime_timeout):
		lifetime_timer.timeout.disconnect(_on_lifetime_timeout)

	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)

	# Clean up dynamically created timers
	for child in get_children():
		if child is Timer:
			child.queue_free()
