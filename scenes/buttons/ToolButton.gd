extends Control
tool


signal toggled

var pressed: bool setget _set_pressed

export(Enums.ToolType) var value
export(Texture) var button_base_texture setget _set_button_base_texture
export(Texture) var button_color_texture setget _set_button_color_texture
export(Color) var color setget _set_color

onready var _button_base: TextureButton = $ButtonBase
onready var _button_color: TextureRect = $ButtonBase/ButtonColor
onready var _button_highlight: TextureRect = $ButtonHighlight
onready var _button_highlight_tween: Tween = $ButtonHighlight/Tween


func _ready():
	_set_button_base_texture(button_base_texture)
	_set_button_color_texture(button_color_texture)


func _set_button_base_texture(value):
	button_base_texture = value
	if _button_base:
		_button_base.texture_normal = value


func _set_button_color_texture(value):
	button_color_texture = value
	if _button_color:
		_button_color.texture = value


func _set_color(value):
	color = value
	if _button_color:
		_button_color.material.set_shader_param("hue", color.h)
		_button_color.material.set_shader_param("saturation", color.s)
		_button_color.material.set_shader_param("value", color.v)


func _set_pressed(value):
	var prev_pressed = pressed
	pressed = value
	if _button_highlight:
		_button_highlight_tween.remove_all()
		_button_highlight_tween.interpolate_property(
			_button_highlight, "rect_scale",
			_button_highlight.rect_scale, Vector2.ONE if pressed else Vector2.ONE * 0.85,
			0.3, Tween.TRANS_CUBIC, Tween.EASE_OUT
		)
		_button_highlight_tween.start()
	
	if not prev_pressed and pressed:
		emit_signal("toggled")


func _on_button_pressed():
	if not pressed:
		_set_pressed(true)

