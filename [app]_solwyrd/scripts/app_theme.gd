class_name AppTheme
extends RefCounted
# One shared look for the whole app: night-forest pixel UI (chunky dark outlines, raised moss-green buttons,
# dark teal panels). Change the palette below and every screen follows.
# Optional pixel font: put a .ttf at res://assets/fonts/pixel.ttf (see README for import settings).

const DARK := Color("07140f")       # outlines
const BG := Color("0b1f2a")         # fallback screen colour (night sky)
const PANEL_IN := Color(0.04, 0.13, 0.15, 0.88)   # dark inner panel (slightly see-through)
const MOSS := Color("2f6b3a")       # buttons / frames
const MOSS_HI := Color("3f8a4a")    # hover
const MOSS_LO := Color("1f4a2a")    # pressed
const OFF := Color("243a35")        # disabled
const GOLD := Color("f2c14e")       # firefly gold: highlights, headings
const PALE := Color("e4f2d2")       # body text
const MUTED := Color("6f9488")      # disabled text, placeholders
const FONT_PATH := "res://assets/fonts/pixel.ttf"

static func _box(bg: Color, border: Color, bw: int, bottom: int, pad_x: int, pad_y: int, top_shift := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = bw
	s.border_width_right = bw
	s.border_width_top = bw
	s.border_width_bottom = bottom
	s.set_corner_radius_all(4)
	s.corner_detail = 1
	s.anti_aliasing = false
	s.content_margin_left = pad_x
	s.content_margin_right = pad_x
	s.content_margin_top = pad_y + top_shift
	s.content_margin_bottom = pad_y
	return s

static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 32
	if ResourceLoader.exists(FONT_PATH):
		t.default_font = load(FONT_PATH)

	# Buttons: raised block with a thick bottom edge; pressed = pushed in.
	t.set_stylebox("normal", "Button", _box(MOSS, DARK, 5, 11, 16, 8))
	t.set_stylebox("hover", "Button", _box(MOSS_HI, DARK, 5, 11, 16, 8))
	t.set_stylebox("pressed", "Button", _box(MOSS_LO, DARK, 5, 5, 16, 8, 6))
	t.set_stylebox("disabled", "Button", _box(OFF, DARK, 5, 11, 16, 8))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", PALE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", MUTED)
	t.set_color("font_outline_color", "Button", DARK)
	t.set_constant("outline_size", "Button", 6)

	# Panels and dialogs: dark inside, brown frame.
	t.set_stylebox("panel", "PanelContainer", _box(PANEL_IN, MOSS_HI, 8, 8, 20, 16))
	t.set_stylebox("panel", "Panel", _box(PANEL_IN, MOSS_HI, 8, 8, 8, 8))

	# Text inputs
	for kind in ["LineEdit", "TextEdit"]:
		t.set_stylebox("normal", kind, _box(Color(0.03, 0.09, 0.08, 0.9), MOSS_HI, 4, 4, 14, 10))
		t.set_stylebox("focus", kind, _box(DARK, GOLD, 4, 4, 14, 10))
		t.set_color("font_color", kind, PALE)
		t.set_color("font_placeholder_color", kind, MUTED)
		t.set_color("caret_color", kind, GOLD)

	# Bars (UI.bar() sets the fill colour per bar)
	t.set_stylebox("background", "ProgressBar", _box(DARK, MOSS_LO, 3, 3, 0, 0))
	t.set_stylebox("fill", "ProgressBar", _box(GOLD, GOLD, 0, 0, 0, 0))

	# Toggles and sliders: keep Godot's icons, recolour the text.
	for kind in ["CheckButton", "CheckBox"]:
		t.set_color("font_color", kind, PALE)
		t.set_color("font_hover_color", kind, Color.WHITE)
		t.set_color("font_pressed_color", kind, GOLD)
		t.set_color("font_hover_pressed_color", kind, GOLD)
	t.set_color("font_color", "Label", PALE)
	return t
