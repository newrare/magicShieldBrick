# reviewed
extends Node

# Animation locks to prevent overlapping animations
var active_animations: Dictionary = {}

# Track active timers to clean them up if needed
var active_timers: Array[Timer] = []

# Animation configurations
const BOUNCE_DURATION         = 0.5
const SPIN_DURATION           = 0.5
const FADE_DURATION           = 0.8
const COLOR_CHANGE_DURATION   = 0.3
const TIMEOUT_MARGIN          = 0.1

# Clean up all active timers (call when scene changes)
func cleanup_timers():
	for timer in active_timers:
		if is_instance_valid(timer):
			timer.stop()
			timer.queue_free()
	active_timers.clear()



# Bounce effect on score label (milestone)
func animate_score_bounce(label: Label):
	# Check
	if not label:
		print("❌ Invalid label provided for score bounce animation")
		return false

	if is_animation_active("score_bounce"):
		print("⚠️ Score bounce animation already active, skipping")
		return false

	# Set flag
	print("🔔 Animating score bounce")
	mark_animation_active("score_bounce")

	# Create bounce animation
	var tween_color 	= get_tree().create_tween()
	var tween_effect 	= get_tree().create_tween()

	tween_color.set_ease(Tween.EASE_OUT)
	tween_effect.set_ease(Tween.EASE_OUT)
	tween_effect.set_trans(Tween.TRANS_ELASTIC)

	# Color effect
	tween_color.tween_property(label, "modulate", Color.RED,	0.5)
	tween_color.tween_property(label, "modulate", Color.GOLD,	0.5)

	# Bounce effect
	var original_y = label.position.y

	tween_effect.tween_property(label, "position:y", original_y - 15.0, 	BOUNCE_DURATION)
	tween_effect.tween_property(label, "position:y", original_y,			BOUNCE_DURATION)

	# Timer for security and reset the flag
	_create_cleanup_timer(BOUNCE_DURATION + TIMEOUT_MARGIN, func():
		print("✅ Score bounce animation completed")

		if label and is_instance_valid(label):
			label.modulate = Color.GOLD
			label.position.y = original_y

		mark_animation_inactive("score_bounce")
	)

	return true

# Spin player 360° (milestone)
func animate_player_spin(player_container: Node2D, milestones: int = 1):
	if not player_container or is_animation_active("player_spin"):
		return false

	mark_animation_active("player_spin")

	# Force rotation to 0 before starting
	player_container.rotation = 0.0

	var total_rotation  = TAU * milestones
	var spin_duration   = SPIN_DURATION * milestones

	# Create spin animation
	var tween = get_tree().create_tween()

	tween.tween_property(player_container, "rotation", total_rotation, spin_duration)

	# Use Timer instead of callback - more reliable than tween.finished
	_create_cleanup_timer(spin_duration + TIMEOUT_MARGIN, func():
		if player_container and is_instance_valid(player_container):
			player_container.rotation = 0.0

		mark_animation_inactive("player_spin")
	)

	return true

