# reviewed
extends Control

@onready var title_label  			= $VBoxContainer/TitleLabel
@onready var back_button  			= $VBoxContainer/ButtonContainer/BackButton
@onready var mode_buttons_container = $VBoxContainer/ModeButtonsContainer

var scores_container: 	VBoxContainer
var classic_button: 	TextureButton
var free_mode_button: 	TextureButton
var current_mode: 		String = "classic"

# UIButton script preload
const UIButton = preload("res://menus/widgets/UIButton.gd")

# Constants
const ROW_FONT_SIZE      	= 23
const ROW_MIN_HEIGHT     	= 44
const HEADER_FONT_SIZE   	= 18
const TITLE_FONT_SIZE    	= 56
const NO_SCORES_FONT_SIZE 	= 18
const COLUMN_COUNT       	= 6
const FALLBACK_WIDTH     	= 600



func _ready():
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
		back_button.text = tr("BACK")

	if title_label:
		title_label.text = tr("RANKING_TITLE")
		title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
		title_label.add_theme_color_override("font_color", Color.GOLD)

	# Create mode selection buttons
	setup_mode_buttons()

	# Create the scores container
	setup_scores_container()

	# Display the scores
	display_scores()



# Setup mode selection buttons
func setup_mode_buttons():
	if not mode_buttons_container:
		print("❌ ERROR: ModeButtonsContainer not found!")
		return

	# Classic button (UIButton)
	classic_button = TextureButton.new()
	classic_button.set_script(UIButton)
	classic_button.text = tr("RANKING")  # Use "RANKING" key which means "Classic"
	classic_button.custom_minimum_size = Vector2(150, 50)
	classic_button.pressed.connect(_on_classic_mode_pressed)

	# Free mode button (UIButton)
	free_mode_button = TextureButton.new()
	free_mode_button.set_script(UIButton)
	free_mode_button.text = tr("FREE_MODE")
	free_mode_button.custom_minimum_size = Vector2(150, 50)
	free_mode_button.pressed.connect(_on_free_mode_pressed)

	mode_buttons_container.add_child(classic_button)
	mode_buttons_container.add_child(free_mode_button)

	# Set initial button states
	update_button_styles()

# Update button visual states based on current mode
func update_button_styles():
	if current_mode == "classic":
		# Classic selected style (brighter, like hover)
		classic_button.modulate = Color(1.2, 1.2, 1.2, 1.0)
		classic_button.disabled = false

		# Free mode unselected style (dimmer)
		free_mode_button.modulate = Color(0.7, 0.7, 0.7, 1.0)
		free_mode_button.disabled = false
	else:
		# Classic unselected style (dimmer)
		classic_button.modulate = Color(0.7, 0.7, 0.7, 1.0)
		classic_button.disabled = false

		# Free mode selected style (brighter, like hover)
		free_mode_button.modulate = Color(1.2, 1.2, 1.2, 1.0)
		free_mode_button.disabled = false

# Switch to classic mode
func _on_classic_mode_pressed():
	if current_mode != "classic":
		current_mode = "classic"

		GameManager.set_free_mode(false)
		update_button_styles()
		display_scores()

# Switch to free mode
func _on_free_mode_pressed():
	if current_mode != "free_mode":
		current_mode = "free_mode"

		GameManager.set_free_mode(true)
		update_button_styles()
		display_scores()

func setup_scores_container():
	# Use the existing ScoresContainer from the scene
	var existing_scores_container = $VBoxContainer/ScoresContainer

	if not existing_scores_container:
		print("❌ ERROR: ScoresContainer not found in scene!")
		return

	var viewport_rect  = get_viewport_rect()
	var target_width   = min(int(viewport_rect.size.x * 0.95), 750)
	var target_height  = 640

	# Panel for transparent background
	var panel 					= Panel.new()
	panel.custom_minimum_size 	= Vector2(target_width, target_height)

	# Style panel with semi-transparent background
	var style_box                        = StyleBoxFlat.new()
	style_box.bg_color                   = Color(0.1, 0.1, 0.2, 0.7)
	style_box.border_width_left          = 2
	style_box.border_width_top           = 2
	style_box.border_width_right         = 2
	style_box.border_width_bottom        = 2
	style_box.border_color               = Color.GOLD
	style_box.corner_radius_top_left     = 10
	style_box.corner_radius_top_right    = 10
	style_box.corner_radius_bottom_left  = 10
	style_box.corner_radius_bottom_right = 10

	panel.add_theme_stylebox_override("panel", style_box)

	var scroll_container                    = ScrollContainer.new()
	scroll_container.custom_minimum_size    = Vector2(target_width - 20, target_height - 20)
	scroll_container.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	scores_container                        = VBoxContainer.new()
	scores_container.name                   = "ScoresVBox"
	scores_container.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	scores_container.size_flags_vertical    = Control.SIZE_EXPAND_FILL
	scores_container.alignment              = BoxContainer.ALIGNMENT_CENTER
	scores_container.add_theme_constant_override("separation", 2)

	scroll_container.add_child(scores_container)

	var margin_container = _create_margin_container(10)
	margin_container.add_child(scroll_container)

	panel.add_child(margin_container)

	# Add the panel to the existing ScoresContainer
	existing_scores_container.add_child(panel)



