# reviewed
extends Node

const SAVE_FILE				= "user://scores.save"
const FREE_MODE_SAVE_FILE	= "user://scores_free_mode.save"
const MAX_SCORES			= 10
const MILESTONE_INTERVAL	= 1000  # Score increment per level

var high_scores: Array			= []
var current_score: int			= 0
var last_milestone_score: int	= 0  # Last milestone crossed for animations

# Signals for score events
signal score_changed(new_score: int)
signal milestone_crossed(level: int, milestones_crossed: int)

func _ready():
	load_scores()

# Get the appropriate save file based on game mode
func get_save_file():
	if GameManager.get_is_free_mode():
		return FREE_MODE_SAVE_FILE

	return SAVE_FILE

# Load scores from the appropriate file
func load_scores():
	var save_file = get_save_file()

	if FileAccess.file_exists(save_file):
		var file = FileAccess.open(save_file, FileAccess.READ)

		if file:
			var json_string		= file.get_as_text()
			file.close()

			var json			= JSON.new()
			var parse_result	= json.parse(json_string)

			if parse_result == OK:
				high_scores = json.data
				migrate_old_scores()

				var mode = "FREE MODE" if GameManager.get_is_free_mode() else "CLASSIC"
				print("Scores loaded (%s): %s" % [mode, high_scores])
			else:
				print("Error parsing scores file")
				initialize_empty_scores()
	else:
		var mode = "FREE MODE" if GameManager.get_is_free_mode() else "CLASSIC"
		print("No scores file found (%s), creating new one" % mode)
		initialize_empty_scores()


# Save scores to the appropriate file
func save_scores():
	var save_file = get_save_file()
	var file = FileAccess.open(save_file, FileAccess.WRITE)

	if file:
		file.store_string(JSON.stringify(high_scores))
		file.close()
		var mode = "FREE MODE" if GameManager.get_is_free_mode() else "CLASSIC"
		print("Scores saved (%s): %s" % [mode, high_scores])


# Migrate old scores (compatibility)
func migrate_old_scores():
	var needs_save = false

	for score_entry in high_scores:
		if not score_entry.has("lives_used"):
			score_entry["lives_used"]		= 0
			score_entry["time_bonus"]		= 0
			score_entry["initial_lives"]	= 3
			score_entry["final_score"]		= score_entry.get("score", 0)
			needs_save						= true

	if needs_save:
		print("Migrated old scores to new format")
		save_scores()


# Initialize empty scores list
func initialize_empty_scores():
	high_scores = []
	save_scores()


# Check if score would be a new high score (first place)
func is_new_high_score(new_score: int):
	# First score
	if high_scores.is_empty():
		return true

	var current_best = high_scores[0].score

	return new_score > current_best


# Add new score and return its rank (1-based, 0 if not in top 10)
func add_score(new_score: int, lives_used: int = 0, time_bonus: int = 0, initial_lives: int = 3):
	var score_entry = {
		"score":			new_score,
		"date":				Time.get_datetime_string_from_system(),
		"lives_used":		lives_used,
		"time_bonus":		time_bonus,
		"initial_lives":	initial_lives,
		"final_score":		new_score + time_bonus
	}

	high_scores.append(score_entry)

	# Sort by total score descending, then by lives used ascending if tied
	high_scores.sort_custom(_compare_scores)

	# Keep only top 10
	if high_scores.size() > MAX_SCORES:
		high_scores = high_scores.slice(0, MAX_SCORES)

	# Find position of new score
	for i in range(high_scores.size()):
		if high_scores[i].score == new_score and high_scores[i].lives_used == lives_used:
			save_scores()
			return i + 1

	save_scores()

	# Not in top 10
	return 0


