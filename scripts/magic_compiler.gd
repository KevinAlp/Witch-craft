class_name MagicCompiler
extends RefCounted

const Language := preload("res://scripts/magic_language.gd")

static func compile(strokes: Array, canvas_size: Vector2, context: Dictionary) -> Dictionary:
	var result := {
		"valid": false,
		"status": "INCOMPLET",
		"diagnostics": [],
		"tokens": [],
		"corrected": [],
		"pseudo_code": "",
		"metrics": {},
	}
	if strokes.is_empty():
		result.diagnostics.append({"level": "error", "text": "La feuille est vide."})
		return result

	var ring_index := _find_ring(strokes, canvas_size)
	if ring_index < 0:
		result.diagnostics.append({"level": "error", "text": "Aucun cercle d'activation fermé n'a été reconnu."})
		return result

	var ring_points: PackedVector2Array = strokes[ring_index]
	var ring_bounds := Language.bounds_of(ring_points)
	var ring_center := ring_bounds.get_center()
	var ring_radius := (ring_bounds.size.x + ring_bounds.size.y) * 0.25
	var closure := clampf(1.0 - ring_points[0].distance_to(ring_points[-1]) / maxf(ring_radius, 1.0), 0.0, 1.0)
	var circularity := _circularity(ring_points, ring_center, ring_radius)
	var ring_quality := clampf(closure * 0.55 + circularity * 0.45, 0.0, 1.0)
	result.corrected.append({"kind": "ring", "center": ring_center, "radius": ring_radius})

	var recognized: Array = []
	for i in strokes.size():
		if i == ring_index:
			continue
		var stroke: PackedVector2Array = strokes[i]
		if stroke.size() < 4:
			continue
		var bounds := Language.bounds_of(stroke)
		if not ring_bounds.grow(12.0).has_point(bounds.get_center()):
			result.diagnostics.append({"level": "warning", "text": "Un trait hors du cercle a été ignoré."})
			continue
		var category := "source" if bounds.get_center().distance_to(ring_center) < ring_radius * 0.34 else "operator"
		var token := _recognize(stroke, category)
		token["stroke_index"] = i
		token["center"] = bounds.get_center()
		token["scale"] = maxf(bounds.size.x, bounds.size.y)
		recognized.append(token)

	var sources := recognized.filter(func(token: Dictionary) -> bool: return token.category == "source" and token.confidence >= 0.38)
	var operators := recognized.filter(func(token: Dictionary) -> bool: return token.category == "operator" and token.confidence >= 0.34)
	if sources.is_empty():
		result.diagnostics.append({"level": "error", "text": "Il manque un emblème-source lisible au centre."})
	else:
		sources.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.center.distance_to(ring_center) < b.center.distance_to(ring_center))
		if sources.size() > 1:
			result.diagnostics.append({"level": "warning", "text": "Plusieurs sources ont été détectées ; la plus centrale est prioritaire."})

	for token in recognized:
		result.tokens.append(token)
		if token.confidence < 0.34:
			result.diagnostics.append({"level": "warning", "text": "Symbole incertain près de (%d, %d)." % [token.center.x, token.center.y]})
		else:
			result.corrected.append({
				"kind": "glyph",
				"glyph_id": token.id,
				"points": Language.transformed_template(token.id, token.center, maxf(token.scale, 38.0), token.rotation),
				"confidence": token.confidence,
			})

	if sources.is_empty():
		result["status"] = "ERREUR DE TYPE"
		return result

	var source: Dictionary = sources[0]
	var avg_confidence: float = float(source.confidence)
	for operator in operators:
		avg_confidence += operator.confidence
	avg_confidence /= float(operators.size() + 1)

	var drawing_quality: float = clampf(avg_confidence * 0.64 + ring_quality * 0.36, 0.0, 1.0)
	var knowledge: float = float(context.get("mastery", 0.75))
	var focus: float = float(context.get("focus", 0.82))
	var ink_quality: float = float(context.get("ink", 0.72))
	var ambient: float = float(context.get("ambient", 0.65))
	var matter: float = float(context.get("matter", 0.70))
	var caster: float = float(context.get("caster", 0.20))
	var efficiency := clampf(0.88 * drawing_quality * knowledge * focus, 0.02, 0.88)
	var diameter_m := clampf(ring_radius / maxf(canvas_size.x, canvas_size.y) * 8.0, 0.2, 4.0)
	var ink_power := ink_quality * diameter_m * 1350.0
	var environmental_power := ambient * matter * diameter_m * 1900.0
	var caster_power := caster * knowledge * 950.0
	var available_power := minf(ink_power, environmental_power + caster_power)
	var useful_power := available_power * efficiency
	var source_mass := matter * diameter_m * _source_density_factor(source.id)
	var has_acceleration := _has_operator(operators, "accelerate")
	var has_convergence := _has_operator(operators, "converge")
	var has_maintain := _has_operator(operators, "maintain")
	var has_spread := _has_operator(operators, "spread")
	var has_select := _has_operator(operators, "select")
	var mass := maxf(0.08, source_mass * (0.62 if has_select else 1.0))
	var kinetic_share := 0.62 if has_acceleration else 0.08
	var kinetic_energy := useful_power * kinetic_share
	var velocity := sqrt(maxf(0.0, 2.0 * kinetic_energy / mass))
	if has_convergence:
		velocity *= 0.92
	var cohesion := clampf(0.25 + (0.32 if has_convergence else 0.0) + (0.25 if has_maintain else 0.0) + drawing_quality * 0.18, 0.0, 1.0)
	var duration := (0.5 + ink_quality * 2.4) * (1.7 if has_maintain else 1.0) * drawing_quality
	var activation_time := maxf(0.12, (mass * 240.0) / maxf(useful_power, 1.0))
	var impact_energy := 0.5 * mass * velocity * velocity * (0.72 + cohesion * 0.28)
	if has_spread:
		impact_energy *= 0.52
		velocity *= 0.78
	var damage := _damage_band(impact_energy, source.id)

	if operators.is_empty():
		result.diagnostics.append({"level": "warning", "text": "Aucun opérateur fiable : la source sera seulement libérée autour du cercle."})
	if efficiency < 0.23:
		result.diagnostics.append({"level": "danger", "text": "Rendement critique : les pertes chaufferont fortement le support."})
	elif efficiency < 0.42:
		result.diagnostics.append({"level": "warning", "text": "Le dessin produit beaucoup de pertes parasites."})
	if useful_power > ink_power * 0.88:
		result.diagnostics.append({"level": "warning", "text": "Le circuit approche du débit maximal de l'encre."})

	result["valid"] = true
	result["status"] = "STABLE" if efficiency >= 0.48 else ("INSTABLE" if efficiency >= 0.24 else "DANGEREUX")
	result["metrics"] = {
		"drawing_quality": drawing_quality,
		"efficiency": efficiency,
		"power": useful_power,
		"mass": mass,
		"velocity": velocity,
		"duration": duration,
		"activation": activation_time,
		"impact": impact_energy,
		"cohesion": cohesion,
		"damage": damage,
		"source": source.id,
	}
	result["pseudo_code"] = _pseudo_code(source, operators, result.metrics, diameter_m)
	return result

