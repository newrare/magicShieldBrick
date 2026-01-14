# reviewed
extends Node

var hearts: 				Array[Control] = []
var score_label: 			Label
var player_container: 		Node2D
var initial_score_position: Vector2



func initialize(hearts_array: Array[Control], score_lbl: Label, player: Node2D):
	hearts.clear()
	hearts.append_array(hearts_array)

	score_label			= score_lbl
	player_container	= player

	setup_hearts_style()
	setup_score_style()

	# Disconnect previous connections if any (for autoload reinitialization)
	if ScoreManager:
		if ScoreManager.score_changed.is_connected(_on_score_changed):
			ScoreManager.score_changed.disconnect(_on_score_changed)

		if ScoreManager.milestone_crossed.is_connected(_on_milestone_crossed):
			ScoreManager.milestone_crossed.disconnect(_on_milestone_crossed)

		# Connect to ScoreManager signals
		ScoreManager.score_changed.connect(_on_score_changed)
		ScoreManager.milestone_crossed.connect(_on_milestone_crossed)

func add_heart(heart: Control):
	if heart and heart not in hearts:
		hearts.append(heart)
		setup_heart_style(heart)


func update_lives_display(lives: int):
	# Show 'lives' number of hearts, hide the rest
	for i in range(hearts.size()):
		if hearts[i]:
			hearts[i].visible = (i < lives)

			# Reset visual properties for visible hearts
			if i < lives:
				hearts[i].modulate.a = 1.0
				hearts[i].position.y = 0


func setup_hearts_style():
	for heart in hearts:
		if heart:
			setup_heart_style(heart)


func setup_heart_style(heart: Control):
	if heart and heart is Label:
		heart.add_theme_color_override("font_color", Color.RED)
		heart.add_theme_font_size_override("font_size", 48)
		heart.add_theme_color_override("font_shadow_color", Color.BLACK)
		heart.add_theme_constant_override("shadow_offset_x", 3)
		heart.add_theme_constant_override("shadow_offset_y", 3)

		heart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		heart.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER


func heart_loss(current_lives_before_hit: int):
	var heart_index = current_lives_before_hit - 1

	if heart_index >= 0 and heart_index < hearts.size():
		var heart_to_animate = hearts[heart_index]

		if heart_to_animate:
			AnimationManager.animate_heart_loss(heart_to_animate)


func setup_score_style():
	if score_label:
		initial_score_position = score_label.position
		score_label.add_theme_font_size_override("font_size", 48)
		score_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0, 1.0))
		score_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
		score_label.add_theme_constant_override("shadow_offset_x", 3)
		score_label.add_theme_constant_override("shadow_offset_y", 3)

		score_label.horizontal_alignment	= HORIZONTAL_ALIGNMENT_CENTER
		score_label.vertical_alignment		= VERTICAL_ALIGNMENT_CENTER
		score_label.autowrap_mode			= TextServer.AUTOWRAP_OFF


# Called when score changes (connected to ScoreManager signal)
func _on_score_changed(new_score: int):
	if score_label:
		score_label.text = str(new_score)


# Called when milestone is crossed (connected to ScoreManager signal)
func _on_milestone_crossed(level: int, milestones_crossed: int):
	print("[UIManager] _on_milestone_crossed received: level=%d, milestones=%d" % [level, milestones_crossed])
	update_score_font_size(level)
	call_deferred("_trigger_milestone_animations", milestones_crossed)


func update_score_font_size(level: int):
	if not score_label:
		return

	# HARD CAP: Never exceed level 7 for font size calculation (6000+ points)
	var level_for_calc		= min(level, 7)
	var milestones			= level_for_calc - 1  # Level 1 = 0 milestones

	# Calculate dynamic font size (20% increase per milestone)
	# At level 7 (6000+ pts): 1.2^6 = 2.985 (~3x) = 143px max
	var base_font_size		= 48
	var font_multiplier		= pow(1.2, milestones)
	var new_font_size		= int(base_font_size * font_multiplier)

	# Update font size (the label anchors handle the centering automatically)
	score_label.add_theme_font_size_override("font_size", new_font_size)


func _trigger_milestone_animations(milestones_crossed: int):
	print("[UIManager] _trigger_milestone_animations called with milestones=%d" % milestones_crossed)
	# Wait for font change to complete, then animate
	await get_tree().process_frame

	# Delegate animations to AnimationManager
	AnimationManager.animate_score_bounce(score_label)
	AnimationManager.animate_player_spin(player_container, milestones_crossed)


func create_shield_floating_text(shield_position: Vector2, parent_node: Node):
	var font_size = 32

	# Create floating label with cyan color
	var floating_label = Label.new()
	floating_label.text = "+100"
	floating_label.z_index = 100
	floating_label.add_theme_font_size_override("font_size", font_size)
	floating_label.add_theme_color_override("font_color", Color.CYAN)

	# Position above shield center
	floating_label.position = shield_position + Vector2(-25, -80)

	# Add label to parent
	if not parent_node:
		return

	parent_node.add_child(floating_label)

	# Delegate animation to AnimationManager
	AnimationManager.animate_floating_text(floating_label, Vector2(0, -60), 1.0)
