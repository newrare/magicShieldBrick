# reviewed
extends Control

@onready var title_label 				= $VBoxContainer/TitleLabel
@onready var language_button 			= $VBoxContainer/OptionContainer/LanguageContainer/LanguageButton
@onready var music_button 				= $VBoxContainer/OptionContainer/AudioContainer/MusicContainer/MusicButton
@onready var sfx_button 				= $VBoxContainer/OptionContainer/AudioContainer/SFXContainer/SFXButton
@onready var reset_scores_button 		= $VBoxContainer/ResetScoresContainer/ResetScoresButton
@onready var success_message_container 	= $VBoxContainer/SuccessMessageContainer
@onready var back_button 				= $VBoxContainer/BackContainer/BackButton

# State for toggle buttons
var is_music_enabled: bool = true
var is_sfx_enabled: bool = true
var shield_control_button: TextureButton = null



# Load
func _ready():
	# Load button
	language_button.pressed.connect(_on_language_pressed)
	reset_scores_button.pressed.connect(_on_reset_scores_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Connect audio buttons
	music_button.pressed.connect(_on_music_button_pressed)
	sfx_button.pressed.connect(_on_sfx_button_pressed)

	# Create shield control button dynamically
	create_shield_control_button()

	# Initialize button states from AudioManager
	is_music_enabled = !AudioManager.is_music_muted
	is_sfx_enabled = !AudioManager.is_sfx_muted

	# Connect language change signal
	LanguageManager.language_changed.connect(_on_language_changed)

	# Set default text (first loading)
	set_text()

	# Overlay and Bacground
	ToolsManager.add_background(self, "OptionsMenuBackground", "option.png")

	if name == "OptionsMenuOverlay":
		setup_overlay_background()


func _exit_tree():
	# Disconnect signals to prevent memory leaks
	if LanguageManager.language_changed.is_connected(_on_language_changed):
		LanguageManager.language_changed.disconnect(_on_language_changed)


# Action
func _on_language_pressed():
	var current_lang = LanguageManager.get_current_language()

	if current_lang == "fr":
		LanguageManager.toggle_language("en")
	else:
		LanguageManager.toggle_language("fr")

func _on_back_pressed():
	if name == "OptionsMenuOverlay":
		# Return to game (pause menu)
		queue_free()
	else:
		# Return to title Menu
		GameManager.change_scene("res://scenes/MainMenu.tscn")

func _on_reset_scores_pressed():
	ScoreManager.reset_all_scores()

	var message = tr("SUCCESS")
	show_success_message(message)

func _on_music_button_pressed():
	# Toggle state
	is_music_enabled = !is_music_enabled

	# Update AudioManager
	AudioManager.update_music_state(!is_music_enabled)
	print("Music ", "enabled" if is_music_enabled else "disabled")

	# Update button text
	update_audio_button_texts()

func _on_sfx_button_pressed():
	# Toggle state
	is_sfx_enabled = !is_sfx_enabled

	# Update AudioManager
	AudioManager.update_sfx_state(!is_sfx_enabled)
	print("SFX ", "enabled" if is_sfx_enabled else "disabled")

	# Update button text
	update_audio_button_texts()

# When langue is update in Game
func _on_language_changed():
	set_text()


# Create shield control button
func create_shield_control_button():
	var audio_container = $VBoxContainer/OptionContainer/AudioContainer

	if not audio_container:
		return

	# Create container for shield control button
	var shield_container = CenterContainer.new()
	shield_container.name = "ShieldControlContainer"

	# Create the button
	var ui_button_script = preload("res://menus/widgets/UIButton.gd")
	shield_control_button = TextureButton.new()
	shield_control_button.custom_minimum_size = Vector2(280, 60)
	shield_control_button.set_script(ui_button_script)
	shield_control_button.pressed.connect(_on_shield_control_button_pressed)

	shield_container.add_child(shield_control_button)
	audio_container.add_child(shield_container)

	# Update button text
	update_shield_control_button_text()


func _on_shield_control_button_pressed():
	# Toggle control mode
	ControlManager.toggle_control_mode()
	print("Shield control mode toggled")

	# Update button text
	update_shield_control_button_text()


func update_shield_control_button_text():
	if not shield_control_button:
		return

	var mode_text = ""

	if ControlManager.is_direction_mode():
		mode_text = tr("CONTROL_DIRECTION")
	else:
		mode_text = tr("CONTROL_ZONES")

	shield_control_button.text = mode_text



# Set langue with traductions
func set_text():
	title_label.text 			= tr("OPTIONS")
	reset_scores_button.text 	= tr("RESET_RANKING")
	back_button.text 			= tr("BACK")

	var current_lang = LanguageManager.get_current_language()

	if current_lang == "fr":
		language_button.text = "Switch to English"
	else:
		language_button.text = "Basculer en Français"

	# Update audio button texts
	update_audio_button_texts()
	update_shield_control_button_text()

	title_label.add_theme_font_size_override("font_size", 56)
	title_label.add_theme_color_override("font_color", Color.GOLD)

# Update audio button texts based on current state
func update_audio_button_texts():
	if music_button:
		if is_music_enabled:
			music_button.text = "♪ " + tr("MUSIC_ACTIVE")
		else:
			music_button.text = "♪ " + tr("MUSIC_INACTIVE")

	if sfx_button:
		if is_sfx_enabled:
			sfx_button.text = "🔊 " + tr("SFX_ACTIVE")
		else:
			sfx_button.text = "🔊 " + tr("SFX_INACTIVE")

# Show Success message (for reset button)
func show_success_message(message: String):
	# Clear any existing message
	for child in success_message_container.get_children():
		child.queue_free()

	# Init message
	var success_label 	= Label.new()
	success_label.text 	= "✓ " + message
	success_label.add_theme_color_override("font_color", Color.GREEN)
	success_label.add_theme_font_size_override("font_size", 18)
	success_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Add message to the dedicated container
	success_message_container.add_child(success_label)

	# Animate appearance
	success_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(success_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(success_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(success_label.queue_free)

# Setup background (when option is called in game)
func setup_overlay_background():
	var vbox = $VBoxContainer
	if vbox:
		vbox.modulate = Color.WHITE
		for child in vbox.get_children():
			if child is Control:
				child.modulate = Color.WHITE
