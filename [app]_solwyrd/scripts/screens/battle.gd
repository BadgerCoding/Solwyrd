extends Control
# Landscape, Pokemon-style quiz battle: you vs the wizard. No exploration.
# Layout is anchor-based (see _place calls) so you can move things around easily.

const TIMER_STARTS_ON_FIGHT := true   # false = the timer starts as soon as the question appears
const WIZARD := {
    "easy": {"intro": "Welcome, young scholar. I'll go easy on you.", "correct": ["Well done! Now for the next question.", "Nicely answered. Let's go on."], "wrong": ["Not quite. Don't worry, I'm going easy on you."], "win": "You bested me... you learn fast.", "lose": "Even going easy, I won this round. Study and return!"},
    "normal": {"intro": "Let us see what you have learned.", "correct": ["Well done! Now for the next question.", "Correct. But can you keep it up?"], "wrong": ["Wrong! My spell finds its mark."], "win": "Impressive. You have defeated me.", "lose": "Defeated! Study harder and challenge me again."},
    "hard": {"intro": "No mercy this time. I'm going all out!", "correct": ["Hmph. Lucky. Next question!", "Correct... but I'm just getting started."], "wrong": ["Ha! Wrong! Feel my full power!"], "win": "Impossible... you defeated me at full strength!", "lose": "Too weak! Come back when you are ready."},
}

var _s: Dictionary
var _d: Dictionary
var _state := "intro"
var _time_left := 0.0
var _timing := false
var _question_label: Label
var _timer_label: Label
var _say_label: Label
var _answers: VBoxContainer
var _enemy_bar: ProgressBar
var _enemy_text: Label
var _player_bar: ProgressBar
var _player_text: Label
var _xp_bar: ProgressBar
var _menu: GridContainer
var _player_sprite: Control
var _wizard_sprite: Control

func _ready() -> void:
    if SceneRouter.args.get("resume", false):
        _s = _normalize(SaveManager.load_json(GameState.cyo_save_file, {}))
    else:
        _s = SceneRouter.args.get("session", {})
    if _s.is_empty() or not _s.has("questions"):
        SceneRouter.go("cyo_hub")
        return
    _d = GameState.DIFFICULTIES[_s["difficulty"]]
    _build_ui()
    _update_hud()
    _say(_line("intro"))
    await get_tree().create_timer(1.6).timeout
    if is_inside_tree():
        _next_question()

func _normalize(s: Dictionary) -> Dictionary:
    for k in ["index", "player_hp", "player_max_hp", "enemy_hp", "enemy_max_hp", "correct", "timer_seconds"]:
        if s.has(k):
            s[k] = int(s[k])
    if s.has("questions"):
        for q in s["questions"]:
            q["answer_index"] = int(q["answer_index"])
    return s

func _place(c: Control, l: float, t: float, r: float, b: float) -> void:
    c.anchor_left = l
    c.anchor_top = t
    c.anchor_right = r
    c.anchor_bottom = b
    c.offset_left = 0
    c.offset_top = 0
    c.offset_right = 0
    c.offset_bottom = 0

