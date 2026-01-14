# reviewed
extends Node

# Control modes
enum ControlMode {
	DIRECTION,  # Follow mouse/touch direction (default)
	ZONES       # Left/Right zones
}

var current_control_mode: ControlMode = ControlMode.DIRECTION

# Settings file path
const SETTINGS_PATH = "user://control_settings.cfg"

# Signal for control mode changes
signal control_mode_changed(mode: ControlMode)


func _ready():
	load_settings()
	print("🎮 ControlManager ready - Mode: %s" % get_mode_name())


# Get current control mode
func get_control_mode() -> ControlMode:
	return current_control_mode


# Set control mode
func set_control_mode(mode: ControlMode):
	if current_control_mode != mode:
		current_control_mode = mode
		save_settings()
		control_mode_changed.emit(mode)
		print("🎮 Control mode changed to: %s" % get_mode_name())


# Toggle between modes
func toggle_control_mode():
	if current_control_mode == ControlMode.DIRECTION:
		set_control_mode(ControlMode.ZONES)
	else:
		set_control_mode(ControlMode.DIRECTION)


# Get mode name for display
func get_mode_name() -> String:
	match current_control_mode:
		ControlMode.DIRECTION:
			return "DIRECTION"
		ControlMode.ZONES:
			return "ZONES"
		_:
			return "UNKNOWN"


# Check if current mode is direction
func is_direction_mode():
	return current_control_mode == ControlMode.DIRECTION


# Check if current mode is zones
func is_zones_mode():
	return current_control_mode == ControlMode.ZONES


# Load settings from file
func load_settings():
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)

		if file:
			var json_string = file.get_as_text()
			file.close()

			var json 			= JSON.new()
			var parse_result	= json.parse(json_string)

			if parse_result == OK:
				var data = json.data

				if data.has("control_mode"):
					current_control_mode = data["control_mode"] as ControlMode


# Save settings to file
func save_settings():
	var data = {
		"control_mode": current_control_mode
	}

	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)

	if file:
		file.store_string(JSON.stringify(data))
		file.close()
