extends Control

const Language := preload("res://scripts/magic_language.gd")
const Compiler := preload("res://scripts/magic_compiler.gd")
const CanvasScript := preload("res://scripts/drawing_canvas.gd")
const TutorialScript := preload("res://scripts/tutorial_overlay.gd")

var canvas: Control
var result_status: Label
var result_subtitle: Label
var code_output: RichTextLabel
var diagnostics_output: RichTextLabel
var stats_grid: GridContainer
var stat_values: Dictionary = {}
var correction_toggle: CheckButton
var pen_button: Button
var eraser_button: Button
var compile_button: Button
var context_sliders: Dictionary = {}
var compiled_once := false

func _ready() -> void:
	_build_theme()
	_build_interface()
	get_viewport().set_embedding_subwindows(false)
	if "--capture-tutorial" in OS.get_cmdline_user_args():
		call_deferred("_capture_tutorial")
	elif "--capture" in OS.get_cmdline_user_args():
		call_deferred("_capture_demo")
	else:
		call_deferred("_show_tutorial_if_needed")

func _build_theme() -> void:
	var app_theme := Theme.new()
	app_theme.set_default_font_size(16)
	app_theme.set_color("font_color", "Label", Color("#eceaf5"))
	app_theme.set_color("font_color", "Button", Color("#e9e6f7"))
	app_theme.set_color("font_hover_color", "Button", Color.WHITE)
	app_theme.set_color("font_pressed_color", "Button", Language.CYAN)
	app_theme.set_font_size("font_size", "Button", 14)
	app_theme.set_constant("outline_size", "Label", 0)
	theme = app_theme

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#090d18")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 22)
	root_margin.add_theme_constant_override("margin_right", 22)
	root_margin.add_theme_constant_override("margin_top", 16)
	root_margin.add_theme_constant_override("margin_bottom", 18)
	add_child(root_margin)

	var root_column := VBoxContainer.new()
	root_column.add_theme_constant_override("separation", 14)
	root_margin.add_child(root_column)
	root_column.add_child(_build_header())

	var body := HSplitContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.split_offset = 820
	body.add_theme_constant_override("separation", 16)
	root_column.add_child(body)
	body.add_child(_build_workspace())
	body.add_child(_build_results())

func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.custom_minimum_size.y = 64
	header.add_theme_constant_override("separation", 14)
	var mark := Label.new()
	mark.text = "◈"
	mark.add_theme_font_size_override("font_size", 34)
	mark.add_theme_color_override("font_color", Language.CYAN)
	header.add_child(mark)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", -2)
	header.add_child(titles)
	var title := Label.new()
	title.text = "L'ATELIER DES GLYPHES"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	titles.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Compilateur visuel de matière, d'énergie et de mouvement"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("#8e93ac"))
	titles.add_child(subtitle)
	var tutorial := _button("?  Tutoriel", _open_tutorial)
	tutorial.tooltip_text = "Réouvrir le cours du langage magique"
	header.add_child(tutorial)
	compile_button = _button("COMPILER  ◆", _compile)
	compile_button.custom_minimum_size = Vector2(150, 44)
	compile_button.add_theme_color_override("font_color", Color.WHITE)
	compile_button.add_theme_stylebox_override("normal", _button_style(Color("#6548e8"), Color("#7657ff")))
	compile_button.add_theme_stylebox_override("hover", _button_style(Color("#7657ff"), Language.CYAN))
	header.add_child(compile_button)
	return header

func _build_workspace() -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 650
	column.add_theme_constant_override("separation", 10)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 7)
	column.add_child(toolbar)
	pen_button = _button("✎  Plume", _select_pen)
	eraser_button = _button("⌫  Gomme", _select_eraser)
	toolbar.add_child(pen_button)
	toolbar.add_child(eraser_button)
	toolbar.add_child(_separator())
	toolbar.add_child(_button("↶", func() -> void: canvas.undo(), "Annuler (Ctrl+Z)"))
	toolbar.add_child(_button("↷", func() -> void: canvas.redo(), "Rétablir (Ctrl+Y)"))
	toolbar.add_child(_button("Effacer", func() -> void: canvas.clear_canvas()))
	toolbar.add_child(_separator())
	toolbar.add_child(_button("Charger un exemple", _load_example))
	correction_toggle = CheckButton.new()
	correction_toggle.text = "Reconstruction"
	correction_toggle.button_pressed = true
	correction_toggle.tooltip_text = "Superposer les glyphes propres reconnus"
	correction_toggle.toggled.connect(func(active: bool) -> void: canvas.set_show_correction(active))
	correction_toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	correction_toggle.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	toolbar.add_child(correction_toggle)

	var canvas_panel := PanelContainer.new()
	canvas_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_panel.add_theme_stylebox_override("panel", _panel_style(Color("#11172a"), Color("#2f3652"), 12))
	column.add_child(canvas_panel)
	var canvas_margin := MarginContainer.new()
	canvas_margin.add_theme_constant_override("margin_left", 8)
	canvas_margin.add_theme_constant_override("margin_right", 8)
	canvas_margin.add_theme_constant_override("margin_top", 8)
	canvas_margin.add_theme_constant_override("margin_bottom", 8)
	canvas_panel.add_child(canvas_margin)
	canvas = CanvasScript.new()
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size = Vector2(620, 540)
	canvas.strokes_changed.connect(_on_strokes_changed)
	canvas_margin.add_child(canvas)

	column.add_child(_build_context_bar())
	_select_pen()
	return column

