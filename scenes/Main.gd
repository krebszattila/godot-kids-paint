extends Node


const MIN_TOOLBAR_HEIGHT = 1000

const COLORS = {
	Enums.Colors.BLACK: {
		"draw": Color("#000000"),
		"tool": Color("#232323")
	},
	Enums.Colors.WHITE: {
		"draw": Color("#ffffff"),
		"tool": Color("#e4e4e4")
	},
	Enums.Colors.GRAY: {
		"draw": Color("#898989"),
		"tool": Color("#898989")
	},
	Enums.Colors.BROWN: {
		"draw": Color("#752b0a"),
		"tool": Color("#752b0a")
	},
	Enums.Colors.RED: {
		"draw": Color("#ce0606"),
		"tool": Color("#ce0606")
	},
	Enums.Colors.ORANGE: {
		"draw": Color("#f37a24"),
		"tool": Color("#f37a24")
	},
	Enums.Colors.GREEN: {
		"draw": Color("#2eb312"),
		"tool": Color("#2eb312")
	},
	Enums.Colors.YELLOW: {
		"draw": Color("#edbd0a"),
		"tool": Color("#edbd0a")
	},
	Enums.Colors.BLUE: {
		"draw": Color("#1b3fcc"),
		"tool": Color("#1b3fcc")
	},
	Enums.Colors.CYAN: {
		"draw": Color("#18bece"),
		"tool": Color("#18bece")
	},
	Enums.Colors.PURPLE: {
		"draw": Color("#5911a4"),
		"tool": Color("#5911a4")
	},
	Enums.Colors.PINK: {
		"draw": Color("#ef4fbc"),
		"tool": Color("#ef4fbc")
	}
}

const CURSORS = {
	Enums.ToolType.PENCIL: {
		"cursor": preload("res://assets/images/cursors/pencil.png"),
		"hotspot": Vector2(3, 28)
	},
	Enums.ToolType.BRUSH: {
		"cursor": preload("res://assets/images/cursors/brush.png"),
		"hotspot": Vector2(5, 26)
	},
	Enums.ToolType.BUCKET: {
		"cursor": preload("res://assets/images/cursors/bucket.png"),
		"hotspot": Vector2(8, 28)
	},
	Enums.ToolType.AIRBRUSH: {
		"cursor": preload("res://assets/images/cursors/airbrush.png"),
		"hotspot": Vector2(9, 5)
	}
}

var _selected_tool = Enums.ToolType.PENCIL
var _selected_size = Enums.ToolSize.SM
var _selected_color = Enums.Colors.BLACK

var _tool_buttons: Array
var _pencil_size_buttons: Array
var _brush_size_buttons: Array
var _airbrush_size_buttons: Array
var _color_buttons: Array

onready var _toolbar: Control = $Toolbar
onready var _canvas: Control = $Canvas
onready var _menu: Control = $Menu
onready var _menu_help_popup: Panel = $MenuHelpPopup
onready var _file_dialog: FileDialog = $FileDialog

onready var _sounds_check: CheckButton = $Menu/SettingsButtons/SoundsCheck
onready var _particles_check: CheckButton = $Menu/SettingsButtons/ParticlesCheck
onready var _antialiasing_check: CheckButton = $Menu/SettingsButtons/AntialiasingCheck
onready var _fullscreen_check: CheckButton = $Menu/SettingsButtons/FullscreenCheck


func _ready():
	_sounds_check.pressed = Settings.sounds_enabled
	_particles_check.pressed = Settings.particles_enabled
	_antialiasing_check.pressed = Settings.anti_aliasing_enabled
	_fullscreen_check.pressed = Settings.full_screen
	
	_tool_buttons = []
	for button in $Toolbar/ToolButtons.get_children():
		button.connect("toggled", self, "_on_tool_button_toggled", [ button, button.value ])
		_tool_buttons.append(button)
	_tool_buttons[0].pressed = true
	
	_pencil_size_buttons = []
	for button in $Toolbar/SizeButtons/PencilSizeButtons.get_children():
		button.connect("toggled", self, "_on_size_button_toggled", [ button, button.value, _pencil_size_buttons, "pencil_size" ])
		_pencil_size_buttons.append(button)
	_pencil_size_buttons[0].pressed = true
	
	_brush_size_buttons = []
	for button in $Toolbar/SizeButtons/BrushSizeButtons.get_children():
		button.connect("toggled", self, "_on_size_button_toggled", [ button, button.value, _brush_size_buttons, "brush_size" ])
		_brush_size_buttons.append(button)
	_brush_size_buttons[0].pressed = true
	
	_airbrush_size_buttons = []
	for button in $Toolbar/SizeButtons/AirbrushSizeButtons.get_children():
		button.connect("toggled", self, "_on_size_button_toggled", [ button, button.value, _airbrush_size_buttons, "airbrush_size" ])
		_airbrush_size_buttons.append(button)
	_airbrush_size_buttons[0].pressed = true
	
	_color_buttons = []
	for button in $Toolbar/ColorButtons.get_children():
		button.color = COLORS[button.value].draw
		button.connect("toggled", self, "_on_color_button_toggled", [ button, button.value ])
		_color_buttons.append(button)
	_color_buttons[0].pressed = true
	
	_set_cursor_shape(_toolbar, Input.CURSOR_POINTING_HAND)
	
	Window.connect("size_changed", self, "_on_window_size_changed")
	_on_window_size_changed(Window.size, Window.prev_size)
	
	yield(get_tree(), "idle_frame")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _unhandled_key_input(event):
	if event.pressed and event.is_action_pressed("toggle_fullscreen"):
		_fullscreen_check.pressed = not Settings.full_screen
	elif event.pressed and event.is_action_pressed("undo"):
		_canvas.undo()
	elif event.pressed and event.is_action_pressed("redo"):
		_canvas.redo()
	elif event.pressed and event.is_action_pressed("ui_cancel"):
		_toggle_menu(not _menu.visible)
	elif (
		event.pressed and not _menu.visible and event is InputEventKey and
		event.scancode != KEY_CONTROL and event.scancode != KEY_ALT and event.scancode != KEY_SHIFT
	):
		_toggle_menu_help_popup(true)


