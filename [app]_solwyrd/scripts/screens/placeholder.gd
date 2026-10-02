extends Control
# Generic "coming soon" page. Pass {"title", "note", "back"} through SceneRouter.go().

func _ready() -> void:
    UI.background(self)
    var v := UI.margin(self, 40)
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_child(UI.label(str(SceneRouter.args.get("title", "Coming soon")), 60))
    v.add_child(UI.label(str(SceneRouter.args.get("note", "")), 36))
    var b := UI.button("Back", Vector2(0, 120), 44)
    b.pressed.connect(SceneRouter.back)
    v.add_child(b)
