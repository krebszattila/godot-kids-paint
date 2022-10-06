extends Node2D


signal size_changed(size, prev_size)

var size: Vector2
var prev_size: Vector2


func _ready():
	get_tree().get_root().connect("size_changed", self, "_on_size_changed")
	_on_size_changed()


func _on_size_changed():
	prev_size = size
	size = get_viewport_rect().size
	emit_signal("size_changed", size, prev_size)
