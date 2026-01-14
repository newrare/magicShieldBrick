# reviewed
extends Node


# Utility to add a background image to a scene
func add_background(target: Node, texture_name: String, file_name: String):
	# Create TextureRect node
	var texture_bg  = TextureRect.new()
	texture_bg.name = texture_name

	# Load background image
	var bg_texture = load("res://assets/images/%s" % file_name)

	if bg_texture:
		# Configure texture display properties
		texture_bg.texture      = bg_texture
		texture_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_bg.expand_mode  = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

		texture_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		# Add to scene at first position (behind other elements)
		target.add_child(texture_bg)
		target.move_child(texture_bg, 0)
		return texture_bg

	return null

# Utility method for UI labels
func create_label(text, min_width, color, font_size):
	# Create label node
	var label                   = Label.new()
	label.text                  = text
	label.custom_minimum_size.x = min_width
	label.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER

	# Apply color and font styling
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)

	return label


# Utility method to style buttons with rounded corners
func style_button(button: Button, width: float = 280.0, height: float = 60.0):
	if not button:
		return

	# Apply rounded corners
	button.add_theme_constant_override("corner_radius_top_left", 40)
	button.add_theme_constant_override("corner_radius_top_right", 40)
	button.add_theme_constant_override("corner_radius_bottom_left", 40)
	button.add_theme_constant_override("corner_radius_bottom_right", 40)

	# Set margins
	button.add_theme_constant_override("margin_top", 5)
	button.add_theme_constant_override("margin_bottom", 5)

	# Set minimum size
	button.custom_minimum_size = Vector2(width, height)


# Utility method to style multiple buttons at once
func style_buttons(buttons: Array, width: float = 280.0, height: float = 60.0):
	# Apply style to each button in array
	for button in buttons:
		if button is Button:
			style_button(button, width, height)


# Utility method to center a button horizontally
func center_button(button: Button):
	if button:
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


# Utility method to create a custom button with image background and overlay
func create_custom_button(button_text: String = "", width: float = 280.0, height: float = 60.0):
	# Load custom button script
	var custom_button_script = load("res://components/CustomButton.gd")

	if not custom_button_script:
		push_error("CustomButton.gd not found!")
		return null

	# Create and configure button instance
	var button                 = Node.new()
	button.set_script(custom_button_script)
	button.custom_minimum_size = Vector2(width, height)
	button.text                = button_text

	return button
