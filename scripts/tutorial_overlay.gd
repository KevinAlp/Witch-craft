class_name TutorialOverlay
extends ColorRect

const Language := preload("res://scripts/magic_language.gd")
const GlyphPreviewScene := preload("res://scripts/glyph_preview.gd")

signal closed

var page := 0
var title_label: Label
var body_label: Label
var examples: GridContainer
var page_label: Label
var previous_button: Button
var next_button: Button

var pages := [
	{
		"title": "Bienvenue dans l'Atelier",
		"body": "Un pentacle est un programme physique. Dessine une source au centre, place des opérations autour, puis ferme le grand cercle. Le bouton COMPILER lit les traits, corrige leurs formes et exécute le programme.",
		"glyphs": [],
	},
	{
		"title": "1 — Choisir une source",
		"body": "L'emblème central fixe le type de matière ou d'énergie prélevé dans l'environnement. Il doit rester près du centre du cercle.",
		"glyphs": ["water", "fire", "air", "earth"],
	},
	{
		"title": "2 — Ajouter des opérations",
		"body": "Les signes périphériques transforment le flux. Leur taille règle l'intensité et leur orientation peut régler une direction. Un signe mal tracé reste utilisable, mais augmente les pertes.",
		"glyphs": ["select", "converge", "accelerate", "maintain", "spread"],
	},
	{
		"title": "3 — Fermer et compiler",
		"body": "Trace le cercle en dernier et ferme-le correctement. Le compilateur vérifie les types, la matière, l'énergie, le débit de l'encre et la stabilité. Utilise EXEMPLE pour charger un premier sort d'eau.",
		"glyphs": ["water", "select", "converge", "accelerate", "maintain"],
	},
	{
		"title": "4 — Lire le résultat",
		"body": "Le pseudo-code décrit exactement le sort reconnu. Le rapport indique rendement, puissance, masse, vitesse, durée et dommages estimés. Le tracé cyan montre la reconstruction propre proposée par le moteur.",
		"glyphs": [],
	},
]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.02, 0.025, 0.05, 0.91)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	_show_page()

func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 570)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 42)
	margin.add_theme_constant_override("margin_right", 42)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)

	var eyebrow := Label.new()
	eyebrow.text = "TUTORIEL DU LANGAGE MAGIQUE"
	eyebrow.add_theme_color_override("font_color", Language.CYAN)
	eyebrow.add_theme_font_size_override("font_size", 14)
	column.add_child(eyebrow)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color("#17162a"))
	column.add_child(title_label)
	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size.y = 86
	body_label.add_theme_font_size_override("font_size", 18)
	body_label.add_theme_color_override("font_color", Color("#45415b"))
	column.add_child(body_label)
	examples = GridContainer.new()
	examples.columns = 5
	examples.size_flags_vertical = Control.SIZE_EXPAND_FILL
	examples.add_theme_constant_override("h_separation", 12)
	examples.add_theme_constant_override("v_separation", 14)
	column.add_child(examples)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 10)
	column.add_child(footer)
	var skip := Button.new()
	skip.text = "Passer le tutoriel"
	skip.flat = true
	skip.add_theme_color_override("font_color", Color("#5d43d6"))
	skip.add_theme_color_override("font_hover_color", Color("#2b1c82"))
	skip.pressed.connect(_close)
	footer.add_child(skip)
	page_label = Label.new()
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_label.add_theme_color_override("font_color", Color("#5a566d"))
	footer.add_child(page_label)
	previous_button = Button.new()
	previous_button.text = "← Précédent"
	previous_button.add_theme_color_override("font_color", Color("#39354d"))
	previous_button.add_theme_color_override("font_disabled_color", Color("#aaa6b5"))
	previous_button.add_theme_stylebox_override("normal", _light_button_style(Color("#eeeaf5"), Color("#d5cfdf")))
	previous_button.add_theme_stylebox_override("disabled", _light_button_style(Color("#f4f1f6"), Color("#e5e0e8")))
	previous_button.pressed.connect(_previous)
	footer.add_child(previous_button)
	next_button = Button.new()
	next_button.text = "Suivant →"
	next_button.add_theme_color_override("font_color", Color.WHITE)
	next_button.add_theme_color_override("font_hover_color", Color.WHITE)
	next_button.add_theme_stylebox_override("normal", _light_button_style(Color("#6548e8"), Color("#6548e8")))
	next_button.add_theme_stylebox_override("hover", _light_button_style(Color("#7657ff"), Color("#42d9da")))
	next_button.pressed.connect(_next)
	footer.add_child(next_button)

func _show_page() -> void:
	var data: Dictionary = pages[page]
	title_label.text = data.title
	body_label.text = data.body
	page_label.text = "%d / %d" % [page + 1, pages.size()]
	previous_button.disabled = page == 0
	next_button.text = "Commencer" if page == pages.size() - 1 else "Suivant →"
	for child in examples.get_children():
		child.queue_free()
	for glyph_id in data.glyphs:
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(122, 138)
		card.alignment = BoxContainer.ALIGNMENT_CENTER
		var preview = GlyphPreviewScene.new().setup(glyph_id)
		preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card.add_child(preview)
		var label := Label.new()
		label.text = Language.GLYPHS[glyph_id].name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color("#302c48"))
		card.add_child(label)
		examples.add_child(card)

func _previous() -> void:
	page = maxi(0, page - 1)
	_show_page()

func _next() -> void:
	if page >= pages.size() - 1:
		_close()
	else:
		page += 1
		_show_page()

func _close() -> void:
	closed.emit()
	queue_free()

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fbfaf6")
	style.border_color = Color("#7657ff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 24
	return style

func _light_button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

