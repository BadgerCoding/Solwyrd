extends Control
# Story Mode: rotate prompt -> PB Presents -> game menu (New Game / Continue / Options).
# New Game / Continue currently open a placeholder. Swap in your real RPG at _start_story().

const WALLPAPER := "res://assets/wizard_wallpaper.png"   # your wise-wizard wallpaper (optional)

var _content: Control
var _stage := "intro"

func _ready() -> void:
    UI.background(self, Color.BLACK)
    _run_intro()

func _set_content(c: Control) -> void:
    if _content:
        _content.queue_free()
    _content = c
    add_child(c)

func _run_intro() -> void:
    _set_content(UI.centered("Rotate your phone sideways", 56))
    await get_tree().create_timer(1.8).timeout
    if not is_inside_tree(): return
    SceneRouter.set_landscape(true)
    await get_tree().create_timer(0.7).timeout
    if not is_inside_tree(): return
    _set_content(UI.centered("PB Presents", 90))
    await get_tree().create_timer(2.2).timeout
    if not is_inside_tree(): return
    _show_menu()

func _backdrop() -> Control:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    if ResourceLoader.exists(WALLPAPER):
        var t := TextureRect.new()
        t.texture = load(WALLPAPER)
        t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        root.add_child(t)
    else:
        var r := ColorRect.new()
        r.color = AppTheme.PANEL_IN
        r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        root.add_child(r)
    return root

func _column(root: Control) -> VBoxContainer:
    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(center)
    var v := VBoxContainer.new()
    v.custom_minimum_size = Vector2(620, 0)
    v.add_theme_constant_override("separation", 24)
    center.add_child(v)
    return v

func _show_menu() -> void:
    _stage = "menu"
    var root := _backdrop()
    var v := _column(root)
    var new_game := UI.button("New Game", Vector2(0, 110), 44)
    new_game.pressed.connect(_start_story.bind(true))
    v.add_child(new_game)
    var cont := UI.button("Continue", Vector2(0, 110), 44)
    cont.disabled = not FileAccess.file_exists(GameState.story_save_file)
    cont.pressed.connect(_start_story.bind(false))
    v.add_child(cont)
    var opt := UI.button("Options", Vector2(0, 110), 44)
    opt.pressed.connect(_show_options)
    v.add_child(opt)
    var back := UI.button("Back", Vector2(0, 110), 44)
    back.pressed.connect(SceneRouter.go_parent)
    v.add_child(back)
    _set_content(root)

func _show_options() -> void:
    _stage = "options"
    var root := _backdrop()
    var v := _column(root)
    for item in [["Animation", "animation"], ["Sound", "sound"]]:
        var key: String = item[1]
        var t := CheckButton.new()
        t.text = item[0]
        t.add_theme_font_size_override("font_size", 44)
        t.button_pressed = bool(GameState.settings.get(key, true))
        t.toggled.connect(func(on: bool):
            GameState.settings[key] = on
            GameState.save_settings())
        v.add_child(t)
    var back := UI.button("Back", Vector2(0, 110), 44)
    back.pressed.connect(_show_menu)
    v.add_child(back)
    _set_content(root)

func _start_story(new_game: bool) -> void:
    if new_game:
        SaveManager.save_json(GameState.story_save_file, {"chapter": 1, "created": int(Time.get_unix_time_from_system())})
    # >>> CONNECT YOUR RPG HERE <<<
    # Replace the line below with: SceneRouter.launch_scene("res://story/your_first_scene.tscn")
    # and call SceneRouter.return_to_app() from your game to come back to the menu.
    SceneRouter.go("story_placeholder", {"new_game": new_game})

func on_back() -> void:
    if _stage == "options":
        _show_menu()
    else:
        SceneRouter.go_parent()