static func _find_ring(strokes: Array, canvas_size: Vector2) -> int:
	var best_index := -1
	var best_score := 0.0
	var minimum_size := minf(canvas_size.x, canvas_size.y) * 0.28
	for i in strokes.size():
		var points: PackedVector2Array = strokes[i]
		if points.size() < 12:
			continue
		var bounds := Language.bounds_of(points)
		if minf(bounds.size.x, bounds.size.y) < minimum_size:
			continue
		var center := bounds.get_center()
		var radius := (bounds.size.x + bounds.size.y) * 0.25
		var closure := 1.0 - clampf(points[0].distance_to(points[-1]) / maxf(radius, 1.0), 0.0, 1.0)
		var score := closure * 0.62 + _circularity(points, center, radius) * 0.38
		if score > best_score and score > 0.50:
			best_score = score
			best_index = i
	return best_index

static func _circularity(points: PackedVector2Array, center: Vector2, radius: float) -> float:
	if points.is_empty() or radius <= 0.0:
		return 0.0
	var deviation := 0.0
	for point in points:
		deviation += absf(point.distance_to(center) - radius)
	deviation /= float(points.size()) * radius
	return clampf(1.0 - deviation * 2.2, 0.0, 1.0)

static func _recognize(stroke: PackedVector2Array, category: String) -> Dictionary:
	var candidate := Language.normalized(Language.resample(stroke, 64))
	var best := {"id": "unknown", "score": 999.0, "rotation": 0.0}
	for glyph_id in Language.glyph_ids(category):
		var template := Language.normalized(Language.template_points(glyph_id, 64))
		var rotations := 24 if category == "operator" else 1
		for r in rotations:
			var angle := float(r) / float(rotations) * TAU
			var score := _path_distance(candidate, template, angle)
			var reverse_score := _path_distance(_reversed(candidate), template, angle)
			if reverse_score < score:
				score = reverse_score
			if score < best.score:
				best = {"id": glyph_id, "score": score, "rotation": -angle}
	var confidence := clampf(1.0 - float(best.score) / 0.62, 0.0, 1.0)
	return {
		"id": best.id,
		"category": category,
		"confidence": confidence,
		"rotation": best.rotation,
	}

