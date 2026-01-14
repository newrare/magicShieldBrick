# reviewed
extends Node

var game_start_time : float = 0.0
var initial_lives    : int   = 3
var lives_used       : int   = 0
var game_duration    : float = 0.0

func start_game(starting_lives: int = 3):
	game_start_time = Time.get_unix_time_from_system()
	initial_lives   = starting_lives
	lives_used      = 0
	game_duration   = 0.0

func record_life_lost():
	lives_used += 1

func end_game():
	var end_time = Time.get_unix_time_from_system()
	game_duration = end_time - game_start_time

	var stats = {
		"initial_lives"          : initial_lives,
		"lives_used"             : lives_used,
		"game_duration_seconds"  : int(game_duration),
		"time_bonus"             : int(game_duration)
	}

	return stats
