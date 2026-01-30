# reviewed
extends Control

@onready var start_button 		= $VBoxContainer/ButtonContainer/StartButton
@onready var bonus_life_button 	= $VBoxContainer/ButtonContainer/BonusLifeButton
@onready var free_mode_button 	= $VBoxContainer/ButtonContainer/FreeModeButton
@onready var ranking_button 	= $VBoxContainer/ButtonContainer/RankingButton
@onready var options_button 	= $VBoxContainer/ButtonContainer/OptionsButton
@onready var quit_button 		= $VBoxContainer/ButtonContainer/QuitButton
@onready var title_image 		= $VBoxContainer/TitleImage
@onready var newrare_container 	= $NewrareContainer
@onready var newrare_image 		= $NewrareContainer/NewrareImage
@onready var newrare_label 		= $NewrareContainer/TextContainer/NewrareLabel
@onready var version_label 		= $NewrareContainer/TextContainer/VersionLabel

var background_sprite: TextureRect
var tween: Tween



# Load
func _ready():
	# Load background
	set_background()

	# Load Newrare branding
	set_newrare_branding()
	position_branding_at_bottom()

	# Load button
	start_button.pressed.connect(_on_start_pressed)
	bonus_life_button.pressed.connect(_on_bonus_life_pressed)
	free_mode_button.pressed.connect(_on_free_mode_pressed)
	ranking_button.pressed.connect(_on_ranking_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Spacing between buttons
	var button_container = $VBoxContainer/ButtonContainer
	button_container.add_theme_constant_override("separation", 20)

	# Set default text
	set_text()



# Action
func _on_start_pressed():
	print("Start pressed")
	GameManager.set_free_mode(false)
	GameManager.change_scene("res://scenes/GameScene.tscn")

func _on_bonus_life_pressed():
	print("Bonus life ad pressed")
	GameManager.set_free_mode(false)
	GameManager.change_scene("res://scenes/BonusLifeAdScene.tscn")

func _on_free_mode_pressed():
	print("Free mode pressed")
	GameManager.change_scene("res://scenes/FreeModeScene.tscn")

func _on_ranking_pressed():
	print("Ranking pressed")
	GameManager.change_scene("res://scenes/RankingScene.tscn")

func _on_options_pressed():
	print("Options pressed")
	GameManager.change_scene("res://scenes/OptionsMenu.tscn")

func _on_quit_pressed():
	# Stop and cleanup audio before quitting
	if AudioManager:
		AudioManager.cleanup()

	get_tree().quit()



# Set text translated
func set_text():
	start_button.text 		= tr("START")
	bonus_life_button.text 	= tr("BONUS_LIFE_AD")
	free_mode_button.text 	= tr("FREE_MODE")
	ranking_button.text 	= tr("RANKING_TITLE")
	options_button.text 	= tr("OPTIONS")
	quit_button.text 		= tr("QUIT")



# Set background with animation
func set_background():
	# Load background
	var title_texture = load("res://assets/images/title.png")

	if not title_texture:
		print("❌ ERROR: Impossible to load title texture for background!")
		return

	background_sprite 				= TextureRect.new()
	background_sprite.texture 		= title_texture
	background_sprite.name 			= "BackgroundTitleScreenImage"
	background_sprite.stretch_mode 	= TextureRect.STRETCH_KEEP_ASPECT_COVERED

	# Set Background position before VBoxContainer
	add_child(background_sprite)
	move_child(background_sprite, 1)

	# Background animation
	background_sprite.anchor_left	= 0.0
	background_sprite.anchor_top 	= 0.0
	background_sprite.anchor_right 	= 1.1
	background_sprite.anchor_bottom = 1.0
	background_sprite.offset_left 	= 0
	background_sprite.offset_top 	= 0
	background_sprite.offset_right 	= 0
	background_sprite.offset_bottom = 0

	await get_tree().process_frame

	var screen_width 				= get_viewport().get_visible_rect().size.x
	var start_x 					= 0.0
	var end_x 						= -screen_width * 1.0
	background_sprite.position.x 	= start_x

	tween = create_tween()
	tween.set_loops()
	tween.tween_property(background_sprite, "position:x", end_x, 15)
	tween.tween_property(background_sprite, "position:x", start_x, 15)


# Set Newrare branding (image + text)
func set_newrare_branding():
	# Load Newrare logo
	var newrare_texture = load("res://assets/images/newrare.png")

	if newrare_texture and newrare_image:
		newrare_image.texture = newrare_texture
		newrare_image.custom_minimum_size = Vector2(80, 80)

	# Set branding text
	if newrare_label:
		newrare_label.text = "A Newrare Game"
		newrare_label.add_theme_font_size_override("font_size", 18)
		newrare_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))

	# Load and display version dynamically
	if version_label:
		var config 	= ConfigFile.new()
		var version = "1.0"

		if config.load("res://project.godot") == OK:
			version = config.get_value("application", "config/version", "1.0")

		version_label.text = "v" + version
		version_label.add_theme_font_size_override("font_size", 14)
		version_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))

# Position branding
func position_branding_at_bottom():
	if newrare_container:
		await get_tree().process_frame

		# Adjust the offset to position at 2% bottom and left
		var screen_size 	= get_viewport().get_visible_rect().size
		var margin_bottom 	= screen_size.y * 0.01
		var margin_left 	= screen_size.x * 0.02

		newrare_container.offset_left 	= margin_left
		newrare_container.offset_top 	= -100.0 - margin_bottom
		newrare_container.offset_bottom = -margin_bottom
