extends Control
# List of previously uploaded documents (stored on the phone, playable offline).

func _ready() -> void:
    UI.background(self)
    var v := UI.margin(self, 40)
    v.add_child(UI.label("My Documents", 60))
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    v.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 16)
    scroll.add_child(list)
    var docs := SaveManager.list_documents()
    if docs.is_empty():
        list.add_child(UI.label("No documents yet. Use Upload or Scan first.", 38))
    for doc in docs:
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 12)
        list.add_child(row)
        var b := UI.button("%s  (%d questions)" % [str(doc["title"]), doc["questions"].size()], Vector2(0, 130), 36)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.clip_text = true
        var id: String = doc["id"]
        b.pressed.connect(func(): SceneRouter.go("difficulty", {"doc_id": id}))
        row.add_child(b)
        var del := UI.button("X", Vector2(130, 130), 40)
        del.pressed.connect(_confirm_delete.bind(id))
        row.add_child(del)
    var back := UI.button("Back", Vector2(0, 120), 44)
    back.pressed.connect(SceneRouter.back)
    v.add_child(back)

func _confirm_delete(id: String) -> void:
    UI.dialog(self, "Delete this document and its quiz?", [["Cancel", Callable()], ["Delete", _delete_doc.bind(id)]])

func _delete_doc(id: String) -> void:
    SaveManager.delete_document(id)
    SceneRouter.go("cyo_documents")
