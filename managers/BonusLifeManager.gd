# reviewed
extends Node

# Manages the bonus life earned through advertisement reward system
var bonus_life_earned = false

func earn_bonus_life():
	bonus_life_earned = true

func use_bonus_life():
	var had_bonus 		= bonus_life_earned
	bonus_life_earned 	= false

	return had_bonus

func has_bonus_life():
	return bonus_life_earned

func reset_bonus_life():
	bonus_life_earned = false