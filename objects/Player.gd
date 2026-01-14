# reviewed
extends Area2D

enum PlayerState { NORMAL, HURT }

var current_state  = PlayerState.NORMAL
var hurt_timer:    Timer

var normal_sprite: Sprite2D
var hurt_sprite:   Sprite2D


func create_hurt_timer():
	var timer       = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot  = true
	timer.timeout.connect(_on_hurt_timer_timeout)
	add_child(timer)

	return timer

func _ready():
	# Initialize hurt state timer
	hurt_timer = create_hurt_timer()

	# Set rendering priority above shield
	z_index = 10
	visible = true
	modulate = Color.WHITE

	# Setup sprite system
	setup_sprites()
	update_sprite_visibility()
	queue_redraw()


func _exit_tree():
	# Clean up timer
	if hurt_timer:
		if hurt_timer.timeout.is_connected(_on_hurt_timer_timeout):
			hurt_timer.timeout.disconnect(_on_hurt_timer_timeout)
		hurt_timer.queue_free()


func setup_sprites():
	# Create normal state sprite
	normal_sprite = Sprite2D.new()

	if normal_sprite == null:
		return

	# Load and configure normal texture
	var normal_path = "res://assets/images/player.png"
	ResourceLoader.set_abort_on_missing_resources(false)
	var normal_texture = ResourceLoader.load(normal_path, "", ResourceLoader.CACHE_MODE_REPLACE)

	if normal_texture != null:
		normal_sprite.texture = normal_texture
		normal_sprite.z_index = 15
		normal_sprite.scale   = Vector2(0.33, 0.33)
		add_child(normal_sprite)

	# Create hurt state sprite
	hurt_sprite = Sprite2D.new()

	if hurt_sprite != null:
		# Load and configure hurt texture
		var hurt_path = "res://assets/images/player_hurt.png"
		var hurt_texture = ResourceLoader.load(hurt_path, "", ResourceLoader.CACHE_MODE_REPLACE)

		if hurt_texture != null:
			hurt_sprite.texture = hurt_texture
			hurt_sprite.z_index = 15
			hurt_sprite.scale   = Vector2(0.33, 0.33)
			hurt_sprite.visible = false
			add_child(hurt_sprite)


func update_sprite_visibility():
	# Show appropriate sprite based on current state
	if normal_sprite and hurt_sprite and normal_sprite.texture and hurt_sprite.texture:
		normal_sprite.visible = (current_state == PlayerState.NORMAL)
		hurt_sprite.visible   = (current_state == PlayerState.HURT)

func set_hurt():
	# Switch to hurt state for temporary invincibility
	current_state = PlayerState.HURT

	# Ensure timer exists
	if not hurt_timer:
		hurt_timer = create_hurt_timer()

	# Start invincibility period
	hurt_timer.start()
	update_sprite_visibility()


func _on_hurt_timer_timeout():
	# Return to normal state after invincibility period
	current_state = PlayerState.NORMAL
	update_sprite_visibility()


func is_invincible():
	return current_state == PlayerState.HURT
