# reviewed
extends TextureButton

var label: Label
var _text: String = ""

var text: String:
	get:
		return _text
	set(value):
		_text = value
		if label:
			label.text = value

func _ready():
	# Set button size to 70% of viewport width only if no custom size is set
	if custom_minimum_size == Vector2.ZERO:
		var viewport_width  = get_viewport_rect().size.x
		var button_width    = int(viewport_width * 0.7)
		custom_minimum_size = Vector2(button_width, 60)

	# Load textures
	var button_texture          = load("res://assets/images/button.png")
	var button_hover_texture    = load("res://assets/images/button_hover.png")

	if button_texture:
		texture_normal      = button_texture
		texture_disabled    = button_texture

	if button_hover_texture:
		texture_hover   = button_hover_texture
		texture_pressed = button_hover_texture

	# Use container size (not native texture size)
	stretch_mode        = STRETCH_SCALE
	ignore_texture_size = true

	# Setup text style
	label                       = Label.new()
	label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER

	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)

	# Apply text if it was set before _ready()
	if _text != "":
		label.text = _text

	# Play sound by events (works for both mouse and touch)
	mouse_entered.connect(_on_mouse_entered)
	pressed.connect(_on_pressed)

	# Additional touch support: play hover sound on button_down for touch devices
	button_down.connect(_on_button_down)

func _is_mobile_platform():
	var os_name = OS.get_name()
	return os_name == "Android" or os_name == "iOS"

func _on_mouse_entered():
	# Play hover sound on desktop (mouse has hover concept)
	# Skip on mobile (no hover concept with touch)
	if AudioManager and not _is_mobile_platform():
		AudioManager.play_sfx_button_hover()

func _on_button_down():
	# Play hover sound for mobile devices (when finger touches button)
	# This provides tactile feedback similar to hover on desktop
	if AudioManager and _is_mobile_platform():
		AudioManager.play_sfx_button_hover()

func _on_pressed():
	if AudioManager:
		AudioManager.play_sfx_button_click()