# Animate heart loss (fade down and shrink)
func animate_heart_loss(heart: Control):
	if not heart:
		return false

	var anim_id = "heart_loss_%s" % heart.get_instance_id()

	if is_animation_active(anim_id):
		return false

	mark_animation_active(anim_id)

	var start_pos = heart.position.y

	# Create fade animation
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(heart, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_property(heart, "position:y", start_pos + 50.0, FADE_DURATION)
	tween.tween_property(heart, "scale", Vector2(0.5, 0.5), FADE_DURATION)

	# Use Timer instead of callback - more reliable
	_create_cleanup_timer(FADE_DURATION + TIMEOUT_MARGIN, func():
		mark_animation_inactive(anim_id)
	)

	return true

# Bounce shield (called on ball hit)
func animate_shield_bounce(
		shield_visual: Node2D,
		shield_redraw: Node2D,
		bounce_scale_callback: Callable,
		intensity: 	float = 1.2,
		duration: 	float = 0.3,
		cooldown: 	float = 0.1
	):

	# Check cooldown
	var current_time    = Time.get_ticks_msec() / 1000.0
	var last_time_key   = "shield_bounce_last_time"

	if active_animations.has(last_time_key):
		var time_since_last = current_time - active_animations[last_time_key]

		if time_since_last < cooldown:
			return false

	if is_animation_active("shield_bounce"):
		return false

	mark_animation_active("shield_bounce")
	active_animations[last_time_key] = current_time

	# Force reset before animation
	bounce_scale_callback.call(1.0)

	# Create bounce animation - bind to shield_visual node for Android compatibility
	# Using node.create_tween() instead of get_tree().create_tween() ensures
	# the tween is properly bound to the node's lifecycle
	var tween: Tween
	if shield_visual and is_instance_valid(shield_visual):
		tween = shield_visual.create_tween()
	else:
		tween = get_tree().create_tween()

	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)

	# Animation: grow then return to normal
	tween.tween_method(bounce_scale_callback, 1.0, intensity, duration * 0.3)
	tween.tween_method(bounce_scale_callback, intensity, 1.0, duration * 0.7)

	# Use Timer instead of callback - more reliable
	_create_cleanup_timer(duration + TIMEOUT_MARGIN, func():
		bounce_scale_callback.call(1.0)
		if shield_visual and is_instance_valid(shield_visual):
			shield_visual.queue_redraw()

		if shield_redraw and is_instance_valid(shield_redraw):
			shield_redraw.queue_redraw()

		mark_animation_inactive("shield_bounce")
	)

	return true

# Change node color temporarily
func animate_color_change(
		node: Node,
		property: String,
		target_color: Color,
		duration: float,
		restore_color: Color = Color.TRANSPARENT
	):

	var anim_id = "color_change_%s_%s" % [node.get_instance_id(), property]

	if is_animation_active(anim_id):
		return false

	mark_animation_active(anim_id)

	# Animate to target color
	var tween = get_tree().create_tween()
	tween.tween_property(node, property, target_color, COLOR_CHANGE_DURATION)

	# Wait duration
	tween.tween_interval(duration - COLOR_CHANGE_DURATION)

	# Restore color if specified
	if restore_color != Color.TRANSPARENT:
		tween.tween_property(node, property, restore_color, COLOR_CHANGE_DURATION)

	# Use Timer instead of callback - more reliable
	var total_duration = COLOR_CHANGE_DURATION + duration
	_create_cleanup_timer(total_duration + TIMEOUT_MARGIN, func():
		mark_animation_inactive(anim_id)
	)

	return true

# Shake node (screen shake, etc.) - works with Control or Node2D
func animate_shake(
		node: CanvasItem,
		intensity:		float 	= 15.0,
		duration:		float 	= 0.3,
		shake_count: 	int 	= 8
	):

	var anim_id = "shake_%s" % node.get_instance_id()

	if is_animation_active(anim_id):
		return false

	mark_animation_active(anim_id)

	var original_position = node.position

	# Create shake animation
	var tween = get_tree().create_tween()

	for i in range(shake_count):
		tween.parallel().tween_property(
			node, "position",
			original_position + Vector2(randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)),
			duration / shake_count
		)

	tween.tween_property(node, "position", original_position, duration / shake_count)

	# Use Timer instead of callback - more reliable
	_create_cleanup_timer(duration + TIMEOUT_MARGIN, func():
		if node and is_instance_valid(node):
			node.position = original_position

		mark_animation_inactive(anim_id)
	)

	return true

# Check if animation is currently active
func is_animation_active(animation_id: String):
	return active_animations.has(animation_id) and active_animations[animation_id] == true


# Mark animation as active
func mark_animation_active(animation_id: String):
	active_animations[animation_id] = true


