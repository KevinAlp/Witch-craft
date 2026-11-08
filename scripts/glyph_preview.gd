class_name GlyphPreview
extends Control

const Language := preload("res://scripts/magic_language.gd")

var glyph_id := "water"
var line_color := Language.ACCENT

func _ready() -> void:
	custom_minimum_size = Vector2(82, 82)
	queue_redraw()

func setup(id: String, color: Color = Language.ACCENT) -> GlyphPreview:
	glyph_id = id
	line_color = color
	queue_redraw()
	return self

func _draw() -> void:
	draw_circle(size * 0.5, minf(size.x, size.y) * 0.45, Color("#f1edff"))
	var points := Language.transformed_template(glyph_id, size * 0.5, minf(size.x, size.y) * 0.62)
	if points.size() > 1:
		draw_polyline(points, line_color, 3.0, true)

