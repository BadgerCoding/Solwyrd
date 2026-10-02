extends Control
# Portrait main menu: profile header, four mode buttons, bottom bar.

func _ready() -> void:
    UI.background(self)
    UI.fireflies(self)
    var v := UI.margin(self, 30)
    v.add_child(_header())
    v.add_child(UI.label("Select your mode", 44))
    var modes := VBoxContainer.new()
    modes.size_flags_vertical = Control.SIZE_EXPAND_FILL
    modes.alignment = BoxContainer.ALIGNMENT_CENTER
    modes.add_theme_constant_override("separation", 40)
    v.add_child(modes)
    for m in [["Story Mode", "story_flow"], ["Create your own", "cyo_hub"], ["Online", "online"]]:
        var b := UI.button(m[0], Vector2(0, 170), 52)
        b.pressed.connect(func(): SceneRouter.go(m[1]))
        modes.add_child(b)
    var lan := UI.button("LAN", Vector2(0, 170), 52)
    lan.pressed.connect(func(): SceneRouter.go("placeholder", {"title": "LAN", "note": "Planned: multiplayer over a phone hotspot / same Wi-Fi (host and join, like Mini Militia).", "back": "main_menu"}))
    modes.add_child(lan)
    v.add_child(_bottom_bar())

func _header() -> Control:
    var panel := PanelContainer.new()
    var h := HBoxContainer.new()
    h.add_theme_constant_override("separation", 24)
    panel.add_child(h)
    h.add_child(UI.avatar(int(GameState.profile.get("avatar", 0)), 140))
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    info.alignment = BoxContainer.ALIGNMENT_CENTER
    h.add_child(info)
    var lvl := GameState.level()
    info.add_child(UI.label("Name: %s" % str(GameState.profile.get("username", "Player")), 38, HORIZONTAL_ALIGNMENT_LEFT))
    info.add_child(UI.label("Level: %d" % lvl, 34, HORIZONTAL_ALIGNMENT_LEFT))
    var xp := UI.bar(AppTheme.GOLD)
    xp.max_value = GameState.xp_needed(lvl)
    xp.value = GameState.xp()
    info.add_child(xp)
    return panel

func _bottom_bar() -> Control:
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    for item in [["Quest", "quest"], ["Achievement", "achievement"], ["Ranking", "ranking"], ["Shop", "shop"], ["Setting", "settings"]]:
        var key: String = item[1]
        var locked := key != "settings" and not GameState.is_unlocked(key)
        var text: String = item[0]
        if locked:
            text += "\n(Lv %d)" % int(GameState.UNLOCK_LEVELS[key])
        var b := UI.button(text, Vector2(0, 130), 26)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(func(): _open(key, locked))
        row.add_child(b)
    return row

func _open(key: String, locked: bool) -> void:
    if locked:
        UI.alert(self, "Unlocks at level %d." % int(GameState.UNLOCK_LEVELS[key]))
    elif key == "settings":
        SceneRouter.go("settings")
    else:
        SceneRouter.go("placeholder", {"title": key.capitalize(), "note": "Coming soon.", "back": "main_menu"})