func _build_ui() -> void:
    UI.background(self)
    var root := UI.margin(self, 20)
    root.add_theme_constant_override("separation", 16)

    # Top bar: question + timer
    var top := HBoxContainer.new()
    top.add_theme_constant_override("separation", 16)
    root.add_child(top)
    var qp := PanelContainer.new()
    qp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(qp)
    _question_label = UI.label("", 40, HORIZONTAL_ALIGNMENT_LEFT)
    qp.add_child(_question_label)
    var tp := PanelContainer.new()
    tp.custom_minimum_size = Vector2(170, 0)
    top.add_child(tp)
    _timer_label = UI.label("--", 56)
    tp.add_child(_timer_label)

    # Battlefield
    var field := Control.new()
    field.size_flags_vertical = Control.SIZE_EXPAND_FILL
    field.clip_contents = true
    root.add_child(field)
    var bg := ColorRect.new()
    bg.color = Color(0.03, 0.12, 0.10, 0.55)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    field.add_child(bg)

    _answers = VBoxContainer.new()   # answer boxes appear on the left after pressing Fight
    _answers.add_theme_constant_override("separation", 14)
    _place(_answers, 0.01, 0.04, 0.42, 0.96)
    _answers.visible = false
    field.add_child(_answers)

    var bubble := PanelContainer.new()
    _place(bubble, 0.44, 0.02, 0.68, 0.36)
    field.add_child(bubble)
    _say_label = UI.label("", 32)
    bubble.add_child(_say_label)

    _player_sprite = UI.sprite("res://assets/player.png", Color("7fb04a"), "YOU")
    _place(_player_sprite, 0.46, 0.40, 0.60, 0.98)
    field.add_child(_player_sprite)

    _wizard_sprite = UI.sprite("res://assets/wizard.png", Color("9b59b6"), "WIZARD")
    _place(_wizard_sprite, 0.76, 0.30, 0.94, 0.90)
    field.add_child(_wizard_sprite)

    var ep := PanelContainer.new()
    _place(ep, 0.70, 0.02, 0.98, 0.26)
    field.add_child(ep)
    var ev := VBoxContainer.new()
    ep.add_child(ev)
    ev.add_child(UI.label("Wizard", 34, HORIZONTAL_ALIGNMENT_LEFT))
    _enemy_bar = UI.bar(Color("c4443a"))
    ev.add_child(_enemy_bar)
    _enemy_text = UI.label("", 28, HORIZONTAL_ALIGNMENT_LEFT)
    ev.add_child(_enemy_text)

    # Bottom: player panel + action menu
    var bottom := HBoxContainer.new()
    bottom.custom_minimum_size = Vector2(0, 250)
    bottom.add_theme_constant_override("separation", 20)
    root.add_child(bottom)
    var pp := PanelContainer.new()
    pp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bottom.add_child(pp)
    var ph := HBoxContainer.new()
    ph.add_theme_constant_override("separation", 20)
    pp.add_child(ph)
    ph.add_child(UI.avatar(int(GameState.profile.get("avatar", 0)), 200))
    var pv := VBoxContainer.new()
    pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    pv.alignment = BoxContainer.ALIGNMENT_CENTER
    ph.add_child(pv)
    pv.add_child(UI.label("%s  Lv.%d" % [str(GameState.profile.get("username", "Player")), GameState.level()], 32, HORIZONTAL_ALIGNMENT_LEFT))
    _player_bar = UI.bar(Color("7fb04a"))
    pv.add_child(_player_bar)
    _player_text = UI.label("", 26, HORIZONTAL_ALIGNMENT_LEFT)
    pv.add_child(_player_text)
    _xp_bar = UI.bar(AppTheme.GOLD)
    pv.add_child(_xp_bar)

    _menu = GridContainer.new()
    _menu.columns = 2
    _menu.add_theme_constant_override("h_separation", 16)
    _menu.add_theme_constant_override("v_separation", 16)
    bottom.add_child(_menu)
    for item in ["Fight", "Bag", "Skills", "Run"]:
        var b := UI.button(item, Vector2(300, 110), 44)
        b.pressed.connect(_on_menu.bind(item))
        _menu.add_child(b)
    _set_menu(false)

func _line(kind: String) -> String:
    var v = WIZARD[_s["difficulty"]][kind]
    if v is Array:
        return str(v[randi() % v.size()])
    return str(v)

func _say(t: String) -> void:
    _say_label.text = t
    _say_label.get_parent().visible = t != ""

func _set_menu(on: bool) -> void:
    for b in _menu.get_children():
        b.disabled = not on

func _update_hud() -> void:
    _enemy_bar.max_value = int(_s["enemy_max_hp"])
    _enemy_bar.value = int(_s["enemy_hp"])
    _enemy_text.text = "HP %d/%d" % [int(_s["enemy_hp"]), int(_s["enemy_max_hp"])]
    _player_bar.max_value = int(_s["player_max_hp"])
    _player_bar.value = int(_s["player_hp"])
    _player_text.text = "HP %d/%d" % [int(_s["player_hp"]), int(_s["player_max_hp"])]
    _xp_bar.max_value = GameState.xp_needed(GameState.level())
    _xp_bar.value = GameState.xp()

func _next_question() -> void:
    _state = "ask"
    var q: Dictionary = _s["questions"][int(_s["index"])]
    _question_label.text = "%d. %s" % [int(_s["index"]) + 1, str(q["question"])]
    _timer_label.text = str(int(_s["timer_seconds"])) if _s["timer_enabled"] else "--"
    _clear_answers()
    _set_menu(true)
    if _s["timer_enabled"] and not TIMER_STARTS_ON_FIGHT:
        _time_left = float(_s["timer_seconds"])
        _timing = true

