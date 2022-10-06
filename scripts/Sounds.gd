extends Node


var enabled: bool setget _set_enabled

var _click_player: AudioStreamPlayer
var _pencil_player: AudioStreamPlayer
var _brush_player: AudioStreamPlayer
var _bucket_player: AudioStreamPlayer
var _airbrush_spray_player: AudioStreamPlayer
var _airbrush_shake_player: AudioStreamPlayer


func _ready():
	_set_enabled(false)
	
	_click_player = _add_player(preload("res://assets/sounds/click.wav"))
	_pencil_player = _add_player(preload("res://assets/sounds/pencil.ogg"))
	_brush_player = _add_player(preload("res://assets/sounds/brush.ogg"))
	_bucket_player = _add_player(preload("res://assets/sounds/bucket.ogg"))
	_airbrush_spray_player = _add_player(preload("res://assets/sounds/airbrush_spray.ogg"))
	_airbrush_shake_player = _add_player(preload("res://assets/sounds/airbrush_shake.ogg"))


func _set_enabled(value: bool):
	enabled = value
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not enabled)


func click():
	_click_player.play()


func pencil(play: bool, replay = false):
	_start_stop_player(_pencil_player, play, replay)


func brush(play: bool, replay = false):
	_start_stop_player(_brush_player, play, replay)


func bucket(play: bool, replay = false):
	_start_stop_player(_bucket_player, play, replay)


func airbrush_spray(play: bool, replay = false):
	_start_stop_player(_airbrush_spray_player, play, replay)


func airbrush_shake(play: bool, replay = false):
	_start_stop_player(_airbrush_shake_player, play, replay)


func stop_loops():
	pencil(false)
	brush(false)
	airbrush_spray(false)


func _add_player(stream, pitch_scale = 1.0):
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.bus = "SFX"
	add_child(player)
	return player;


func _start_stop_player(player: AudioStreamPlayer, play: bool, replay = false):
	if replay or (play and not player.playing):
		player.play()
	elif not play and player.playing:
		player.stop()
