# reviewed
extends Node

signal language_changed

var current_language 	= "en"
var available_languages = ["fr", "en"]

# Settings file path
const SETTINGS_PATH = "user://language_settings.cfg"



# Load
func _ready():
	load_basic_translations()
	load_settings()  # Load saved language or use default



func load_basic_translations():
	# EN
	var en_translation 		= Translation.new()
	en_translation.locale 	= "en"

	en_translation.add_message("START", 						"Start")
	en_translation.add_message("FREE_MODE",						"Free Mode")
	en_translation.add_message("RANKING", 						"Classic")
	en_translation.add_message("RANKING_TITLE", 				"Ranking")
	en_translation.add_message("OPTIONS", 						"Options")
	en_translation.add_message("PAUSE", 						"Pause")
	en_translation.add_message("QUIT", 							"Quit")
	en_translation.add_message("BACK", 							"Back")
	en_translation.add_message("RESUME", 						"Resume")
	en_translation.add_message("RESET_RANKING", 				"Reset ranking")
	en_translation.add_message("SUCCESS", 						"Success!")
	en_translation.add_message("MUSIC_ACTIVE",					"Switch off music")
	en_translation.add_message("MUSIC_INACTIVE",				"Switch on music")
	en_translation.add_message("SFX_ACTIVE",					"Switch off sound")
	en_translation.add_message("SFX_INACTIVE",					"Switch on sound")
	en_translation.add_message("SHIELD_CONTROL",				"Shield Control")
	en_translation.add_message("CONTROL_DIRECTION",				"Switch to zones")
	en_translation.add_message("CONTROL_ZONES",					"Switch to direction")
	en_translation.add_message("BONUS",							"Bonus")
	en_translation.add_message("SCORE", 						"Score")
	en_translation.add_message("TOTAL", 						"Total")
	en_translation.add_message("LIVES", 						"Lives")
	en_translation.add_message("DATE", 							"Date")
	en_translation.add_message("BONUS_LIFE_AD", 				"Start with bonus Life (Ad)")
	en_translation.add_message("NO_SCORES",						"No scores yet")

	en_translation.add_message("NEW_RECORD",					"New record!")
	en_translation.add_message("GAME_OVER",						"Game Over")
	en_translation.add_message("TIME_BONUS",					"Time Bonus")
	en_translation.add_message("FINAL_SCORE",					"Final Score")
	en_translation.add_message("LIVES_USED",					"Lives Used")
	en_translation.add_message("POSITION",						"Position")
	en_translation.add_message("LAST_CHANCE_AD",				"Last chance (Ad)")
	en_translation.add_message("REPLAY",						"Replay")
	en_translation.add_message("MENU",							"Menu")

	en_translation.add_message("ADVERTISEMENT",					"Advertisement")
	en_translation.add_message("AD_CONTENT",					"Discover our new game.")
	en_translation.add_message("AD_ENDS_IN",					"Ad ends in")
	en_translation.add_message("BACK_TO_MENU",					"Back to menu")
	en_translation.add_message("AD_FINISHED",					"Ad finished! Resuming game...")

	en_translation.add_message("BONUS_LIFE_TITLE",				"Bonus Life")
	en_translation.add_message("BONUS_LIFE_MESSAGE",			"Congratulations!\n\nYou will start your next\ngame with 4 lives instead of 3!")
	en_translation.add_message("BONUS_LIFE_OBTAINED",			"Bonus life obtained!")
	en_translation.add_message("AD_CLOSES_IN",					"Ad closes in")

	en_translation.add_message("FREE_MODE_TITLE",				"Free Mode")
	en_translation.add_message("GREEN_STAR_SPAWN_INTERVAL",		"Star spawn interval")
	en_translation.add_message("GREEN_STAR_LIFETIME",			"Star lifetime")
	en_translation.add_message("SHIELD_BOOST_PERCENT",			"Shield boost increase")
	en_translation.add_message("SHIELD_BOOST_DURATION",			"Shield boost duration")
	en_translation.add_message("SHIELD_MAX_ARC_PERCENT",		"Shield max arc")
	en_translation.add_message("SHIELD_HITS_FOR_BONUS_BALL",	"Hits for bonus ball")
	en_translation.add_message("MAX_BALLS_IN_SCENE",			"Max balls in scene")
	en_translation.add_message("START_GAME",					"Play")
	en_translation.add_message("RESET_TO_DEFAULT",				"Reset to Default")

	en_translation.add_message("TUTORIAL_1",					"Control the [color=#00FFFF]shield[/color] to block the [color=#00FFFF]blue ball[/color]")
	en_translation.add_message("TUTORIAL_2",					"[color=#33FF4D]Green stars[/color] temporarily enlarge the [color=#00FFFF]shield[/color]")
	en_translation.add_message("TUTORIAL_3",					"Change game controls as needed via [color=#FFA500]options[/color]")

	TranslationServer.add_translation(en_translation)

	# FR
	var fr_translation 		= Translation.new()
	fr_translation.locale 	= "fr"

	fr_translation.add_message("START", 						"Commencer")
	fr_translation.add_message("RANKING", 						"Classique")
	fr_translation.add_message("RANKING_TITLE",					"Classement")
	fr_translation.add_message("FREE_MODE",						"Mode Libre")
	fr_translation.add_message("OPTIONS", 						"Options")
	fr_translation.add_message("PAUSE", 						"Pause")
	fr_translation.add_message("QUIT", 							"Quitter")
	fr_translation.add_message("BACK", 							"Retour")
	fr_translation.add_message("RESUME", 						"Reprendre")
	fr_translation.add_message("RESET_RANKING",					"Effacer le classement")
	fr_translation.add_message("SUCCESS",						"OK!")
	fr_translation.add_message("MUSIC_ACTIVE",					"Désactiver la musique")
	fr_translation.add_message("MUSIC_INACTIVE",				"Activer la musique")
	fr_translation.add_message("SFX_ACTIVE",					"Désactiver les bruitages")
	fr_translation.add_message("SFX_INACTIVE",					"Activer les bruitages")
	fr_translation.add_message("SHIELD_CONTROL",				"Contrôle du bouclier")
	fr_translation.add_message("CONTROL_DIRECTION",				"Basculer en zone")
	fr_translation.add_message("CONTROL_ZONES",					"Basculer en direction")
	fr_translation.add_message("BONUS",							"Bonus")
	fr_translation.add_message("SCORE", 						"Score")
	fr_translation.add_message("TOTAL", 						"Total")
	fr_translation.add_message("LIVES", 						"Vies")
	fr_translation.add_message("DATE", 							"Date")
	fr_translation.add_message("BONUS_LIFE_AD", 				"Commencer avec une vie bonus (Pub)")
	fr_translation.add_message("NO_SCORES",						"Pas encore de scores")

	fr_translation.add_message("NEW_RECORD",					"Nouveau record !")
	fr_translation.add_message("GAME_OVER",						"Game Over")
	fr_translation.add_message("TIME_BONUS",					"Bonus temps")
	fr_translation.add_message("FINAL_SCORE",					"Score Final")
	fr_translation.add_message("LIVES_USED",					"Vies utilisées")
	fr_translation.add_message("POSITION",						"Position")
	fr_translation.add_message("LAST_CHANCE_AD",				"Dernière chance (Pub)")
	fr_translation.add_message("REPLAY",						"Rejouer")
	fr_translation.add_message("MENU",							"Menu")

	fr_translation.add_message("ADVERTISEMENT",					"Publicité")
	fr_translation.add_message("AD_CONTENT",					"Découvrez notre nouveau jeu !")
	fr_translation.add_message("AD_ENDS_IN",					"Pub termine dans")
	fr_translation.add_message("BACK_TO_MENU",					"Retour au menu")
	fr_translation.add_message("AD_FINISHED",					"Pub terminée ! Reprise du jeu...")

	fr_translation.add_message("BONUS_LIFE_TITLE",				"Vie Bonus")
	fr_translation.add_message("BONUS_LIFE_MESSAGE",			"Félicitations !\n\nVous allez commencer votre prochaine\npartie avec 4 vies au lieu de 3 !")
	fr_translation.add_message("BONUS_LIFE_OBTAINED",			"Vie bonus obtenue !")
	fr_translation.add_message("AD_CLOSES_IN",					"Pub se termine dans")

	fr_translation.add_message("FREE_MODE_TITLE",				"Mode Libre")
	fr_translation.add_message("GREEN_STAR_SPAWN_INTERVAL",		"Intervalle d'apparition des étoiles")
	fr_translation.add_message("GREEN_STAR_LIFETIME",			"Durée de vie des étoiles")
	fr_translation.add_message("SHIELD_BOOST_PERCENT",			"Agrandissement du bouclier")
	fr_translation.add_message("SHIELD_BOOST_DURATION",			"Durée d'agrandissement du bouclier")
	fr_translation.add_message("SHIELD_MAX_ARC_PERCENT",		"Arc maximum du bouclier")
	fr_translation.add_message("SHIELD_HITS_FOR_BONUS_BALL",	"Coups avant la création d'une balle bonus")
	fr_translation.add_message("MAX_BALLS_IN_SCENE",			"Nombre max de balles")
	fr_translation.add_message("START_GAME",					"Jouer")
	fr_translation.add_message("RESET_TO_DEFAULT",				"Réinitialiser")

	fr_translation.add_message("TUTORIAL_1",					"Contrôle le [color=#00FFFF]bouclier[/color] pour bloquer la [color=#00FFFF]balle[/color] bleue")
	fr_translation.add_message("TUTORIAL_2",					"Les [color=#33FF4D]étoiles[/color] vertes agrandissent le [color=#00FFFF]bouclier[/color] temporairement")
	fr_translation.add_message("TUTORIAL_3",					"Change les contrôles du jeu au besoin via les [color=#FFA500]options[/color]")

	TranslationServer.add_translation(fr_translation)

# Load language settings from file
func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)

	if err == OK:
		var saved_lang = config.get_value("language", "current", "en")
		set_language(saved_lang)
		print("✅ Language settings loaded: %s" % saved_lang)
	else:
		# No saved settings, use default
		set_language("en")
		print("ℹ️ No language settings file found, using default (en)")

# Save language settings to file
func save_settings():
	var config = ConfigFile.new()
	config.set_value("language", "current", current_language)

	var err = config.save(SETTINGS_PATH)
	if err == OK:
		print("✅ Language settings saved: %s" % current_language)
	else:
		print("❌ Failed to save language settings: error %d" % err)

func set_language(lang):
	if lang in available_languages:
		current_language = lang
		TranslationServer.set_locale(lang)
		language_changed.emit()
		save_settings()  # Save after changing language
	else:
		print("❌ ERROR: Unsupported language '", lang, "'. Available languages: ", available_languages)

func get_current_language():
	return current_language

func toggle_language(lang: String):
	if lang in available_languages:
		set_language(lang)