func display_scores():
	if not scores_container:
		print("❌ ERROR: Scores_container not found!")
		return

	# Empty the container
	for child in scores_container.get_children():
		child.queue_free()

	# Reload scores based on current mode
	ScoreManager.load_scores()

	# Get the scores
	var high_scores = ScoreManager.get_high_scores()

	if high_scores.is_empty():
		var no_scores_label                  = Label.new()
		no_scores_label.text                 = tr("NO_SCORES")
		no_scores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_scores_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		no_scores_label.size_flags_vertical  = Control.SIZE_EXPAND_FILL

		no_scores_label.add_theme_color_override("font_color", Color.WHITE)
		no_scores_label.add_theme_font_size_override("font_size", NO_SCORES_FONT_SIZE)
		scores_container.add_child(no_scores_label)

		return

	# Dynamic widths to occupy 100% of space
	# 6 columns: rank | date | lives | score | bonus | total

	var table_width = scores_container.get_parent().get_parent().custom_minimum_size.x
	if table_width <= 0:
		table_width = FALLBACK_WIDTH

	var col_size = int(table_width / COLUMN_COUNT)
	var col_widths = {
		"rank": 	col_size,
		"date": 	col_size,
		"lives": 	col_size,
		"score": 	col_size,
		"bonus": 	col_size,
		"total": 	col_size
	}

	# Create the column header
	var header_container = _create_header(col_widths)
	scores_container.add_child(header_container)

	# Separator line
	var separator = HSeparator.new()
	separator.add_theme_color_override("separator", Color.YELLOW)
	scores_container.add_child(separator)

	# Display each score with alternating background
	for i in range(high_scores.size()):
		var score_entry = high_scores[i]
		var rank        = i + 1
		var font_size   = ROW_FONT_SIZE
		var min_height  = ROW_MIN_HEIGHT

		# Panel for row with alternating background
		var row_panel = _create_row_panel(i, min_height)

		var score_container                   = HBoxContainer.new()
		score_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Rank
		var rank_color 					= _get_rank_color(rank)
		var rank_label                  = ToolsManager.create_label(str(rank) + ".", col_widths.rank, rank_color, font_size)
		rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		# Date
		var date_text					= _extract_date(score_entry)
		var date_label                  = ToolsManager.create_label(date_text, col_widths.date, Color.GRAY, font_size - 4)
		date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		# Lives
		var lives_used      = int(score_entry.get("lives_used", 0))
		var lives_container = _create_lives_container(lives_used, col_widths.lives, font_size)

		# Base score
		var base_score                        = int(score_entry.get("score", 0))
		var base_score_label                  = ToolsManager.create_label(str(base_score), col_widths.score, Color.WHITE, font_size)
		base_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		# Time bonus
		var time_bonus    					= int(score_entry.get("time_bonus", 0))
		var bonus_text    					= "+" + str(time_bonus) if time_bonus > 0 else "0"
		var bonus_color   					= Color.LIGHT_GREEN if time_bonus > 0 else Color.GRAY
		var bonus_label                  	= ToolsManager.create_label(bonus_text, col_widths.bonus, bonus_color, font_size)
		bonus_label.horizontal_alignment 	= HORIZONTAL_ALIGNMENT_CENTER

		# Final score
		var final_score       					= int(score_entry.get("final_score", base_score))
		var final_score_color 					= _get_rank_color(rank, Color.CYAN)
		var final_score_label                  	= ToolsManager.create_label(str(final_score), col_widths.total, final_score_color, font_size)
		final_score_label.horizontal_alignment 	= HORIZONTAL_ALIGNMENT_CENTER

		# Add all elements to row in new order: rank | date | lives | score | bonus | total
		score_container.add_child(rank_label)
		score_container.add_child(date_label)
		score_container.add_child(lives_container)
		score_container.add_child(base_score_label)
		score_container.add_child(bonus_label)
		score_container.add_child(final_score_label)

		# Add margin to row content
		var row_margin = _create_margin_container(5)
		row_margin.add_child(score_container)

		row_panel.add_child(row_margin)
		scores_container.add_child(row_panel)



