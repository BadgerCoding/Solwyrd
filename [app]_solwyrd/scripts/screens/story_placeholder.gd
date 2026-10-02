extends Control
# Stand-in for your real Story Mode RPG scene.

func _ready() -> void:
    UI.background(self, Color(0.08, 0.12, 0.10))
    var v := UI.margin(self, 40)
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    var new_game: bool = SceneRouter.args.get("new_game", true)
    v.add_child(UI.label("Story Mode (placeholder)", 64))
    v.add_child(UI.label("New game started." if new_game else "Continuing your saved story.", 40))
    v.add_child(UI.label("Your RPG scene will be loaded here.", 34))
    var b := UI.button("Back to menu", Vector2(0, 120), 44)
    b.pressed.connect(func(): SceneRouter.go("main_menu"))
    v.add_child(b)
