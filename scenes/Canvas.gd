extends Control


signal history_changed(can_undo, can_redo)

const PENCIL_SIZES = {
	Enums.ToolSize.SM: 1.0,
	Enums.ToolSize.MD: 2.0,
	Enums.ToolSize.LG: 4.0
}

const BRUSH_SIZES = {
	Enums.ToolSize.SM: 12.0,
	Enums.ToolSize.MD: 24.0,
	Enums.ToolSize.LG: 40.0
}

const AIRBRUSH_SIZES = {
	Enums.ToolSize.SM: {
		"radius": 18.0,
		"drop_size": [1.0, 1.5]
	},
	Enums.ToolSize.MD: {
		"radius": 30.0,
		"drop_size": [1.0, 2.0]
	},
	Enums.ToolSize.LG: {
		"radius": 45.0,
		"drop_size": [1.0, 3.0]
	}
}

const AIRBRUSH_INTERVAL = 0.001

const HISTORY_SIZE = 10

const flood_fill_script = preload("res://scripts/FloodFill.gd")

var _viewport: Viewport
var _drawer: Node2D
var _texture: Texture
var _prev_mouse_position: Vector2

var _history: Array = []
var _history_index: int = 0
var _restore_texture: ImageTexture
var _restore_index_diff: int = 0

var _flood_fill: Node
var _flood_fill_texture: ImageTexture
var _flood_fill_completed: bool

var _airbrush_spraying: bool
var _airbrush_remaining_time: float

var _reset: bool
var _reset_after: bool
var _size_changed: bool
var _rect_size: Vector2
var _locked: bool

var _input_pressed: bool
var _input_just_pressed: bool
var _input_just_released: bool

export(Enums.ToolType) var tool_type setget _set_tool_type
export(Enums.ToolSize) var pencil_size = Enums.ToolSize.SM
export(Enums.ToolSize) var brush_size = Enums.ToolSize.SM
export(Enums.ToolSize) var airbrush_size = Enums.ToolSize.SM
export var color: Color

onready var _board: TextureRect = $Board
onready var _flood_fill_board: TextureRect = $FloodFillBoard
onready var _flood_fill_tween: Tween = $FloodFillBoard/Tween
onready var _particles: Node2D = $Particles
onready var _paint_particles: CPUParticles2D = $Particles/PaintParticles
onready var _airbrush_particles: CPUParticles2D = $Particles/AirbrushParticles
onready var _anti_alias: ColorRect = $AntiAlias
onready var _airbrush_shake_timer: Timer = $AirbrushShakeTimer


func _ready():
	_viewport = Viewport.new()
	_viewport.size = get_rect().size
	_viewport.usage = Viewport.USAGE_2D
	_viewport.render_target_clear_mode = Viewport.CLEAR_MODE_NEVER
	_viewport.render_target_v_flip = true
	
	_drawer = Node2D.new()
	_viewport.add_child(_drawer)
	_drawer.connect("draw", self, "_on_draw")
	add_child(_viewport)
	
	_texture = _viewport.get_texture()
	_board.set_texture(_texture)
	
	_flood_fill = flood_fill_script.new()
	add_child(_flood_fill)
	
	_anti_alias.visible = Settings.anti_aliasing_enabled
	
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	_reset = true
	
	Settings.connect("particles_enabled_changed", self, "toggle_particles")
	Settings.connect("anti_aliasing_enabled_changed", self, "toggle_anti_aliasing")
	toggle_particles(Settings.particles_enabled)
	toggle_anti_aliasing(Settings.anti_aliasing_enabled)


func _process(delta):
	if _airbrush_spraying:
		_airbrush_remaining_time -= delta
	
	var mouse_position = get_local_mouse_position()
	_particles.position = mouse_position
	
	_drawer.update()


func _unhandled_input(event):
	_input_pressed = Input.is_action_pressed("draw")
	_input_just_pressed = Input.is_action_just_pressed("draw")
	_input_just_released = Input.is_action_just_released("draw")


func undo():
	_restore_index_diff = 1


func redo():
	_restore_index_diff = -1


func clear():
	_reset = true


func toggle_particles(enabled):
	_particles.visible = enabled


func toggle_anti_aliasing(enabled):
	_anti_alias.visible = enabled


func _set_tool_type(value):
	tool_type = value
	Sounds.stop_loops()
	_airbrush_spraying = false
	_paint_particles.emitting = false
	_airbrush_particles.emitting = false


