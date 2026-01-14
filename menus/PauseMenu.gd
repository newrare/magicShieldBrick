# reviewed
extends Control

@onready var title_label 		= $VBoxContainer/TitleLabel
@onready var resume_button 		= $VBoxContainer/ButtonContainer/ResumeButton
@onready var options_button 	= $VBoxContainer/ButtonContainer/OptionsButton
@onready var main_menu_button 	= $VBoxContainer/ButtonContainer/MainMenuButton



# Load
func _ready():
	# Style title label (same as RankingMenu)
	if title_label:
		title_label.add_theme_font_size_override("font_size", 56)
		title_label.add_theme_color_override("font_color", Color.GOLD)

	# Spacing between buttons (same as MainMenu)
	var button_container = $VBoxContainer/ButtonContainer
	if button_container:
		button_container.add_theme_constant_override("separation", 20)

	# Load button
	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	# Load Lang (for update)
	LanguageManager.language_changed.connect(_on_language_changed)

	# Set default text (first loading)
	set_text()


func _exit_tree():
	# Disconnect signals to prevent memory leaks
	if LanguageManager.language_changed.is_connected(_on_language_changed):
		LanguageManager.language_changed.disconnect(_on_language_changed)


# When langue is update in Game
func _on_language_changed():
	set_text()

# Action
func _on_resume_pressed():
	get_parent().get_parent().toggle_pause()

func _on_options_pressed():
	get_parent().get_parent().go_to_options()

func _on_main_menu_pressed():
	get_parent().get_parent().go_to_main_menu()

# Close PauseMenu with escape keyboard key
func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()



# Set langue with traductions
func set_text():
	title_label.text 		= tr("PAUSE")
	resume_button.text 		= tr("RESUME")
	options_button.text 	= tr("OPTIONS")
	main_menu_button.text 	= tr("QUIT")
