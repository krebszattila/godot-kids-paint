extends Control
tool


signal toggled

var pressed: bool setget _set_pressed

export(Enums.ToolSize) var value
export(Texture) var button_base_texture setget _set_button_base_texture

onready var _button_base: TextureButton = $ButtonBase
onready var _button_highlight: TextureRect = $ButtonHighlight
onready var _button_highlight_tween: Tween = $ButtonHighlight/Tween


func _ready():
	_set_button_base_texture(button_base_texture)


func _set_button_base_texture(value):
	button_base_texture = value
	if _button_base:
		_button_base.texture_normal = value


func _set_pressed(value):
	var prev_pressed = pressed
	pressed = value
	if _button_highlight:
		_button_highlight_tween.remove_all()
		_button_highlight_tween.interpolate_property(
			_button_highlight, "rect_scale",
			_button_highlight.rect_scale, Vector2.ONE if pressed else Vector2.ONE * 0.8,
			0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT
		)
		_button_highlight_tween.start()
	
	if not prev_pressed and pressed:
		emit_signal("toggled")


func _on_button_pressed():
	if not pressed:
		_set_pressed(true)