func _on_draw():
	if _reset or _size_changed:
		var new_rect_size = get_rect().size
		_drawer.draw_rect(_board.get_rect(), Color.white)
		_rect_size = new_rect_size
	
	if _reset:
		_reset = false
		_reset_after = true
		return
	
	if _reset_after:
		_reset_after = false
		_push_to_history(true)
		return
	
	if _size_changed:
		_size_changed = false
		_restore_history(0)
		return
	
	if _flood_fill_completed:
		_flood_fill_completed = false
		_push_to_history()
		return
	
	if _restore_index_diff != 0:
		_restore_history(_restore_index_diff)
		_restore_index_diff = 0
		return
	
	var mouse_position = get_local_mouse_position()
	
	var inside_rect = (
		mouse_position.x >= 0 and mouse_position.y >= 0 and
		mouse_position.x < rect_size.x and mouse_position.y < rect_size.y
	)
	
	if _input_just_pressed:
		if tool_type == Enums.ToolType.PENCIL:
			Sounds.pencil(true)
		if not _locked and tool_type == Enums.ToolType.BRUSH:
			_paint_particles.color = color
			_paint_particles.scale_amount = BRUSH_SIZES[brush_size] / BRUSH_SIZES[Enums.ToolSize.LG]
			_paint_particles.emitting = Settings.particles_enabled
			Sounds.brush(true)
		if not _locked and tool_type == Enums.ToolType.AIRBRUSH:
			_airbrush_spraying = true
			_airbrush_particles.color = color
			_airbrush_particles.scale_amount = AIRBRUSH_SIZES[airbrush_size].radius / AIRBRUSH_SIZES[Enums.ToolSize.LG].radius
			_airbrush_particles.emitting = Settings.particles_enabled
			_airbrush_remaining_time = 0.0
			Sounds.airbrush_spray(true)
			Sounds.airbrush_shake(false)
			_airbrush_shake_timer.stop()
	if _input_just_released:
		if tool_type == Enums.ToolType.PENCIL:
			Sounds.pencil(false)
			_push_to_history()
		if tool_type == Enums.ToolType.BRUSH:
			_paint_particles.emitting = false
			Sounds.brush(false)
			_push_to_history()
		if tool_type == Enums.ToolType.AIRBRUSH:
			_airbrush_spraying = false
			_airbrush_particles.emitting = false
			Sounds.airbrush_spray(false)
			if randf() > 0.66:
				_airbrush_shake_timer.start()
			_push_to_history()
		if not _locked and tool_type == Enums.ToolType.BUCKET and inside_rect:
			var data = _texture.get_data()
			data.lock()
			var rect = _flood_fill.fill(data, mouse_position, data.get_pixelv(mouse_position), color)
			data.unlock()
			if rect:
				_locked = true
				var original_texture = ImageTexture.new()
				original_texture.create_from_image(_texture.get_data())
				_flood_fill_board.visible = true
				_flood_fill_board.texture = original_texture
				
				_flood_fill_texture = ImageTexture.new()
				_flood_fill_texture.create_from_image(data)
				_drawer.draw_texture(_flood_fill_texture, Vector2.ZERO)
				
				_animate_flood_fill(mouse_position, rect)
				Sounds.bucket(true, true)
	
	if _input_pressed:
		if not _locked and (tool_type == Enums.ToolType.PENCIL or tool_type == Enums.ToolType.BRUSH):
			var size = PENCIL_SIZES[pencil_size] if tool_type == Enums.ToolType.PENCIL else BRUSH_SIZES[brush_size]
			_drawer.draw_circle(_prev_mouse_position, size / 2.0, color)
			_drawer.draw_line(mouse_position, _prev_mouse_position, color, size)
			_drawer.draw_circle(mouse_position, size / 2.0, color)
	
	if not _locked and _airbrush_spraying:
		while _airbrush_remaining_time <= 0:
			var size = AIRBRUSH_SIZES[airbrush_size]
			var radius = size.radius
			var drop = rand_range(size.drop_size[0], size.drop_size[1])
			var offset = Vector2.UP.rotated(randf() * 2.0 * PI) * randf() * radius
			_drawer.draw_circle(mouse_position + offset, drop / 2.0, color)
			_airbrush_remaining_time += AIRBRUSH_INTERVAL
	
	_prev_mouse_position = mouse_position
	
	_input_pressed = false
	_input_just_pressed = false
	_input_just_released = false


func _push_to_history(replace = false):
	if replace:
		_history.clear()
		_history_index = 0
	else:
		while _history_index > 0:
			_history.pop_front()
			_history_index -= 1
	
	var data = _texture.get_data()
	_history.push_front(data)
	while _history.size() > HISTORY_SIZE:
		_history.pop_back()
	
	emit_signal("history_changed", _history.size() > 1, false)


func _restore_history(index_diff: int):
	_history_index = clamp(_history_index + index_diff, 0, _history.size() - 1)
	if not _history.empty() and _history[_history_index]:
		_restore_texture = ImageTexture.new()
		_restore_texture.create_from_image(_history[_history_index])
		_drawer.draw_texture(_restore_texture, Vector2.ZERO)
	
	emit_signal("history_changed", _history.size() - _history_index > 1, _history_index > 0)


func _animate_flood_fill(origin: Vector2, rect: Rect2):
	_flood_fill_tween.remove_all()
	
	var top = origin.y - rect.position.y
	var bottom = rect.end.y - origin.y
	var left = origin.x - rect.position.x
	var right = rect.end.x - origin.x
	rect = rect.grow_individual(
		right - left if left < right else 0.0,
		bottom - top if top < bottom else 0.0,
		left - right if right < left else 0.0,
		top - bottom if bottom < top else 0.0
	)
	
	var radius = rect.size.length() / 2.0
	
	_flood_fill_board.material.set_shader_param("origin", origin)
	_flood_fill_board.material.set_shader_param("radius", 0.0)
	
	_flood_fill_tween.interpolate_method(
		self, "_set_flood_fill_animation_radius",
		0.0, radius,
		0.4, Tween.TRANS_CIRC, Tween.EASE_IN
	)
	
	_flood_fill_tween.start()


func _set_flood_fill_animation_radius(radius: float):
	_flood_fill_board.material.set_shader_param("radius", radius)


func _on_flood_fill_tween_all_completed():
	_flood_fill_board.visible = false
	_locked = false
	_flood_fill_completed = true


func _on_rect_changed():
	if _viewport:
		_viewport.size = get_rect().size
		_size_changed = true


func _on_airbrush_shake_timer_timeout():
	Sounds.airbrush_shake(true)
