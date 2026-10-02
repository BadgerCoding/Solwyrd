extends Control
# After "Tap to start": Guest / Login / Register.

func _ready() -> void:
    UI.background(self)
    UI.fireflies(self, 14)
    var v := UI.margin(self, 40)
    var top := Control.new()
    top.size_flags_vertical = Control.SIZE_EXPAND_FILL
    v.add_child(top)
    v.add_child(UI.label("Welcome", 80))
    v.add_child(UI.spacer(30))
    var guest := UI.button("Play as guest", Vector2(0, 150), 48)
    guest.pressed.connect(_guest)
    v.add_child(guest)
    var login := UI.button("Login", Vector2(0, 150), 48)
    login.pressed.connect(func(): SceneRouter.go("login"))
    v.add_child(login)
    var register := UI.button("Register", Vector2(0, 150), 48)
    register.pressed.connect(func(): SceneRouter.go("register"))
    v.add_child(register)
    var note := UI.label("Guest progress stays on this phone only.", 28)
    note.add_theme_color_override("font_color", AppTheme.MUTED)
    v.add_child(note)
    var bottom := Control.new()
    bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
    bottom.size_flags_stretch_ratio = 0.6
    v.add_child(bottom)

func _guest() -> void:
    GameState.enter_account("guest")
    SceneRouter.go(GameState.next_screen())