# Fade out animation for green stars
func animate_star_fadeout(star: Node2D, duration: float = 1.5):
	if not star or not is_instance_valid(star):
		return false

	var anim_id = "star_fade_%d" % star.get_instance_id()

	if is_animation_active(anim_id):
		return false

	mark_animation_active(anim_id)

	# Force reset before animation
	star.scale      = Vector2.ONE
	star.modulate.a = 1.0

	# Create fade animation
	var tween = get_tree().create_tween()

	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(star, "modulate:a", 0.0, duration)
	tween.tween_property(star, "scale", Vector2(0.3, 0.3), duration)

	# Use Timer instead of tween.finished - more reliable
	_create_cleanup_timer(duration + TIMEOUT_MARGIN, func():
		mark_animation_inactive(anim_id)

		if star and is_instance_valid(star):
			star.queue_free()
	)

	return true


# Mark animation as inactive
func mark_animation_inactive(animation_id: String):
	active_animations.erase(animation_id)

# Force stop all animations
func stop_all_animations():
	active_animations.clear()

# Create and start a cleanup timer with callback
func _create_cleanup_timer(duration: float, callback: Callable):
	var cleanup_timer 		= Timer.new()
	cleanup_timer.wait_time = duration
	cleanup_timer.one_shot 	= true

	# Use a wrapper method to avoid lambda capture issues
	cleanup_timer.timeout.connect(_on_cleanup_timer_timeout.bind(cleanup_timer, callback))

	add_child(cleanup_timer)
	cleanup_timer.start()

	# Track timer for cleanup
	active_timers.append(cleanup_timer)

	return cleanup_timer

# Wrapper method to safely handle timer timeout
func _on_cleanup_timer_timeout(timer: Timer, callback: Callable):
	# Call callback - it will handle null captures internally with is_instance_valid() checks
	# The "Lambda capture freed" warning is harmless - just means an object was freed before timer fired
	callback.call_deferred()

	# Remove from tracking array
	var index = active_timers.find(timer)
	if index >= 0:
		active_timers.remove_at(index)

	# Clean up timer
	if is_instance_valid(timer):
		timer.queue_free()

# Animate floating text (move and fade out)
func animate_floating_text(label: Label, movement_offset: Vector2, duration: float = 1.0):
	if not label or not is_instance_valid(label):
		return false

	# Create tween and bind it to the label
	var tween = label.create_tween()

	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + movement_offset, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration)
	tween.chain()
	tween.tween_callback(label.queue_free)

	# Safety timer to force cleanup after duration + margin
	var safety_timer 		= Timer.new()
	safety_timer.wait_time 	= duration + TIMEOUT_MARGIN + 1.0
	safety_timer.one_shot 	= true

	label.add_child(safety_timer)

	safety_timer.timeout.connect(func():
		if is_instance_valid(label) and label.get_parent():
			label.queue_free()
	)

	safety_timer.start()

	return true


# Animate death effect (slow motion + red overlay)
func animate_death_effect(parent_node: Control):
	if not parent_node:
		return false

	var anim_id = "death_effect_%s" % parent_node.get_instance_id()

	if is_animation_active(anim_id):
		return false

	mark_animation_active(anim_id)

	# Activate slow motion
	Engine.time_scale = 0.15

	# Create red death overlay
	var death_overlay 		= ColorRect.new()
	death_overlay.color 	= Color(1, 0, 0, 0.0)
	death_overlay.z_index 	= 1000
	death_overlay.name 		= "DeathOverlay"

	death_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent_node.add_child(death_overlay)

	# Fade-in animation
	var tween = parent_node.create_tween()

	tween.tween_property(death_overlay, "color:a", 0.6, 0.2)

	return true


