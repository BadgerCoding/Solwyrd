extends Control

var _user: LineEdit
var _pass: LineEdit
var _confirm: LineEdit
var _error: Label

func _ready() -> void:
    UI.background(self)
    UI.fireflies(self, 10)
    var v := UI.margin(self, 40)
    v.add_child(UI.spacer(100))
    v.add_child(UI.label("Register", 72))
    _user = UI.field("Username (3-16 letters, numbers, _)")
    v.add_child(_user)
    _pass = UI.field("Password (6+ characters)", true)
    v.add_child(_pass)
    _confirm = UI.field("Confirm password", true)
    _confirm.text_submitted.connect(func(_t): _submit())
    v.add_child(_confirm)
    _error = UI.error_label()
    v.add_child(_error)
    var note := UI.label("For now, accounts are saved on this phone only.", 28)
    note.add_theme_color_override("font_color", AppTheme.MUTED)
    v.add_child(note)
    var go := UI.button("Create account", Vector2(0, 140), 48)
    go.pressed.connect(_submit)
    v.add_child(go)
    var back := UI.button("Back", Vector2(0, 110), 40)
    back.pressed.connect(SceneRouter.back)
    v.add_child(back)

func _submit() -> void:
    if _pass.text != _confirm.text:
        _error.text = "Passwords do not match."
        return
    var err := GameState.register(_user.text, _pass.text)
    if err != "":
        _error.text = err
        return
    SceneRouter.go("profile_setup")