func _build_context_bar() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#11172a"), Color("#252d49"), 10))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)
	row.add_child(_context_slider("ink", "Encre", 0.72))
	row.add_child(_context_slider("mastery", "Maîtrise", 0.75))
	row.add_child(_context_slider("focus", "Concentration", 0.82))
	row.add_child(_context_slider("ambient", "Énergie ambiante", 0.65))
	row.add_child(_context_slider("matter", "Matière", 0.70))
	row.add_child(_context_slider("caster", "Énergie humaine", 0.20))
	return panel

func _context_slider(key: String, label_text: String, initial: float) -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size.x = 90
	box.add_theme_constant_override("separation", 2)
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#969cb5"))
	box.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.05
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial
	slider.tooltip_text = "%s : %d %%" % [label_text, int(initial * 100.0)]
	slider.value_changed.connect(func(value: float) -> void:
		slider.tooltip_text = "%s : %d %%" % [label_text, int(value * 100.0)]
		if compiled_once:
			_compile()
	)
	box.add_child(slider)
	context_sliders[key] = slider
	return box

func _build_results() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 390
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#0f1425"), Color("#292f49"), 14))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 14)
	scroll.add_child(column)

	var eyebrow := Label.new()
	eyebrow.text = "SORTIE DU COMPILATEUR"
	eyebrow.add_theme_font_size_override("font_size", 12)
	eyebrow.add_theme_color_override("font_color", Language.CYAN)
	column.add_child(eyebrow)
	result_status = Label.new()
	result_status.text = "EN ATTENTE"
	result_status.add_theme_font_size_override("font_size", 30)
	result_status.add_theme_color_override("font_color", Color("#777d96"))
	column.add_child(result_status)
	result_subtitle = Label.new()
	result_subtitle.text = "Dessinez un pentacle puis compilez-le."
	result_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_subtitle.add_theme_color_override("font_color", Color("#9da2ba"))
	column.add_child(result_subtitle)
	column.add_child(_rule())

	var stats_title := Label.new()
	stats_title.text = "MESURES PHYSIQUES"
	stats_title.add_theme_font_size_override("font_size", 12)
	stats_title.add_theme_color_override("font_color", Color("#8d93ad"))
	column.add_child(stats_title)
	stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 18)
	stats_grid.add_theme_constant_override("v_separation", 8)
	column.add_child(stats_grid)
	_add_stat("Qualité du tracé", "—", "drawing")
	_add_stat("Rendement", "—", "efficiency")
	_add_stat("Puissance utile", "—", "power")
	_add_stat("Masse transformée", "—", "mass")
	_add_stat("Vitesse", "—", "velocity")
	_add_stat("Durée", "—", "duration")
	_add_stat("Énergie d'impact", "—", "impact")
	_add_stat("Dommages", "—", "damage")
	column.add_child(_rule())

	var code_title := Label.new()
	code_title.text = "PSEUDO-CODE COMPILÉ"
	code_title.add_theme_font_size_override("font_size", 12)
	code_title.add_theme_color_override("font_color", Color("#8d93ad"))
	column.add_child(code_title)
	code_output = RichTextLabel.new()
	code_output.bbcode_enabled = true
	code_output.fit_content = true
	code_output.custom_minimum_size.y = 230
	code_output.add_theme_font_size_override("normal_font_size", 14)
	code_output.add_theme_color_override("default_color", Color("#cfd6f6"))
	code_output.text = "[color=#777d96]Aucun programme compilé.[/color]"
	column.add_child(code_output)

	var diagnostic_title := Label.new()
	diagnostic_title.text = "DIAGNOSTICS"
	diagnostic_title.add_theme_font_size_override("font_size", 12)
	diagnostic_title.add_theme_color_override("font_color", Color("#8d93ad"))
	column.add_child(diagnostic_title)
	diagnostics_output = RichTextLabel.new()
	diagnostics_output.bbcode_enabled = true
	diagnostics_output.fit_content = true
	diagnostics_output.custom_minimum_size.y = 80
	diagnostics_output.text = "[color=#777d96]Le compilateur signalera ici les erreurs et pertes.[/color]"
	column.add_child(diagnostics_output)
	return panel

func _compile() -> void:
	compiled_once = true
	compile_button.disabled = true
	compile_button.text = "LECTURE…"
	await get_tree().process_frame
	var context := {}
	for key in context_sliders:
		context[key] = context_sliders[key].value
	var result: Dictionary = Compiler.compile(canvas.strokes, canvas.size, context)
	canvas.set_correction(result.corrected)
	_update_results(result)
	compile_button.disabled = false
	compile_button.text = "COMPILER  ◆"

