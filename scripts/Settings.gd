extends Node


signal particles_enabled_changed(enabled)
signal anti_aliasing_enabled_changed(enabled)

const PATH = "user://settings.dat"

var _initialized: bool

var sounds_enabled = true setget _toggle_sounds
var particles_enabled = true setget _toggle_particles
var anti_aliasing_enabled = true setget _toggle_anti_aliasing
var full_screen = true setget _toggle_full_screen


func _ready():
	_load()
	
	if full_screen:
		OS.window_fullscreen = true


func _load():
	var file = File.new()
	if file.file_exists(PATH):
		var error = file.open(PATH, File.READ)
		if error == OK:
			var data = file.get_var()
			file.close()
			
			_toggle_sounds(data["sounds_enabled"])
			_toggle_particles(data["particles_enabled"])
			_toggle_anti_aliasing(data["anti_aliasing_enabled"])
			_toggle_full_screen(data["full_screen"])
	_initialized = true


func _save():
	var file = File.new()
	var error = file.open(PATH, File.WRITE)
	if error == OK:
		file.store_var({
			"sounds_enabled": sounds_enabled,
			"particles_enabled": particles_enabled,
			"anti_aliasing_enabled": anti_aliasing_enabled,
			"full_screen": full_screen
		})
		file.close()


func _toggle_sounds(enabled: bool):
	sounds_enabled = enabled
	Sounds.enabled = sounds_enabled
	if _initialized:
		_save()


func _toggle_particles(enabled: bool):
	particles_enabled = enabled
	emit_signal("particles_enabled_changed", particles_enabled)
	if _initialized:
		_save()


func _toggle_anti_aliasing(enabled: bool):
	anti_aliasing_enabled = enabled
	emit_signal("anti_aliasing_enabled_changed", anti_aliasing_enabled)
	if _initialized:
		_save()


func _toggle_full_screen(enabled: bool):
	full_screen = enabled
	OS.window_fullscreen = full_screen
	if _initialized:
		_save()
