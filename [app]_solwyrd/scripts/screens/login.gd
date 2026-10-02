extends Control

var _user: LineEdit
var _pass: LineEdit
var _error: Label

func _ready() -> void:
    UI.background(self)
    UI.fireflies(self, 10)
    var v := UI.margin(self, 40)
    v.add_child(UI.spacer(140))
    v.add_child(UI.label("Login", 72))
    _user = UI.field("Username")
    v.add_child(_user)
    _pass = UI.field("Password", true)
    _pass.text_submitted.connect(func(_t): _submit())
    v.add_child(_pass)
    _error = UI.error_label()
    v.add_child(_error)
    var go := UI.button("Login", Vector2(0, 140), 48)
    go.pressed.connect(_submit)
    v.add_child(go)
    var back := UI.button("Back", Vector2(0, 110), 40)
    back.pressed.connect(SceneRouter.back)
    v.add_child(back)

func _submit() -> void:
    var err := GameState.login(_user.text, _pass.text)
    if err != "":
        _error.text = err
        return
    SceneRouter.go(GameState.next_screen())
