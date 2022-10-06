extends Node

# A Seed Fill Algorithm
# by Paul Heckbert
# from "Graphics Gems", Academic Press, 1990
# https://github.com/erich666/GraphicsGems/blob/master/gems/SeedFill.c

var _data: Image
var _width: int
var _height: int
var _color_from: Color
var _color_to: Color
var _cover_rect: Rect2


func fill(data: Image, position: Vector2, color_from: Color, color_to: Color):
	if color_from == color_to:
		return
	
	_data = data
	_width = data.get_width()
	_height = data.get_height()
	_color_from = color_from
	_color_to = color_to
	_cover_rect = Rect2(position, Vector2.ZERO)
	
	var x = position.x
	var y = position.y
	
	var stack = []
	var l
	var x1
	var x2
	var dy
	var skip
	
	_push_stack(stack, y, x, x, 1)
	_push_stack(stack, y + 1, x, x, -1)
	
	while not stack.empty():
		var pos = _pop_stack(stack)
		y = pos.y
		x1 = pos.xl
		x2 = pos.xr
		dy = pos.dy
		
		x = x1
		while x >= 0 and _test(x, y):
			_paint(x, y)
			x -= 1
		
		skip = x >= x1
		
		if not skip:
			l = x + 1
			if l < x1:
				_push_stack(stack, y, l, x1 - 1, -dy)
			x = x1 + 1
		
		while true:
			if not skip:
				while x < _width and _test(x, y):
					_paint(x, y)
					x += 1
				_push_stack(stack, y, l, x - 1, dy)
				if x > x2 + 1:
					_push_stack(stack, y, x2 + 1, x - 1, -dy)

			skip = false
			x += 1
			while x <= x2 and not _test(x, y):
				x += 1
			l = x
			if x > x2:
				break
	
	return _cover_rect


func _push_stack(stack: Array, y: int, xl: int, xr: int, dy: int):
	if y + dy >= 0 and y + dy < _height:
		stack.push_back({
			"y": y,
			"xl": xl,
			"xr": xr,
			"dy": dy
		})


func _pop_stack(stack: Array):
	var p = stack.pop_back()
	return {
		"y": p.y + p.dy,
		"xl": p.xl,
		"xr": p.xr,
		"dy": p.dy
	}


func _test(x: int, y: int):
	return _data.get_pixel(x, y) == _color_from


func _paint(x: int, y: int):
	_data.set_pixel(x, y, _color_to)
	_cover_rect = _cover_rect.expand(Vector2(x, y))