func _toggle_menu(visible):
	if visible:
		_toggle_menu_help_popup(false)
	_menu.visible = visible
	_set_tool_cursor(_selected_tool if not visible else null)
	if not visible:
		_menu.get_node("MenuButtons").visible = true
		_menu.get_node("AboutText").visible = false
		_menu.get_node("SettingsButtons").visible = false


func _toggle_menu_help_popup(visible):
	_menu_help_popup.visible = visible
	var timer = _menu_help_popup.get_node("Timer")
	timer.stop()
	if visible:
		timer.start()


func _save_image(path):
	_toggle_menu(false)
	_canvas.toggle_particles(false)
	yield (get_tree(), "idle_frame")
	yield (get_tree(), "idle_frame")
	
	var img = get_viewport().get_texture().get_data()
	var cropped_image = img.get_rect(Rect2(_canvas.rect_global_position, _canvas.rect_size))
	cropped_image.flip_y()
	cropped_image.save_png(path)
	
	_canvas.toggle_particles(Settings.particles_enabled)


func _set_tool_cursor(selected_tool):
	if selected_tool != null:
		var cursor = CURSORS[selected_tool]
		Input.set_custom_mouse_cursor(cursor.cursor, Input.CURSOR_ARROW, cursor.hotspot)
	else:
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)


func _set_cursor_shape(control, shape):
	if "mouse_default_cursor_shape" in control:
		control.mouse_default_cursor_shape = shape
		for child in control.get_children():
			_set_cursor_shape(child, shape)


func _on_tool_button_toggled(pressed_button, tool_type):
	Sounds.click()
	_selected_tool = tool_type
	_canvas.tool_type = _selected_tool
	$Toolbar/SizeButtons/PencilSizeButtons.visible = _selected_tool == Enums.ToolType.PENCIL
	$Toolbar/SizeButtons/BrushSizeButtons.visible = _selected_tool == Enums.ToolType.BRUSH
	$Toolbar/SizeButtons/AirbrushSizeButtons.visible = _selected_tool == Enums.ToolType.AIRBRUSH
	_set_tool_cursor(_selected_tool)
	for button in _tool_buttons:
		if button != pressed_button:
			button.pressed = false


func _on_size_button_toggled(pressed_button, size, buttons, size_prop):
	Sounds.click()
	_selected_size = size
	_canvas[size_prop] = _selected_size
	for button in buttons:
		if button != pressed_button:
			button.pressed = false


func _on_color_button_toggled(pressed_button, color):
	Sounds.click()
	_selected_color = color
	_canvas.color = COLORS[_selected_color].draw
	for button in _tool_buttons:
		button.color = COLORS[_selected_color].tool
	for button in _color_buttons:
		if button != pressed_button:
			button.pressed = false


func _on_window_size_changed(size, prev_size):
	var scale_factor = 1.0
	if size.y < MIN_TOOLBAR_HEIGHT:
		scale_factor = size.y / MIN_TOOLBAR_HEIGHT
	_toolbar.rect_scale = Vector2.ONE * scale_factor
	
	_canvas.margin_left = round(_toolbar.rect_size.x * scale_factor)


func _on_undo_button_pressed():
	Sounds.click()
	_canvas.undo()


func _on_redo_button_pressed():
	Sounds.click()
	_canvas.redo()


func _on_canvas_history_changed(can_undo, can_redo):
	$Toolbar/HistoryButtons/UndoButton.disabled = not can_undo
	$Toolbar/HistoryButtons/RedoButton.disabled = not can_redo


func _on_new_button_pressed():
	_toggle_menu(false)
	_canvas.clear()


func _on_save_button_pressed():
	_file_dialog.popup_centered()


func _on_settings_button_pressed():
	_menu.get_node("MenuButtons").visible = false
	_menu.get_node("SettingsButtons").visible = true


func _on_about_button_pressed():
	_menu.get_node("MenuButtons").visible = false
	_menu.get_node("AboutText").visible = true


func _on_quit_button_pressed():
	get_tree().quit()


func _on_settings_sounds_toggled(enabled):
	Settings.sounds_enabled = enabled


func _on_settings_particles_toggled(enabled):
	Settings.particles_enabled = enabled


func _on_settings_antialiasing_toggled(enabled):
	Settings.anti_aliasing_enabled = enabled


func _on_settings_fullscreen_toggled(enabled):
	Settings.full_screen = enabled


func _on_menu_help_popup_timer_timeout():
	_toggle_menu_help_popup(false)