# Cleanup death effect (restore time scale and remove overlay)
func cleanup_death_effect(parent_node: Control):
	if not parent_node:
		return false

	var anim_id = "death_effect_%s" % parent_node.get_instance_id()

	# Restore normal time
	Engine.time_scale = 1.0

	# Remove death overlay
	var death_overlay = parent_node.get_node_or_null("DeathOverlay")
	if death_overlay:
		death_overlay.queue_free()

	mark_animation_inactive(anim_id)

	return true


# Create bonus ball explosion effect
func create_bonus_ball_explosion(explosion_position: Vector2, parent_node: Node):
	if not parent_node:
		return false

	# Create particle system for explosion
	var particles				= GPUParticles2D.new()
	particles.global_position 	= explosion_position
	particles.emitting 			= false
	particles.amount 			= 30
	particles.lifetime 			= 0.8
	particles.one_shot 			= true
	particles.explosiveness 	= 1.0

	# Create material for brown particles
	var material 					= ParticleProcessMaterial.new()
	material.direction 				= Vector3(0, -1, 0)
	material.spread 				= 180.0
	material.initial_velocity_min 	= 100.0
	material.initial_velocity_max 	= 200.0
	material.gravity 				= Vector3(0, 200, 0)
	material.scale_min 				= 0.8
	material.scale_max 				= 2.0
	material.color 					= Color(0.6, 0.4, 0.2, 1.0)  # Brown color

	particles.process_material = material

	# Create simple texture
	var texture 		= PlaceholderTexture2D.new()
	texture.size 		= Vector2(8, 8)
	particles.texture 	= texture

	# Add to parent node
	parent_node.add_child(particles)

	# Start emission
	particles.emitting = true

	# Remove particle system after animation using Timer
	var cleanup_timer 		= Timer.new()
	cleanup_timer.wait_time = 1.0
	cleanup_timer.one_shot 	= true

	particles.add_child(cleanup_timer)

	cleanup_timer.timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)

	cleanup_timer.start()

	return true

# Victory confetti animation for high score display
func animate_victory_confetti(parent_node: Control, duration: float = 3.5):
	if not parent_node:
		print("❌ Invalid parent node for victory confetti")
		return false

	if is_animation_active("victory_confetti"):
		print("⚠️ Victory confetti animation already active, skipping")
		return false

	print("🎉 Animating victory confetti")
	mark_animation_active("victory_confetti")

	var confetti_list: Array[Node] = []
	var animation_duration = 3.5

	# Use design viewport size (720x1280) not physical screen size
	var viewport_rect = parent_node.get_viewport().get_visible_rect()
	var screen_width  = viewport_rect.size.x
	var screen_height = viewport_rect.size.y

	for i in range(50):
		var confetti      = ColorRect.new()
		confetti.size     = Vector2(8, 8)
		confetti.color    = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.MAGENTA][i % 5]

		var center_x      = screen_width / 2
		var center_y      = screen_height / 2
		var start_pos_y   = center_y - randf_range(100, 200)
		var end_pos_y     = screen_height + 100

		confetti.position = Vector2(
			center_x + randf_range(-200, 200),
			start_pos_y
		)

		parent_node.add_child(confetti)
		confetti_list.append(confetti)

		var fall_duration     = randf_range(2.0, 4.0)
		var rotation_duration = randf_range(1.0, 3.0)
		var fade_duration     = randf_range(1.5, 3.0)

		# Create tween bound to the confetti node itself
		var tween = confetti.create_tween()
		tween.set_parallel(true)
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_QUAD)

		# All animations run in parallel
		tween.tween_property(confetti, "position:y", end_pos_y, fall_duration)
		tween.tween_property(confetti, "rotation", randf_range(-PI, PI), rotation_duration)
		tween.tween_property(confetti, "modulate:a", 0.0, fade_duration)

	_create_cleanup_timer(animation_duration + TIMEOUT_MARGIN, func():
		for confetti in confetti_list:
			if is_instance_valid(confetti):
				confetti.queue_free()
		mark_animation_inactive("victory_confetti")
	)

	return true
