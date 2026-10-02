extends Control
# Create Your Own hub: Continue / List / Upload / Scan.

func _ready() -> void:
    UI.background(self)
    var v := UI.margin(self, 40)
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_child(UI.label("Create Your Own", 64))
    var has_save := FileAccess.file_exists(GameState.cyo_save_file)
    _add(v, "Continue", has_save, func(): SceneRouter.go("battle", {"resume": true}))
    _add(v, "List", true, func(): SceneRouter.go("cyo_documents"))
    _add(v, "Upload", true, func(): SceneRouter.go("cyo_upload", {"mode": "upload"}))
    _add(v, "Scan", true, func(): SceneRouter.go("cyo_upload", {"mode": "scan"}))
    var back := UI.button("Back", Vector2(0, 120), 44)
    back.pressed.connect(SceneRouter.back)
    v.add_child(back)

func _add(parent: Control, text: String, enabled: bool, action: Callable) -> void:
    var b := UI.button(text, Vector2(0, 160), 52)
    b.disabled = not enabled
    b.pressed.connect(action)
    parent.add_child(b)
