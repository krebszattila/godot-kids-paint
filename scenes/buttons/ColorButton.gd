extends Control
tool


signal toggled

var pressed: bool setget _set_pressed

export(Enums.Colors) var value
export(Color) var color setget _set_color

onready var _button_color: TextureRect = $ButtonBase/ButtonColor
onready var _button_highlight: TextureRect = $ButtonHighlight
onready var _button_highlight_tween: Tween = $ButtonHighlight/Tween


func _ready():
	_set_color(color)


func _set_color(value):
	color = value
	if _button_color:
		_button_color.modulate = color


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