static func _path_distance(candidate: PackedVector2Array, template: PackedVector2Array, rotation: float) -> float:
	if candidate.size() != template.size() or candidate.is_empty():
		return 999.0
	var total := 0.0
	for i in candidate.size():
		total += candidate[i].rotated(rotation).distance_to(template[i])
	return total / float(candidate.size())

static func _reversed(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in range(points.size() - 1, -1, -1):
		result.append(points[i])
	return result

static func _has_operator(operators: Array, glyph_id: String) -> bool:
	for operator in operators:
		if operator.id == glyph_id:
			return true
	return false

static func _source_density_factor(source_id: String) -> float:
	match source_id:
		"earth": return 5.2
		"water": return 2.6
		"air": return 0.35
		"fire": return 0.12
	return 1.0

static func _damage_band(energy: float, source_id: String) -> Dictionary:
	var adjusted := energy * (1.18 if source_id == "fire" else 1.0)
	if adjusted < 80.0:
		return {"label": "NÉGLIGEABLE", "score": 1, "description": "Poussée légère, surtout utilitaire."}
	if adjusted < 350.0:
		return {"label": "FAIBLE", "score": 2, "description": "Contusions ou brûlures superficielles possibles."}
	if adjusted < 1200.0:
		return {"label": "SÉRIEUX", "score": 3, "description": "Impact dangereux, fractures ou brûlures probables."}
	if adjusted < 3500.0:
		return {"label": "CRITIQUE", "score": 4, "description": "Traumatisme majeur ; usage fortement réglementé."}
	return {"label": "CATASTROPHIQUE", "score": 5, "description": "Énergie potentiellement létale et destructrice."}

static func _pseudo_code(source: Dictionary, operators: Array, metrics: Dictionary, diameter: float) -> String:
	var source_name: String = Language.GLYPHS[source.id].name
	var lines: Array[String] = []
	lines.append("PROGRAMME PENTACLE {")
	lines.append("  SOURCE %s FROM environnement" % source_name)
	lines.append("    WITHIN rayon(%.2f m)" % diameter)
	if _has_operator(operators, "select"):
		lines.append("  SÉLECTIONNER masse = %.2f kg" % metrics.mass)
	else:
		lines.append("  PRÉLEVER masse_disponible ≈ %.2f kg" % metrics.mass)
	if _has_operator(operators, "converge"):
		lines.append("  CONVERGER cohésion = %.0f %%" % (metrics.cohesion * 100.0))
	if _has_operator(operators, "spread"):
		lines.append("  DISPERSER branches = 2")
	if _has_operator(operators, "accelerate"):
		lines.append("  ACCÉLÉRER vitesse ≈ %.1f m/s" % metrics.velocity)
	if _has_operator(operators, "maintain"):
		lines.append("  MAINTENIR pendant ≈ %.2f s" % metrics.duration)
	else:
		lines.append("  RELÂCHER après %.2f s" % metrics.duration)
	lines.append("  LIMITER puissance = %.0f Wₘ" % metrics.power)
	lines.append("}")
	lines.append("")
	lines.append("// activation : %.2f s" % metrics.activation)
	lines.append("// énergie d'impact : %.0f J" % metrics.impact)
	lines.append("// dommages : %s" % metrics.damage.label)
	return "\n".join(lines)

