extends Control
# "Tap to start" screen. Tapping anywhere continues to Guest / Login / Register (or straight on if you are still logged in).

const GAME_TITLE := "PB Quiz RPG"   # placeholder: put your game's real name here

var _done := false

func _ready() -> void:
	UI.background(self)
	UI.fireflies(self, 18)
	var v := UI.margin(self, 40)
	var top := Control.new()
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top.size_flags_stretch_ratio = 1.4
	v.add_child(top)
	v.add_child(UI.label(GAME_TITLE, 96))
	var mid := Control.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.size_flags_stretch_ratio = 1.6
	v.add_child(mid)
	var tap := UI.label("Tap to start", 52)
	tap.add_theme_color_override("font_color", AppTheme.PALE)
	tap.add_theme_color_override("font_outline_color", AppTheme.DARK)
	tap.add_theme_constant_override("outline_size", 8)
	v.add_child(tap)
	var credit := UI.label("PB Presents", 30)
	credit.add_theme_color_override("font_color", AppTheme.MUTED)
	v.add_child(credit)
	if bool(GameState.settings.get("animation", true)):
		var tw := tap.create_tween().set_loops()
		tw.tween_property(tap, "modulate:a", 0.25, 0.8)
		tw.tween_property(tap, "modulate:a", 1.0, 0.8)
	# Invisible full-screen button catches the tap.
	var catcher := Button.new()
	catcher.flat = true
	catcher.focus_mode = Control.FOCUS_NONE
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		catcher.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	catcher.pressed.connect(_proceed)
	add_child(catcher)

func _proceed() -> void:
	if _done:
		return
	_done = true
	SceneRouter.go(GameState.next_screen())
