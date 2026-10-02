extends Control

func _ready() -> void:
    var r: Dictionary = SceneRouter.args
    UI.background(self)
    var v := UI.margin(self, 40)
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_child(UI.label("Victory!" if r.get("won", false) else "Defeated", 72))
    v.add_child(UI.label("Correct answers: %d / %d" % [int(r.get("correct", 0)), int(r.get("total", 0))], 44))
    v.add_child(UI.label("XP earned: +%d" % int(r.get("xp", 0)), 44))
    if r.get("leveled", false):
        v.add_child(UI.label("LEVEL UP! You are now level %d." % GameState.level(), 48))
    if r.has("doc_id"):
        var again := UI.button("Play again", Vector2(0, 140), 48)
        var id := str(r["doc_id"])
        again.pressed.connect(func(): SceneRouter.go("difficulty", {"doc_id": id}))
        v.add_child(again)
    var back := UI.button("Back to Create Your Own", Vector2(0, 120), 44)
    back.pressed.connect(func(): SceneRouter.go("cyo_hub"))
    v.add_child(back)
