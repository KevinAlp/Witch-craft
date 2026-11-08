class_name DrawingCanvas
extends Control

signal strokes_changed

const Language := preload("res://scripts/magic_language.gd")

var strokes: Array[PackedVector2Array] = []
var redo_stack: Array[PackedVector2Array] = []
var corrected: Array = []
var drawing := false
var erasing := false
var show_correction := true
var pen_width := 4.0
var _current := PackedVector2Array()

func _ready() -> void:
	set_process_input(true)
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	clip_contents = true
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if erasing:
				_erase_at(event.position)
			else:
				drawing = true
				_current = PackedVector2Array([event.position])
				corrected.clear()
				queue_redraw()
		else:
			if drawing:
				drawing = false
				if _current.size() >= 2:
					strokes.append(_current)
					redo_stack.clear()
					strokes_changed.emit()
				_current = PackedVector2Array()
				queue_redraw()
	elif event is InputEventMouseMotion and (drawing or (erasing and event.button_mask & MOUSE_BUTTON_MASK_LEFT)):
		if erasing:
			_erase_at(event.position)
		elif _current.is_empty() or _current[-1].distance_to(event.position) >= 2.5:
			_current.append(event.position)
			queue_redraw()

func _draw() -> void:
	var paper := Rect2(Vector2.ZERO, size)
	draw_rect(paper, Color("#fbfaf6"), true)
	for x in range(24, int(size.x), 24):
		for y in range(24, int(size.y), 24):
			draw_circle(Vector2(x, y), 0.9, Color("#d9d5e6"))
	draw_rect(paper.grow(-1.0), Color("#cfc9df"), false, 2.0)
	for stroke in strokes:
		_draw_stroke(stroke, Language.INK.lerp(Color.WHITE, 0.38) if show_correction and not corrected.is_empty() else Language.INK, pen_width)
	if drawing:
		_draw_stroke(_current, Language.INK, pen_width)
	if show_correction:
		for item in corrected:
			if item.kind == "ring":
				draw_arc(item.center, item.radius, 0.0, TAU, 128, Language.CYAN, 3.0, true)
			elif item.kind == "glyph":
				var color := Language.CYAN if item.confidence >= 0.58 else Language.WARNING
				_draw_stroke(item.points, color, 3.2)

func _draw_stroke(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() == 1:
		draw_circle(points[0], width * 0.5, color)
	elif points.size() > 1:
		draw_polyline(points, color, width, true)

func set_correction(items: Array) -> void:
	corrected = items.duplicate(true)
	queue_redraw()

func set_eraser(active: bool) -> void:
	erasing = active
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if active else Control.CURSOR_CROSS

func set_show_correction(active: bool) -> void:
	show_correction = active
	queue_redraw()

func undo() -> void:
	if strokes.is_empty():
		return
	redo_stack.append(strokes.pop_back())
	corrected.clear()
	strokes_changed.emit()
	queue_redraw()

func redo() -> void:
	if redo_stack.is_empty():
		return
	strokes.append(redo_stack.pop_back())
	corrected.clear()
	strokes_changed.emit()
	queue_redraw()

func clear_canvas() -> void:
	if strokes.is_empty():
		return
	redo_stack.append_array(strokes)
	strokes.clear()
	corrected.clear()
	strokes_changed.emit()
	queue_redraw()

func add_example() -> void:
	strokes.clear()
	redo_stack.clear()
	corrected.clear()
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var ring := PackedVector2Array()
	for i in 120:
		var angle := -PI * 0.5 + TAU * float(i) / 119.0
		var wobble := sin(float(i) * 0.73) * 1.2
		ring.append(center + Vector2(cos(angle), sin(angle)) * (radius + wobble))
	strokes.append(ring)
	strokes.append(_placed_glyph("water", center, radius * 0.46, 0.0, 0.018))
	strokes.append(_placed_glyph("select", center + Vector2(-radius * 0.55, 0), radius * 0.24, 0.0, 0.025))
	strokes.append(_placed_glyph("converge", center + Vector2(0, -radius * 0.58), radius * 0.26, 0.0, 0.028))
	strokes.append(_placed_glyph("accelerate", center + Vector2(radius * 0.55, 0), radius * 0.30, 0.0, 0.02))
	strokes.append(_placed_glyph("maintain", center + Vector2(0, radius * 0.58), radius * 0.23, 0.0, 0.025))
	strokes_changed.emit()
	queue_redraw()

func _placed_glyph(glyph_id: String, center: Vector2, glyph_scale: float, rotation: float, noise: float) -> PackedVector2Array:
	var points := Language.transformed_template(glyph_id, center, glyph_scale, rotation)
	for i in points.size():
		points[i] += Vector2(sin(float(i) * 1.71), cos(float(i) * 1.37)) * glyph_scale * noise
	return points

func _erase_at(position: Vector2) -> void:
	var best_index := -1
	var best_distance := 18.0
	for i in strokes.size():
		for point in strokes[i]:
			var distance := point.distance_to(position)
			if distance < best_distance:
				best_distance = distance
				best_index = i
	if best_index >= 0:
		redo_stack.append(strokes[best_index])
		strokes.remove_at(best_index)
		corrected.clear()
		strokes_changed.emit()
		queue_redraw()

