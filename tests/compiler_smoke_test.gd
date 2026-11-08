extends SceneTree

const Language := preload("res://scripts/magic_language.gd")
const Compiler := preload("res://scripts/magic_compiler.gd")

func _init() -> void:
	var canvas_size := Vector2(800, 620)
	var center := canvas_size * 0.5
	var radius := 210.0
	var strokes: Array[PackedVector2Array] = []
	var ring := PackedVector2Array()
	for i in 120:
		var angle := TAU * float(i) / 119.0
		ring.append(center + Vector2(cos(angle), sin(angle)) * radius)
	strokes.append(ring)
	strokes.append(Language.transformed_template("water", center, 95.0))
	strokes.append(Language.transformed_template("select", center + Vector2(-120, 0), 50.0))
	strokes.append(Language.transformed_template("converge", center + Vector2(0, -130), 58.0))
	strokes.append(Language.transformed_template("accelerate", center + Vector2(125, 0), 65.0))
	strokes.append(Language.transformed_template("maintain", center + Vector2(0, 125), 52.0))
	var result := Compiler.compile(strokes, canvas_size, {
		"ink": 0.8,
		"mastery": 0.8,
		"focus": 0.85,
		"ambient": 0.7,
		"matter": 0.75,
		"caster": 0.2,
	})
	if not result.valid:
		printerr("FAIL: expected a valid spell: ", result)
		quit(1)
		return
	if result.metrics.source != "water":
		printerr("FAIL: expected water, got ", result.metrics.source)
		quit(1)
		return
	if not result.pseudo_code.contains("ACCÉLÉRER"):
		printerr("FAIL: acceleration operator not compiled")
		quit(1)
		return
	print("PASS: ", result.status, " | source=", result.metrics.source, " | rendement=", result.metrics.efficiency)
	quit(0)

