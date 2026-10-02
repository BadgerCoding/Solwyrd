extends Control
# Difficulty / challenge selection, then builds the battle session.

var _doc: Dictionary
var _diff := "normal"
var _info: Label
var _count: HSlider
var _count_label: Label
var _mcq: CheckBox
var _tf: CheckBox
var _timer: CheckButton

func _ready() -> void:
    var id := str(SceneRouter.args.get("doc_id", ""))
    _doc = SaveManager.load_json("%s/%s.json" % [SaveManager.doc_dir, id], {})
    if _doc.is_empty():
        SceneRouter.go("cyo_documents")
        return
    UI.background(self)
    var v := UI.margin(self, 40)
    v.add_child(UI.label("Choose your challenge", 56))
    v.add_child(UI.label(str(_doc["title"]), 34))

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 16)
    v.add_child(row)
    var group := ButtonGroup.new()
    for key in ["easy", "normal", "hard"]:
        var b := UI.button(str(GameState.DIFFICULTIES[key]["label"]), Vector2(0, 120), 40)
        b.toggle_mode = true
        b.button_group = group
        b.button_pressed = key == _diff
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(_set_diff.bind(key))
        row.add_child(b)
    _info = UI.label("", 30)
    v.add_child(_info)

    var pool_size: int = _doc["questions"].size()
    _count_label = UI.label("", 36)
    v.add_child(_count_label)
    _count = HSlider.new()
    _count.min_value = mini(5, pool_size)
    _count.max_value = pool_size
    _count.step = 1
    _count.value = mini(10, pool_size)
    _count.custom_minimum_size = Vector2(0, 60)
    _count.value_changed.connect(func(_x): _refresh())
    v.add_child(_count)

    _mcq = CheckBox.new()
    _mcq.text = "Multiple choice"
    _mcq.button_pressed = true
    _mcq.add_theme_font_size_override("font_size", 36)
    v.add_child(_mcq)
    _tf = CheckBox.new()
    _tf.text = "True or false"
    _tf.button_pressed = true
    _tf.add_theme_font_size_override("font_size", 36)
    v.add_child(_tf)
    _timer = CheckButton.new()
    _timer.text = "Question timer"
    _timer.button_pressed = true
    _timer.add_theme_font_size_override("font_size", 36)
    v.add_child(_timer)

    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    v.add_child(spacer)
    var start := UI.button("Start battle", Vector2(0, 140), 52)
    start.pressed.connect(_start)
    v.add_child(start)
    var back := UI.button("Back", Vector2(0, 110), 44)
    back.pressed.connect(SceneRouter.back)
    v.add_child(back)
    _refresh()

func _set_diff(key: String) -> void:
    _diff = key
    _refresh()

func _refresh() -> void:
    var d: Dictionary = GameState.DIFFICULTIES[_diff]
    _info.text = "The wizard hits for %d. You hit for %d. Timer: %d s. You must answer about %d%% correctly." % [int(d["enemy_dmg"]), int(d["player_dmg"]), int(d["timer"]), int(float(d["win_ratio"]) * 100)]
    _count_label.text = "Questions: %d" % int(_count.value)

func _start() -> void:
    var types: Array = []
    if _mcq.button_pressed:
        types.append("mcq")
    if _tf.button_pressed:
        types.append("tf")
    if types.is_empty():
        UI.alert(self, "Pick at least one question type.")
        return
    var pool: Array = []
    for q in _doc["questions"]:
        if q["type"] in types:
            pool.append(q.duplicate(true))
    if pool.is_empty():
        UI.alert(self, "This document has no questions of the selected type(s).")
        return
    pool.shuffle()
    var n := mini(int(_count.value), pool.size())
    var qs: Array = pool.slice(0, n)
    for q in qs:
        q["answer_index"] = int(q["answer_index"])
    var d: Dictionary = GameState.DIFFICULTIES[_diff]
    var hits := ceili(n * float(d["win_ratio"]))
    var enemy_hp := hits * int(d["player_dmg"])
    var session := {
        "doc_id": _doc["id"],
        "difficulty": _diff,
        "questions": qs,
        "index": 0,
        "correct": 0,
        "player_hp": int(d["player_hp"]),
        "player_max_hp": int(d["player_hp"]),
        "enemy_hp": enemy_hp,
        "enemy_max_hp": enemy_hp,
        "timer_enabled": _timer.button_pressed,
        "timer_seconds": int(d["timer"]),
    }
    SaveManager.save_json(GameState.cyo_save_file, session)
    SceneRouter.go("battle", {"session": session})