# Score comparison function for sorting
func _compare_scores(a: Dictionary, b: Dictionary):
	var score_a = a.get("final_score", a.get("score", 0))
	var score_b = b.get("final_score", b.get("score", 0))

	# First sort by total score descending
	if score_a != score_b:
		return score_a > score_b

	# If tied, the one who used fewer lives ranks better
	var lives_a = a.get("lives_used", 0)
	var lives_b = b.get("lives_used", 0)

	if lives_a != lives_b:
		return lives_a < lives_b

	# If score and lives identical, favor older entry (smaller date)
	var date_a = a.get("date", "")
	var date_b = b.get("date", "")

	return date_a < date_b  # Smaller date = older = better rank


# Get all scores
func get_high_scores():
	return high_scores


# Get rank preview of a score without adding it
func get_rank_preview(score: int):
	var temp_scores = high_scores.duplicate()
	temp_scores.append({"score": score})
	temp_scores.sort_custom(func(a, b): return a.score > b.score)

	for i in range(temp_scores.size()):
		if temp_scores[i].score == score and not temp_scores[i].has("date"):
			# Return rank only if in top 10
			if i < MAX_SCORES:
				return i + 1

	# Not in top 10
	return 0


# Clear all scores (complete reset)
func reset_all_scores():
	high_scores.clear()
	save_scores()

	# Also delete the other mode's save file
	var classic_file 	= SAVE_FILE
	var free_mode_file 	= FREE_MODE_SAVE_FILE

	if FileAccess.file_exists(classic_file):
		DirAccess.remove_absolute(classic_file)
		print("✓ Deleted classic mode scores")

	if FileAccess.file_exists(free_mode_file):
		DirAccess.remove_absolute(free_mode_file)
		print("✓ Deleted free mode scores")

	print("All scores have been cleared (classic + free mode)!")

# Initialize current game score
func start_game():
	current_score = 0
	last_milestone_score = 0


# Get current score
func get_score():
	return current_score

# Set score directly (use sparingly, prefer add_points)
func set_score(value: int):
	current_score = value
	score_changed.emit(current_score)

# Add points to current score
func add_points(points: int):
	var previous_level = get_current_level()
	current_score += points
	print("[ScoreManager] add_points: +%d pts -> score=%d, prev_level=%d" % [points, current_score, previous_level])

	# Check milestone crossing
	var current_level = get_current_level()
	if current_level > previous_level:
		var milestones_crossed 	= current_level - previous_level
		last_milestone_score 	= current_level * MILESTONE_INTERVAL

		print("[ScoreManager] MILESTONE CROSSED: level=%d, milestones=%d" % [current_level, milestones_crossed])
		milestone_crossed.emit(current_level, milestones_crossed)

	score_changed.emit(current_score)


# Get current level (1-based: 0-999 = level 1, 1000-1999 = level 2, etc.)
func get_current_level():
	return int(current_score / MILESTONE_INTERVAL) + 1


# Get score range for current level
func get_level_range():
	var level = get_current_level()
	return {
		"level":	level,
		"min":		(level - 1) * MILESTONE_INTERVAL,
		"max":		level * MILESTONE_INTERVAL - 1
	}


# Get progress to next milestone (0.0 to 1.0)
func get_milestone_progress():
	var level_range			= get_level_range()
	var points_in_level		= current_score - level_range.min
	var points_needed		= MILESTONE_INTERVAL
	return float(points_in_level) / float(points_needed)


# Get points until next milestone
func get_points_to_next_milestone():
	var level_range = get_level_range()
	return level_range.max - current_score + 1


# Check if score is at a milestone boundary
func is_at_milestone():
	return current_score % MILESTONE_INTERVAL == 0 and current_score > 0


# Get last milestone score (for animation tracking)
func get_last_milestone_score():
	return last_milestone_score


# Update last milestone score (used by UIManager for animation sync)
func update_last_milestone_score(score: int):
	last_milestone_score = score


# Get dynamic wall points based on current score
func get_wall_points():
	if current_score < 1000:
		return 10
	elif current_score < 2000:
		return 20
	elif current_score < 3000:
		return 30
	elif current_score < 4000:
		return 40
	else:
		return 50


# Calculate final score with time bonus
func calculate_final_score(base_score: int, time_bonus: int):
	return base_score + time_bonus
