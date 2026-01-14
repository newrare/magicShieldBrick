# reviewed
extends Node

# Default values (used for resets and normal mode)
var default_values: Dictionary = {
	"GREEN_STAR_SPAWN_INTERVAL": 	5,
	"GREEN_STAR_LIFETIME": 			30,
	"SHIELD_BOOST_PERCENT": 		10,
	"SHIELD_BOOST_DURATION": 		10,
	"SHIELD_MAX_ARC_PERCENT": 		80,
	"SHIELD_HITS_FOR_BONUS_BALL": 	5,
	"MAX_BALLS_IN_SCENE": 			5
}

# Green star spawn interval (second: 0 to 100)
@export var GREEN_STAR_SPAWN_INTERVAL: int = 5

# Green star lifetime (second: 1 to 100)
@export var GREEN_STAR_LIFETIME: int = 30

# Shield boost percentage added by green star (percent: 10 to 90)
@export var SHIELD_BOOST_PERCENT: int = 10

# Shield boost duration (second: 1 to 100)
@export var SHIELD_BOOST_DURATION: int = 10

# Shield max arc size (percent: 60 to 90)
@export var SHIELD_MAX_ARC_PERCENT: int = 80

# Shield hits before brown bonusBall creation (1 to 100)
@export var SHIELD_HITS_FOR_BONUS_BALL: int = 5

# Max number of balls in the scene (1 to 30)
@export var MAX_BALLS_IN_SCENE: int = 5


# Reset all constants to default values (called when switching to normal mode)
func reset_to_defaults():
	GREEN_STAR_SPAWN_INTERVAL 	= default_values["GREEN_STAR_SPAWN_INTERVAL"]
	GREEN_STAR_LIFETIME 		= default_values["GREEN_STAR_LIFETIME"]
	SHIELD_BOOST_PERCENT 		= default_values["SHIELD_BOOST_PERCENT"]
	SHIELD_BOOST_DURATION 		= default_values["SHIELD_BOOST_DURATION"]
	SHIELD_MAX_ARC_PERCENT 		= default_values["SHIELD_MAX_ARC_PERCENT"]
	SHIELD_HITS_FOR_BONUS_BALL 	= default_values["SHIELD_HITS_FOR_BONUS_BALL"]
	MAX_BALLS_IN_SCENE 			= default_values["MAX_BALLS_IN_SCENE"]
