extends Control
# After the account step: customize your profile = display name + one of the 8 default avatars.

var _name: LineEdit
var _selected := 0

func _ready() -> void:
    UI.background(self)
    var v := UI.margin(self, 40)
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_child(UI.label("Customize your profile", 56))
    _name = LineEdit.new()
    _name.placeholder_text = "Username"
    _name.max_length = 16
    _name.text = GameState.account_username()
    _name.custom_minimum_size = Vector2(0, 100)
    _name.add_theme_font_size_override("font_size", 40)
    v.add_child(_name)
    v.add_child(UI.label("Choose your avatar", 36))
    var grid := GridContainer.new()
    grid.columns = 4
    grid.add_theme_constant_override("h_separation", 16)
    grid.add_theme_constant_override("v_separation", 16)
    v.add_child(grid)
    var group := ButtonGroup.new()
    for i in 8:
        var b := Button.new()
        b.toggle_mode = true
        b.button_group = group
        b.button_pressed = i == 0
        b.custom_minimum_size = Vector2(220, 220)
        var a := UI.avatar(i, 150)
        a.mouse_filter = Control.MOUSE_FILTER_IGNORE
        a.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
        b.add_child(a)
        b.pressed.connect(func(): _selected = i)
        grid.add_child(b)
    var go := UI.button("Continue", Vector2(0, 130), 48)
    go.pressed.connect(_on_start)
    v.add_child(go)

func _on_start() -> void:
    var n := _name.text.strip_edges()
    if n == "":
        UI.alert(self, "Please type a username.")
        return
    GameState.create_profile(n, _selected)
    SceneRouter.go("main_menu")
