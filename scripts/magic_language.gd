class_name MagicLanguage
extends RefCounted

const INK := Color("#19213d")
const ACCENT := Color("#7657ff")
const CYAN := Color("#42d9da")
const DANGER := Color("#ff5d7a")
const WARNING := Color("#ffbd59")

const GLYPHS := {
	"water": {"name": "EAU", "category": "source", "summary": "Prélève ou manipule l'eau disponible.", "type": "Matière<Eau>"},
	"fire": {"name": "FEU", "category": "source", "summary": "Convertit l'énergie en chaleur et combustion.", "type": "Énergie<Thermique>"},
	"air": {"name": "AIR", "category": "source", "summary": "Sélectionne un volume de gaz environnant.", "type": "Matière<Air>"},
	"earth": {"name": "TERRE", "category": "source", "summary": "Sélectionne une matière minérale continue.", "type": "Matière<Minéral>"},
	"accelerate": {"name": "ACCÉLÉRER", "category": "operator", "summary": "Ajoute une vitesse dans l'orientation du signe.", "type": "Matière → Mouvement"},
	"converge": {"name": "CONVERGER", "category": "operator", "summary": "Concentre la matière et augmente sa cohésion.", "type": "Matière → FormeDense"},
	"maintain": {"name": "MAINTENIR", "category": "operator", "summary": "Alimente un état tant que le circuit tient.", "type": "ÉtatInstable → ÉtatMaintenu"},
	"spread": {"name": "DISPERSER", "category": "operator", "summary": "Répartit le flux dans plusieurs directions.", "type": "Flux → Flux[]"},
	"select": {"name": "SÉLECTIONNER", "category": "operator", "summary": "Délimite la quantité prélevée autour de la source.", "type": "Entité → Région"},
}

static func glyph_ids(category: String = "") -> Array[String]:
	var result: Array[String] = []
	for glyph_id in GLYPHS:
		if category.is_empty() or GLYPHS[glyph_id].category == category:
			result.append(glyph_id)
	return result

static func template_points(glyph_id: String, count: int = 64) -> PackedVector2Array:
	var anchors := _anchors(glyph_id)
	return resample(anchors, count)

static func _anchors(glyph_id: String) -> PackedVector2Array:
	match glyph_id:
		"water":
			return _sample_curve(func(t: float) -> Vector2: return Vector2(t, 0.5 + sin(t * TAU * 1.5) * 0.22), 42)
		"fire":
			return PackedVector2Array([
				Vector2(0.52, 0.94), Vector2(0.22, 0.76), Vector2(0.30, 0.51),
				Vector2(0.48, 0.08), Vector2(0.56, 0.47), Vector2(0.73, 0.29),
				Vector2(0.82, 0.65), Vector2(0.70, 0.88), Vector2(0.52, 0.94)
			])
		"air":
			return _sample_curve(func(t: float) -> Vector2:
				var angle := t * TAU * 2.15
				var radius := 0.42 * (1.0 - t) + 0.035
				return Vector2(0.5, 0.5) + Vector2(cos(angle), sin(angle)) * radius, 58)
		"earth":
			return PackedVector2Array([
				Vector2(0.50, 0.08), Vector2(0.90, 0.86), Vector2(0.10, 0.86), Vector2(0.50, 0.08)
			])
		"accelerate":
			return PackedVector2Array([
				Vector2(0.08, 0.50), Vector2(0.88, 0.50), Vector2(0.64, 0.27),
				Vector2(0.88, 0.50), Vector2(0.64, 0.73)
			])
		"converge":
			return PackedVector2Array([
				Vector2(0.08, 0.18), Vector2(0.46, 0.50), Vector2(0.08, 0.82),
				Vector2(0.92, 0.18), Vector2(0.54, 0.50), Vector2(0.92, 0.82)
			])
		"maintain":
			return PackedVector2Array([
				Vector2(0.50, 0.07), Vector2(0.93, 0.50), Vector2(0.50, 0.93),
				Vector2(0.07, 0.50), Vector2(0.50, 0.07)
			])
		"spread":
			return PackedVector2Array([
				Vector2(0.50, 0.92), Vector2(0.50, 0.50), Vector2(0.15, 0.14),
				Vector2(0.50, 0.50), Vector2(0.85, 0.14)
			])
		"select":
			return _sample_curve(func(t: float) -> Vector2:
				var a := -PI * 0.5 + t * TAU
				return Vector2(0.5, 0.5) + Vector2(cos(a), sin(a)) * 0.42, 48)
		_:
			return PackedVector2Array([Vector2(0.1, 0.5), Vector2(0.9, 0.5)])

static func _sample_curve(callable: Callable, samples: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in samples:
		points.append(callable.call(float(i) / float(samples - 1)))
	return points

static func resample(points: PackedVector2Array, count: int) -> PackedVector2Array:
	if points.size() < 2 or count < 2:
		return points.duplicate()
	var lengths := PackedFloat32Array([0.0])
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
		lengths.append(total)
	if total < 0.001:
		return PackedVector2Array()
	var result := PackedVector2Array()
	var segment := 1
	for i in count:
		var target := total * float(i) / float(count - 1)
		while segment < lengths.size() - 1 and lengths[segment] < target:
			segment += 1
		var before := lengths[segment - 1]
		var after := lengths[segment]
		var weight := 0.0 if is_equal_approx(before, after) else (target - before) / (after - before)
		result.append(points[segment - 1].lerp(points[segment], weight))
	return result

static func normalized(points: PackedVector2Array) -> PackedVector2Array:
	if points.is_empty():
		return points
	var bounds := bounds_of(points)
	var scale := maxf(bounds.size.x, bounds.size.y)
	if scale < 0.001:
		return PackedVector2Array()
	var center := bounds.get_center()
	var result := PackedVector2Array()
	for point in points:
		result.append((point - center) / scale)
	return result

static func bounds_of(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var min_point := points[0]
	var max_point := points[0]
	for point in points:
		min_point = min_point.min(point)
		max_point = max_point.max(point)
	return Rect2(min_point, max_point - min_point)

static func transformed_template(glyph_id: String, center: Vector2, scale: float, rotation: float = 0.0) -> PackedVector2Array:
	var normalized_template := normalized(template_points(glyph_id, 72))
	var result := PackedVector2Array()
	for point in normalized_template:
		result.append(center + point.rotated(rotation) * scale)
	return result