func _update_results(result: Dictionary) -> void:
	result_status.text = result.status
	var status_color := Color("#61e6b0") if result.valid and result.status == "STABLE" else Language.WARNING
	if not result.valid or result.status == "DANGEREUX":
		status_color = Language.DANGER
	result_status.add_theme_color_override("font_color", status_color)
	if result.valid:
		var metrics: Dictionary = result.metrics
		result_subtitle.text = "%s — %s" % [Language.GLYPHS[metrics.source].name, metrics.damage.description]
		_set_stat("drawing", "%d %%" % int(metrics.drawing_quality * 100.0))
		_set_stat("efficiency", "%d %%" % int(metrics.efficiency * 100.0))
		_set_stat("power", "%.0f Wₘ" % metrics.power)
		_set_stat("mass", "%.2f kg" % metrics.mass)
		_set_stat("velocity", "%.1f m/s" % metrics.velocity)
		_set_stat("duration", "%.2f s" % metrics.duration)
		_set_stat("impact", "%.0f J" % metrics.impact)
		_set_stat("damage", metrics.damage.label)
		code_output.text = "[font_size=14][color=#42d9da]" + _escape_bbcode(result.pseudo_code) + "[/color][/font_size]"
	else:
		result_subtitle.text = "Le programme ne peut pas être exécuté en sécurité."
		for key in stat_values:
			_set_stat(key, "—")
		code_output.text = "[color=#ff5d7a]COMPILATION INTERROMPUE[/color]\n[color=#777d96]Corrigez le cercle ou l'emblème-source.[/color]"
	var diagnostics: Array = result.diagnostics
	if diagnostics.is_empty():
		diagnostics_output.text = "[color=#61e6b0]✓ Aucun défaut majeur détecté.[/color]"
	else:
		var lines: Array[String] = []
		for diagnostic in diagnostics:
			var color := "#ff5d7a" if diagnostic.level in ["error", "danger"] else "#ffbd59"
			lines.append("[color=%s]• %s[/color]" % [color, diagnostic.text])
		diagnostics_output.text = "\n".join(lines)

func _add_stat(label_text: String, value_text: String, key: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("#8f95ad"))
	stats_grid.add_child(label)
	var value := Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.add_theme_font_size_override("font_size", 14)
	value.add_theme_color_override("font_color", Color("#ecedfa"))
	stats_grid.add_child(value)
	stat_values[key] = value

func _set_stat(key: String, text: String) -> void:
	if stat_values.has(key):
		stat_values[key].text = text

func _load_example() -> void:
	canvas.add_example()
	await get_tree().process_frame
	_compile()

func _select_pen() -> void:
	if not is_instance_valid(canvas):
		return
	canvas.set_eraser(false)
	pen_button.button_pressed = true
	eraser_button.button_pressed = false

func _select_eraser() -> void:
	canvas.set_eraser(true)
	pen_button.button_pressed = false
	eraser_button.button_pressed = true

func _on_strokes_changed() -> void:
	if compiled_once:
		result_status.text = "MODIFIÉ"
		result_status.add_theme_color_override("font_color", Color("#8d93ad"))
		result_subtitle.text = "Le dessin a changé. Relancez la compilation."

func _show_tutorial_if_needed() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK or not bool(config.get_value("tutorial", "seen", false)):
		_open_tutorial(true)

func _open_tutorial(mark_seen: bool = false) -> void:
	if get_node_or_null("TutorialOverlay"):
		return
	var tutorial = TutorialScript.new()
	tutorial.name = "TutorialOverlay"
	tutorial.closed.connect(func() -> void:
		if mark_seen:
			var config := ConfigFile.new()
			config.set_value("tutorial", "seen", true)
			config.save("user://settings.cfg")
	)
	add_child(tutorial)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("undo"):
		canvas.undo()
	elif event.is_action_pressed("redo"):
		canvas.redo()
	elif event.is_action_pressed("compile_spell"):
		_compile()

func _button(text_value: String, callback: Callable, tooltip: String = "") -> Button:
	var button := Button.new()
	button.text = text_value
	button.tooltip_text = tooltip
	button.toggle_mode = text_value.contains("Plume") or text_value.contains("Gomme")
	button.add_theme_stylebox_override("normal", _button_style(Color("#151b30"), Color("#2b3351")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#202844"), Language.ACCENT))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#2a3151"), Language.CYAN))
	button.pressed.connect(callback)
	return button

func _button_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _panel_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _separator() -> VSeparator:
	var separator := VSeparator.new()
	separator.custom_minimum_size.x = 8
	return separator

func _rule() -> HSeparator:
	var separator := HSeparator.new()
	separator.add_theme_constant_override("separation", 8)
	return separator

func _escape_bbcode(text_value: String) -> String:
	return text_value.replace("[", "[lb]")

func _capture_demo() -> void:
	canvas.add_example()
	await get_tree().process_frame
	await _compile()
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/ui-preview.png")
	get_tree().quit()

func _capture_tutorial() -> void:
	_open_tutorial(false)
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/tutorial-preview.png")
	get_tree().quit()

