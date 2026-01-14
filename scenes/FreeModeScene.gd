# reviewed
extends Control

# UI References
@onready var title_label 			= $CenterContainer/VBoxContainer/TitleLabel
@onready var scroll_container 		= $CenterContainer/VBoxContainer/ScrollContainer
@onready var settings_container 	= $CenterContainer/VBoxContainer/ScrollContainer/SettingsContainer
@onready var button_container 		= $CenterContainer/VBoxContainer/ButtonContainer
@onready var start_button 			= $CenterContainer/VBoxContainer/ButtonContainer/StartButton
@onready var back_button 			= $CenterContainer/VBoxContainer/ButtonContainer/BackButton
@onready var reset_button 			= $CenterContainer/VBoxContainer/ButtonContainer/ResetButton

# Slider references (dynamically created)
var sliders: Dictionary = {}

# Settings file path
const SETTINGS_PATH = "user://free_mode_settings.cfg"

# Default values for reset functionality (matching GameConstant defaults)
var default_values: Dictionary = {
	"GREEN_STAR_SPAWN_INTERVAL": 	5,
	"GREEN_STAR_LIFETIME": 			30,
	"SHIELD_BOOST_PERCENT": 		10,
	"SHIELD_BOOST_DURATION": 		10,
	"SHIELD_MAX_ARC_PERCENT": 		80,
	"SHIELD_HITS_FOR_BONUS_BALL": 	5,
	"MAX_BALLS_IN_SCENE": 			5
}

# Slider configurations: [min, max, step]
var slider_configs: Dictionary = {
	"GREEN_STAR_SPAWN_INTERVAL": 	[1, 	100, 	1],
	"GREEN_STAR_LIFETIME": 			[1, 	100, 	1],
	"SHIELD_BOOST_PERCENT": 		[10, 	90,		1],
	"SHIELD_BOOST_DURATION": 		[1,		100, 	1],
	"SHIELD_MAX_ARC_PERCENT": 		[60, 	90, 	1],
	"SHIELD_HITS_FOR_BONUS_BALL": 	[1, 	100, 	1],
	"MAX_BALLS_IN_SCENE": 			[1, 	30, 	1]
}



func _ready():
	create_sliders()
	set_text()
	connect_buttons()
	load_saved_settings()

# Create all sliders dynamically based on GameConstant properties
func create_sliders():
	for key in slider_configs.keys():
		var config 				= slider_configs[key]
		var slider_container 	= create_slider_group(key, config[0], config[1], config[2])

		settings_container.add_child(slider_container)

# Create a slider group with label and value display
func create_slider_group(constant_name: String, min_value: float, max_value: float, step_value: float):
	var group 	= VBoxContainer.new()
	group.name 	= constant_name + "_Group"

	# Header container with label and value
	var header_container           			= HBoxContainer.new()
	header_container.custom_minimum_size 	= Vector2(400, 0)
	header_container.size_flags_horizontal 	= Control.SIZE_EXPAND_FILL

	# Slider name label
	var name_label                    = Label.new()
	name_label.name                   = constant_name + "_Label"
	name_label.size_flags_horizontal  = Control.SIZE_EXPAND_FILL

	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	header_container.add_child(name_label)

	# Value label
	var value_label 	= Label.new()
	value_label.name	= constant_name + "_ValueLabel"

	value_label.add_theme_font_size_override("font_size", 18)
	value_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))  # Light green
	value_label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	header_container.add_child(value_label)

	group.add_child(header_container)

	# Slider with increased thickness
	var slider                  	= HSlider.new()
	slider.name                 	= constant_name + "_Slider"
	slider.min_value            	= min_value
	slider.max_value            	= max_value
	slider.step                 	= step_value
	slider.custom_minimum_size  	= Vector2(400, 50)
	slider.size_flags_horizontal	= Control.SIZE_EXPAND_FILL

	# Connect slider value change
	slider.value_changed.connect(_on_slider_value_changed.bind(constant_name, value_label))

	group.add_child(slider)

	# Store references
	sliders[constant_name] = {
		"slider": slider,
		"name_label": name_label,
		"value_label": value_label
	}

	# Add spacing
	group.add_theme_constant_override("separation", 10)

	return group

# Handle slider value changes
func _on_slider_value_changed(value: float, constant_name: String, value_label: Label):
	var int_value = int(value)

	# Update value label display
	value_label.text = str(int_value)

	# Update GameConstant
	_update_game_constant(constant_name, int_value)

	# Save settings after each change
	save_settings()

# Update GameConstant based on constant name and value
func _update_game_constant(constant_name: String, int_value: int):
	match constant_name:
		"GREEN_STAR_SPAWN_INTERVAL":
			GameConstant.GREEN_STAR_SPAWN_INTERVAL = int_value
		"GREEN_STAR_LIFETIME":
			GameConstant.GREEN_STAR_LIFETIME = int_value
		"SHIELD_BOOST_PERCENT":
			GameConstant.SHIELD_BOOST_PERCENT = int_value
		"SHIELD_BOOST_DURATION":
			GameConstant.SHIELD_BOOST_DURATION = int_value
		"SHIELD_MAX_ARC_PERCENT":
			GameConstant.SHIELD_MAX_ARC_PERCENT = int_value
		"SHIELD_HITS_FOR_BONUS_BALL":
			GameConstant.SHIELD_HITS_FOR_BONUS_BALL = int_value
		"MAX_BALLS_IN_SCENE":
			GameConstant.MAX_BALLS_IN_SCENE = int_value

func load_saved_settings():
	var config 	= ConfigFile.new()
	var err 	= config.load(SETTINGS_PATH)

	if err == OK:
		for key in default_values.keys():
			var value = config.get_value("settings", key, default_values[key])
			_set_slider_value(key, value)
		print("✅ Free mode settings loaded")
	else:
		# No saved settings, use defaults
		for key in default_values.keys():
			_set_slider_value(key, default_values[key])
		print("ℹ️ No saved settings, using defaults")

# Save settings to file
func save_settings():
	var config = ConfigFile.new()

	for key in sliders.keys():
		var value = int(sliders[key]["slider"].value)
		config.set_value("settings", key, value)

	var err = config.save(SETTINGS_PATH)

	if err == OK:
		print("✅ Free mode settings saved")
	else:
		print("❌ Failed to save free mode settings")

# Helper to set slider value
func _set_slider_value(constant_name: String, value: int):
	if sliders.has(constant_name):
		sliders[constant_name]["slider"].value = value
		sliders[constant_name]["value_label"].text = str(value)

		_update_game_constant(constant_name, value)

# Reset all values to default
func reset_to_default():
	for key in default_values.keys():
		_set_slider_value(key, default_values[key])

# Set all translated texts
func set_text():
	title_label.text 	= tr("FREE_MODE_TITLE")
	start_button.text 	= tr("START_GAME")
	back_button.text 	= tr("BACK")
	reset_button.text 	= tr("RESET_TO_DEFAULT")

	# Set slider labels
	for key in sliders.keys():
		sliders[key]["name_label"].text = tr(key)

# Connect button signals
func connect_buttons():
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	# Listen for language changes
	if LanguageManager:
		LanguageManager.language_changed.connect(set_text)

# Button callbacks
func _on_start_pressed():
	GameManager.set_free_mode(true)
	GameManager.change_scene("res://scenes/GameScene.tscn")

func _on_back_pressed():
	GameManager.change_scene("res://scenes/MainMenu.tscn")

func _on_reset_pressed():
	reset_to_default()