func _clear_answers() -> void:
    for c in _answers.get_children():
        _answers.remove_child(c)
        c.queue_free()
    _answers.visible = false

func _on_menu(item: String) -> void:
    if _state != "ask":
        return
    match item:
        "Fight":
            _show_answers()
        "Bag":
            _say("Your bag is empty. (Items coming soon)")
        "Skills":
            _say("No skills learned yet. (Coming soon)")
        "Run":
            _confirm_run()

func _confirm_run() -> void:
    UI.dialog(self, "Run away? Your progress is saved. You can continue from Create Your Own.", [["Stay", Callable()], ["Run", _leave]])

func _leave() -> void:
    _timing = false
    SceneRouter.go("cyo_hub")

func on_back() -> void:
    if _state == "ask" or _state == "answering":
        _confirm_run()

func _show_answers() -> void:
    var q: Dictionary = _s["questions"][int(_s["index"])]
    _state = "answering"
    _set_menu(false)
    _say("")
    _clear_answers()
    var letters := ["A", "B", "C", "D"]
    for i in q["choices"].size():
        var txt := str(q["choices"][i])
        if q["type"] == "mcq":
            txt = "%s. %s" % [letters[i], txt]
        var b := UI.button(txt, Vector2(0, 100), 34)
        b.size_flags_vertical = Control.SIZE_EXPAND_FILL
        b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        b.pressed.connect(_answer.bind(i))
        _answers.add_child(b)
    _answers.visible = true
    if _s["timer_enabled"]:
        _time_left = float(_s["timer_seconds"])
        _timing = true

func _process(delta: float) -> void:
    if not _timing:
        return
    _time_left -= delta
    _timer_label.text = str(maxi(0, ceili(_time_left)))
    if _time_left <= 0.0:
        _timing = false
        _answer(-1)

func _answer(idx: int) -> void:
    if _state != "answering":
        return
    _state = "resolve"
    _timing = false
    var q: Dictionary = _s["questions"][int(_s["index"])]
    var ok := idx == int(q["answer_index"])
    _clear_answers()
    if ok:
        _s["correct"] = int(_s["correct"]) + 1
        _s["enemy_hp"] = maxi(0, int(_s["enemy_hp"]) - int(_d["player_dmg"]))
        _say(_line("correct"))
        _flash(_wizard_sprite)
    else:
        _s["player_hp"] = maxi(0, int(_s["player_hp"]) - int(_d["enemy_dmg"]))
        var right := str(q["choices"][int(q["answer_index"])])
        var why := str(q.get("explanation", ""))
        _say("%s\nAnswer: %s\n%s" % [_line("wrong"), right, why])
        _flash(_player_sprite)
    _s["index"] = int(_s["index"]) + 1
    _update_hud()
    SaveManager.save_json(GameState.cyo_save_file, _s)
    await get_tree().create_timer(2.0 if ok else 3.5).timeout
    if not is_inside_tree():
        return
    if int(_s["enemy_hp"]) <= 0:
        _finish(true)
    elif int(_s["player_hp"]) <= 0 or int(_s["index"]) >= _s["questions"].size():
        _finish(false)
    else:
        _next_question()

func _flash(node: CanvasItem) -> void:
    if not bool(GameState.settings.get("animation", true)):
        return
    var t := create_tween()
    t.tween_property(node, "modulate", Color(1, 0.3, 0.3), 0.1)
    t.tween_property(node, "modulate", Color.WHITE, 0.25)

func _finish(won: bool) -> void:
    _state = "done"
    _say(_line("win" if won else "lose"))
    SaveManager.delete_file(GameState.cyo_save_file)
    var correct := int(_s["correct"])
    var xp := correct * int(_d["xp_per_correct"]) + (20 if won else 0)
    var leveled := GameState.add_xp(xp)
    var result := {"won": won, "correct": correct, "total": _s["questions"].size(), "xp": xp, "leveled": leveled, "doc_id": _s["doc_id"]}
    SaveManager.queue_sync("battle_result", result)
    await get_tree().create_timer(2.5).timeout
    if is_inside_tree():
        SceneRouter.go("results", result)
