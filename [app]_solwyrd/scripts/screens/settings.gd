extends Control
# Setting: sound/animation, AI key + model, credits, extra info, log out.

var _key: LineEdit
var _model: LineEdit

func _ready() -> void:
    UI.background(self)
    var v := UI.margin(self, 40)
    v.add_child(UI.label("Setting", 60))
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(scroll)
    var c := VBoxContainer.new()
    c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    c.add_theme_constant_override("separation", 24)
    scroll.add_child(c)

    c.add_child(_toggle("Animation", "animation"))
    c.add_child(_toggle("Sound", "sound"))

    c.add_child(UI.label("AI (Gemini) for Create Your Own", 36))
    _model = LineEdit.new()
    _model.text = str(GameState.settings.get("model", ""))
    _model.placeholder_text = "Model name"
    _model.add_theme_font_size_override("font_size", 34)
    c.add_child(_model)
    _key = LineEdit.new()
    _key.text = str(GameState.settings.get("api_key", ""))
    _key.placeholder_text = "Gemini API key"
    _key.secret = true
    _key.add_theme_font_size_override("font_size", 34)
    c.add_child(_key)
    var save := UI.button("Save AI settings", Vector2(0, 100), 38)
    save.pressed.connect(_save_ai)
    c.add_child(save)

    var credits := UI.button("Credits", Vector2(0, 100), 38)
    credits.pressed.connect(func(): UI.alert(self, "PB Presents (Programming_Badger)\nBuilt with Godot Engine."))
    c.add_child(credits)
    var info := UI.button("Extra information", Vector2(0, 100), 38)
    info.pressed.connect(func(): UI.alert(self, "Documents and photos you upload are sent to Google's Gemini API to write your quiz. On Google's free tier, Google may use submitted content to improve its products, so avoid private or sensitive material."))
    c.add_child(info)
    var out := UI.button("Log out", Vector2(0, 100), 38)
    out.pressed.connect(_confirm_logout)
    c.add_child(out)

    var back := UI.button("Back", Vector2(0, 120), 44)
    back.pressed.connect(SceneRouter.back)
    v.add_child(back)

func _toggle(text: String, key: String) -> CheckButton:
    var t := CheckButton.new()
    t.text = text
    t.add_theme_font_size_override("font_size", 38)
    t.button_pressed = bool(GameState.settings.get(key, true))
    t.toggled.connect(func(on: bool):
        GameState.settings[key] = on
        GameState.save_settings())
    return t

func _save_ai() -> void:
    GameState.settings["model"] = _model.text.strip_edges()
    GameState.settings["api_key"] = _key.text.strip_edges()
    GameState.save_settings()
    UI.alert(self, "Saved.")

func _confirm_logout() -> void:
    UI.dialog(self, "Log out? Your progress stays saved on this phone. Log back in to continue where you left off.", [["Cancel", Callable()], ["Log out", _do_logout]])

func _do_logout() -> void:
    GameState.logout()
    SceneRouter.go("auth_menu")
