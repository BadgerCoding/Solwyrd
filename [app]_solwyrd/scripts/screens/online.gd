extends Control
# Online: screen flow only for now (Host / Join). Real networking comes later.

func _ready() -> void:
    UI.background(self)
    var v := UI.margin(self, 40)
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_child(UI.label("Online", 64))
    _add(v, "Host", "Host a lobby", "Planned: no-timer lobby where you pick the quiz mode (multiple choice, true/false...), one of 10 maps, and the fight mode (2 vs E, 1v1, Tournament 4-8 players).")
    _add(v, "Join", "Find a host", "Planned: list of host lobbies. After joining you can only change your character (8 characters) and tap Ready. When everyone is ready a countdown starts.")
    var b := UI.button("Back", Vector2(0, 120), 44)
    b.pressed.connect(SceneRouter.back)
    v.add_child(b)

func _add(parent: Control, text: String, title: String, note: String) -> void:
    var b := UI.button(text, Vector2(0, 170), 52)
    b.pressed.connect(func(): SceneRouter.go("placeholder", {"title": title, "note": note, "back": "online"}))
    parent.add_child(b)