func _on_back_pressed():
	# Reset to classic mode when leaving
	current_mode = "classic"
	GameManager.set_free_mode(false)
	GameManager.change_scene("res://scenes/MainMenu.tscn")


func _get_rank_color(rank: int, default_color: Color = Color.WHITE):
	if rank == 1:
		return Color.GOLD
	elif rank == 2:
		return Color.SILVER
	elif rank == 3:
		return Color.SANDY_BROWN
	else:
		return default_color


func _extract_date(score_entry: Dictionary):
	if not score_entry.has("date"):
		return ""

	var date_parts = score_entry.date.split("T")

	if date_parts.size() > 0:
		return date_parts[0]  # Format yyyy-mm-dd

	return ""


func _create_lives_container(lives_used: int, width: int, font_size: int):
	# Create wrapper container with fixed size
	var wrapper                   = Control.new()
	wrapper.custom_minimum_size.x = width
	wrapper.custom_minimum_size.y = font_size + 4
	wrapper.size_flags_horizontal = 0  # Don't expand
	wrapper.clip_contents         = false  # Allow overflow for visual effect

	# Heart size and overlap offset
	var heart_size      = font_size
	var overlap_offset  = 10  # Pixels of overlap between hearts

	# Calculate total width needed and starting position to center the stack
	var total_width     = heart_size + (lives_used - 1) * overlap_offset
	var start_x         = (width - total_width) / 2.0

	# Create hearts as overlapping stack
	for j in range(lives_used):
		var heart_texture                 = TextureRect.new()
		heart_texture.texture             = load("res://assets/images/heart.png")
		heart_texture.expand_mode         = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		heart_texture.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_texture.custom_minimum_size = Vector2(heart_size, heart_size)

		# Position with overlap
		heart_texture.position.x = start_x + (j * overlap_offset)
		heart_texture.position.y = 2

		wrapper.add_child(heart_texture)

	return wrapper


func _create_header(col_widths: Dictionary):
	var header_container                   = HBoxContainer.new()
	header_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Create header labels with fixed width (not expandable)
	header_container.add_child(_create_header_label("#", col_widths.rank))
	header_container.add_child(_create_header_label(tr("DATE"), col_widths.date))
	header_container.add_child(_create_header_label(tr("LIVES"), col_widths.lives))
	header_container.add_child(_create_header_label(tr("SCORE"), col_widths.score))
	header_container.add_child(_create_header_label(tr("BONUS"), col_widths.bonus))
	header_container.add_child(_create_header_label(tr("TOTAL"), col_widths.total))

	return header_container

func _create_header_label(text: String, width: int):
	var label                     = Label.new()
	label.text                    = text
	label.custom_minimum_size.x   = width
	label.size_flags_horizontal   = 0  # Don't expand, same as lives_container
	label.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER

	label.add_theme_color_override("font_color", Color.YELLOW)
	label.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)

	return label


func _create_row_panel(row_index: int, min_height: int):
	var row_panel                   = Panel.new()
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.custom_minimum_size.y = min_height

	var row_style = StyleBoxFlat.new()
	if row_index % 2 == 0:
		row_style.bg_color = Color(0.15, 0.15, 0.25, 0.3)  # Even row
	else:
		row_style.bg_color = Color(0.1, 0.1, 0.2, 0.2)  # Odd row

	row_panel.add_theme_stylebox_override("panel", row_style)
	return row_panel


func _create_margin_container(margin: int):
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", margin)
	margin_container.add_theme_constant_override("margin_top", margin)
	margin_container.add_theme_constant_override("margin_right", margin)
	margin_container.add_theme_constant_override("margin_bottom", margin)
	return margin_container
