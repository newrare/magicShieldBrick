# reviewed
extends Node

# Default volume off for Godot (best practice)
var volume_off: 	float = -80.0
var volume_reduced: float = -40.0

# Sound
var sounds = {
	"music_background":	{"stream": null, "audio": null, "file": "res://assets/sounds/music_background.mp3", 	"volume": -19.0},
	"sfx_shield":		{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_shield.mp3",			"volume": -5.0},
	"sfx_player":		{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_player.wav",			"volume": -5.0},
	"sfx_game_over":	{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_game_over.mp3",		"volume": -5.0},
	"sfx_win":			{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_win.mp3",				"volume": -5.0},
	"sfx_button_hover":	{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_button_hover.wav",		"volume": -10.0},
	"sfx_button_click":	{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_button_click.wav",		"volume": -10.0}
}

# Mute state flags
var is_music_muted:		bool = false
var is_sfx_muted:		bool = false
var is_music_before: 	bool = false
var is_music_reduced: 	bool = false
var is_cleaned_up:		bool = false

# Settings file path
const SETTINGS_PATH = "user://audio_settings.cfg"



##################
### METHODS GD ###
##################

# Load
func _ready():
	load_settings()
	setup_audio_players()
	load_audio_resources()
	start_music_background()

	print("🎵 AudioManager ready")


# Cleanup - called when the node is about to be removed
func _exit_tree():
	cleanup()


# Also catch window close events
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		cleanup()
		get_tree().quit()
	elif what == NOTIFICATION_PREDELETE:
		cleanup()

# Stop and disconnect all audio players
func cleanup():
	# Prevent double cleanup
	if is_cleaned_up:
		return

	is_cleaned_up = true

	print("🧹 AudioManager cleanup starting...")

	for key in sounds.keys():
		var sound = sounds[key]

		if sound["audio"]:
			# Disconnect signals
			if key == "music_background" and sound["audio"].finished.is_connected(_on_music_finished):
				sound["audio"].finished.disconnect(_on_music_finished)

			# CRITICAL: Stop playback first
			if sound["audio"].playing:
				sound["audio"].stop()

			# Clear stream from player BEFORE removing from tree
			sound["audio"].stream = null

			# Remove from tree and free immediately (not deferred)
			if sound["audio"].get_parent():
				remove_child(sound["audio"])

			# Use free() instead of queue_free() during cleanup to ensure immediate deallocation
			sound["audio"].free()
			sound["audio"] = null

		# This is crucial for preventing resource leaks with loaded audio files
		if sound["stream"]:
			sound["stream"] = null

	# Clear the entire sounds dictionary
	sounds.clear()

	print("✓ AudioManager cleanup completed")

# Event
func _on_music_finished():
	var music = sounds["music_background"]

	if music["audio"] and music["stream"]:
		music["audio"].play()
		print("🔄 Background music looped")



###############
### METHODS ###
###############

# Set player
func setup_audio_players():
	for key in sounds.keys():
		var sound			= sounds[key]
		var audio			= AudioStreamPlayer.new()

		audio.name			= key
		audio.volume_db		= sound["volume"]
		audio.process_mode	= Node.PROCESS_MODE_ALWAYS
		sound["audio"]		= audio

		add_child(audio)

# Set file
func load_audio_resources():
	for key in sounds.keys():
		var sound	= sounds[key]
		var path	= sound["file"]

		if ResourceLoader.exists(path):
			# Load with default cache mode (Godot handles cleanup automatically)
			var stream: AudioStream = load(path)

			if stream:
				sound["stream"] = stream
				if sound["audio"]:
					sound["audio"].stream = stream
				print("✅ Loaded: %s" % path)
			else:
				print("❌ Failed to load %s" % path)
		else:
			print("❌ File not found: %s" % path)



# Start music
func start_music_background():
	var music = sounds["music_background"]

	if not music["audio"] or not music["stream"]:
		print("❌ Cannot start music background: missing audio player or stream")
		return

	music["audio"].stream = music["stream"]

	# Connect signal only if not already connected
	if not music["audio"].finished.is_connected(_on_music_finished):
		music["audio"].finished.connect(_on_music_finished)

	# Apply mute state before playing
	if is_music_muted:
		music["audio"].volume_db = volume_off
		print("🔇 Music background started (muted)")
	else:
		music["audio"].volume_db = music["volume"]
		print("🎵 Music background started")

	music["audio"].play()



# Play sfx player (hurt)
func play_sfx_player():
	if is_sfx_muted:
		return

	var hurt = sounds["sfx_player"]
	if not hurt["audio"] or not hurt["stream"]:
		print("❌ Cannot play hurt sfx: missing audio player or stream")
		return

	hurt["audio"].play()

# Play sfx button hover
func play_sfx_button_hover():
	if is_sfx_muted:
		return

	var hover = sounds["sfx_button_hover"]

	if not hover["audio"] or not hover["stream"]:
		print("❌ Cannot play button hover sfx: missing audio player or stream")
		return

	hover["audio"].play()

# Play sfx button click
func play_sfx_button_click():
	if is_sfx_muted:
		return

	var click = sounds["sfx_button_click"]
	if not click["audio"] or not click["stream"]:
		print("❌ Cannot play button click sfx: missing audio player or stream")
		return

	click["audio"].play()

# Play sfx shield
func play_sfx_shield():
	if is_sfx_muted:
		return

	var shield = sounds["sfx_shield"]
	if not shield["audio"] or not shield["stream"]:
		print("❌ Cannot play shield sfx: missing audio player or stream")
		return

	shield["audio"].play()

# Play sfx game over
func play_game_over(is_top3: bool = false):
	if is_sfx_muted:
		return

	var over = sounds["sfx_game_over"]
	var win  = sounds["sfx_win"]

	if is_top3:
		if not win["audio"] or not win["stream"]:
			print("❌ Cannot play win sfx: missing audio player or stream")
			return

		win["audio"].play()
		print("🏆 Win sfx played")
	else:
		if not over["audio"] or not over["stream"]:
			print("❌ Cannot play game over sfx: missing audio player or stream")
			return

		over["audio"].play()
		print("💀 Game over sfx played")



# Load settings from file
func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)

	if err == OK:
		is_music_muted = config.get_value("audio", "music_muted", false)
		is_sfx_muted = config.get_value("audio", "sfx_muted", false)
		print("✅ Audio settings loaded: Music muted=%s, SFX muted=%s" % [is_music_muted, is_sfx_muted])
	else:
		print("ℹ️ No audio settings file found, using defaults")

# Save settings to file
func save_settings():
	var config = ConfigFile.new()

	config.set_value("audio", "music_muted", is_music_muted)
	config.set_value("audio", "sfx_muted", is_sfx_muted)

	var err = config.save(SETTINGS_PATH)

	if err == OK:
		print("✅ Audio settings saved")
	else:
		print("❌ Failed to save audio settings: error %d" % err)

# Mute or unmute music
func update_music_state(is_muted: bool):
	is_music_muted	= is_muted
	var music		= sounds["music_background"]

	if not music["audio"] or not music["stream"]:
		print("❌ Cannot update music background: missing audio player or stream")
		return

	if is_muted:
		music["audio"].volume_db = volume_off
		music["audio"].stop()
		print("🔇 Music background muted")
	else:
		music["audio"].volume_db = music["volume"]

		if not music["audio"].playing:
			music["audio"].play()

		print("🔊 Music background unmuted and playing")

	# Save settings
	save_settings()

# Mute or unmute all sfx
func update_sfx_state(is_muted: bool):
	is_sfx_muted = is_muted

	for key in sounds.keys():
		if not key.begins_with("sfx"):
			continue

		var sound = sounds[key]

		if not sound["audio"] or not sound["stream"]:
			print("❌ Cannot update sfx for %s: missing audio player or stream" % key)
			continue

		if is_muted:
			sound["audio"].volume_db = volume_off
			print("🔇 SFX %s muted" % key)
		else:
			sound["audio"].volume_db = sound["volume"]
			print("🔊 SFX %s unmuted" % key)

	# Save settings
	save_settings()


# Reduce music volume temporarily (for game over menu overlay)
func reduce_music_for_overlay():
	if is_music_reduced:
		print("⚠️ Music already reduced, skipping")
		return

	if not sounds.has("music_background"):
		print("❌ Cannot reduce music: sounds dictionary cleared")
		return

	var music = sounds["music_background"]

	if not music["audio"] or not music["stream"]:
		print("❌ Cannot reduce music: missing audio player or stream")
		return

	# Save current state before reducing
	is_music_before = not is_music_muted
	is_music_reduced = true

	if not is_music_muted:
		# Music was playing, reduce volume
		music["audio"].volume_db = volume_reduced
		print("🔉 Music volume reduced for overlay (was playing)")
	else:
		# Music was already muted, keep it muted
		print("🔇 Music already muted, keeping muted for overlay")


# Restore music to original state after overlay
func restore_music_after_overlay():
	if not is_music_reduced:
		print("⚠️ Music not currently reduced, skipping restore")
		return

	if not sounds.has("music_background"):
		print("❌ Cannot restore music: sounds dictionary cleared")
		is_music_reduced = false
		return

	var music = sounds["music_background"]

	if not music["audio"] or not music["stream"]:
		print("❌ Cannot restore music: missing audio player or stream")
		return

	is_music_reduced = false

	if is_music_before:
		# Music was playing before overlay, restore it
		music["audio"].volume_db = music["volume"]
		if not music["audio"].playing:
			music["audio"].play()
		print("🔊 Music restored to original volume and playing")
	else:
		# Music was muted before overlay, keep it muted
		music["audio"].volume_db = volume_off
		music["audio"].stop()
		print("🔇 Music kept muted (was muted before overlay)")

	is_music_before = false

