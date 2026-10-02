class_name UI
extends RefCounted
# Small helpers so every screen can be built from code (no hand-written .tscn files).

const BG := Color("0b1f2a")   # same as AppTheme.BG
const WALLPAPER := "res://assets/backgrounds/app_background.jpg"
const AVATAR_COLORS = [Color("c4443a"), Color("d9822b"), Color("e9a85d"), Color("7fb04a"), Color("4f9a8a"), Color("5b86b8"), Color("8c5ea8"), Color("9a8a7a")]

static func button(text: String, min_size := Vector2(0, 120), font_size := 40) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	return b

static func label(text: String, font_size := 36, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	if font_size >= 56:   # headings: tan text with a dark pixel outline, like the UI kit titles
		l.add_theme_color_override("font_color", AppTheme.GOLD)
		l.add_theme_color_override("font_outline_color", AppTheme.DARK)
		l.add_theme_constant_override("outline_size", 10)
	return l

# Default background = the wallpaper (cropped to fill the screen) under a light dark tint for readability.
# Pass a different colour to get a plain colour instead.
static func background(parent: Control, color := BG) -> void:
	if color == BG and ResourceLoader.exists(WALLPAPER):
		var t := TextureRect.new()
		t.texture = load(WALLPAPER)
		t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(t)
		var dim := ColorRect.new()
		dim.color = Color(0.02, 0.07, 0.08, 0.3)
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(dim)
		return
	var r := ColorRect.new()
	r.color = color
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(r)

static func margin(parent: Control, m := 40) -> VBoxContainer:
	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, m)
	parent.add_child(mc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 24)
	mc.add_child(v)
	return v

static func bar(color: Color) -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, 28)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.anti_aliasing = false
	p.add_theme_stylebox_override("fill", fill)
	return p

static func centered(text: String, font_size := 60) -> Control:
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var l := label(text, font_size)
	l.custom_minimum_size = Vector2(900, 0)
	c.add_child(l)
	return c

# Uses res://assets/avatars/avatar_N.png if present, otherwise a coloured square.
static func avatar(index: int, size := 120) -> Control:
	var path := "res://assets/avatars/avatar_%d.png" % index
	if ResourceLoader.exists(path):
		var t := TextureRect.new()
		t.texture = load(path)
		t.custom_minimum_size = Vector2(size, size)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		return t
	var r := ColorRect.new()
	r.color = AVATAR_COLORS[index % AVATAR_COLORS.size()]
	r.custom_minimum_size = Vector2(size, size)
	return r

# Sprite from a texture path if it exists, otherwise a labelled coloured box.
static func sprite(path: String, color: Color, caption: String) -> Control:
	if ResourceLoader.exists(path):
		var t := TextureRect.new()
		t.texture = load(path)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		return t
	var r := ColorRect.new()
	r.color = color
	var l := label(caption, 40)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.add_child(l)
	return r

# options: [[button_text, Callable], ...]. Use Callable() for "just close".
static func dialog(parent: Control, text: String, options: Array) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.04, 0.02, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 28)
	panel.add_child(v)
	var l := label(text, 36)
	l.custom_minimum_size = Vector2(700, 0)
	v.add_child(l)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	v.add_child(row)
	for opt in options:
		var b := button(opt[0], Vector2(0, 100), 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cb: Callable = opt[1]
		var handler := func() -> void:
			dim.queue_free()
			if cb.is_valid():
				cb.call()
		b.pressed.connect(handler)
		row.add_child(b)

static func alert(parent: Control, text: String) -> void:
	dialog(parent, text, [["OK", Callable()]])

# A few drifting firefly squares (matches the wallpaper). Skipped when Animation is off.
static func fireflies(parent: Control, count := 14) -> void:
	if not bool(GameState.settings.get("animation", true)):
		return
	var area := parent.get_viewport_rect().size
	for i in count:
		var f := ColorRect.new()
		f.color = AppTheme.GOLD
		f.size = Vector2(8, 8)
		f.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var start := Vector2(randf() * area.x, area.y * (0.3 + randf() * 0.65))
		f.position = start
		f.modulate.a = 0.0
		parent.add_child(f)
		var tw := f.create_tween().set_loops()
		tw.tween_interval(randf() * 3.0)
		tw.tween_property(f, "modulate:a", 0.9, 1.2)
		tw.parallel().tween_property(f, "position", start + Vector2(randf_range(-50.0, 50.0), -70.0), 3.0)
		tw.tween_property(f, "modulate:a", 0.0, 1.2)
		tw.tween_property(f, "position", start, 0.0)

static func spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c

static func field(placeholder: String, secret := false) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.secret = secret
	e.max_length = 32
	e.custom_minimum_size = Vector2(0, 110)
	e.add_theme_font_size_override("font_size", 40)
	return e

static func error_label() -> Label:
	var l := label("", 30)
	l.add_theme_color_override("font_color", Color("ff9b7a"))
	l.add_theme_color_override("font_outline_color", AppTheme.DARK)
	l.add_theme_constant_override("outline_size", 6)
	return l
