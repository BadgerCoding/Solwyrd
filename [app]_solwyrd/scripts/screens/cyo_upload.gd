extends Control
# Upload (TXT / DOCX / PDF / image) or Scan (photo of one page of notes) -> AI writes a question pool
# -> stored on the phone -> Difficulty screen.

const SAMPLE_TEXT := "The cell is the basic unit of life. The mitochondria is the powerhouse of the cell because it produces most of the cell's ATP through cellular respiration. The nucleus stores DNA and controls cell activities. Ribosomes make proteins. Plant cells have a cell wall and chloroplasts, which carry out photosynthesis."
const SAMPLE_QUESTIONS := [
    {"type": "mcq", "question": "What is the powerhouse of the cell?", "choices": ["Nucleus", "Mitochondria", "Ribosome", "Chloroplast"], "answer_index": 1, "explanation": "Mitochondria produce most of the cell's ATP."},
    {"type": "tf", "question": "The nucleus stores DNA.", "choices": ["True", "False"], "answer_index": 0, "explanation": "The nucleus holds the cell's DNA."},
    {"type": "mcq", "question": "Which organelle makes proteins?", "choices": ["Ribosome", "Mitochondria", "Cell wall", "Nucleus"], "answer_index": 0, "explanation": "Ribosomes build proteins."},
    {"type": "tf", "question": "Animal cells have chloroplasts.", "choices": ["True", "False"], "answer_index": 1, "explanation": "Chloroplasts are found in plant cells."},
    {"type": "mcq", "question": "What process do chloroplasts carry out?", "choices": ["Respiration", "Photosynthesis", "Digestion", "Replication"], "answer_index": 1, "explanation": "Chloroplasts carry out photosynthesis."},
    {"type": "tf", "question": "Mitochondria produce most of the cell's ATP.", "choices": ["True", "False"], "answer_index": 0, "explanation": "Through cellular respiration."},
]

var _mode := "upload"
var _status: Label
var _paste: TextEdit
var _buttons: Array = []
var _title := "Document"

func _ready() -> void:
    _mode = str(SceneRouter.args.get("mode", "upload"))
    QuizService.quiz_ready.connect(_on_quiz_ready)
    QuizService.quiz_failed.connect(_on_quiz_failed)
    UI.background(self)
    var v := UI.margin(self, 40)
    v.add_child(UI.label("Scan your notes" if _mode == "scan" else "Upload a document", 56))
    v.add_child(UI.label("Take a photo or choose an image of one page of notes." if _mode == "scan" else "TXT, DOCX, PDF or image. The AI reads it and writes your quiz.", 30))
    if _mode == "scan":
        _add(v, "Take photo", func(): UI.alert(self, "Camera capture needs an Android plugin, which is not included yet. Use 'Choose image' for now."))
    _add(v, "Choose image" if _mode == "scan" else "Choose file", _pick_file)
    if _mode == "upload":
        _paste = TextEdit.new()
        _paste.placeholder_text = "...or paste your notes here"
        _paste.custom_minimum_size = Vector2(0, 260)
        _paste.add_theme_font_size_override("font_size", 32)
        v.add_child(_paste)
        _add(v, "Make quiz from pasted text", _from_paste)
    _add(v, "Try sample text (uses AI)", _try_sample_text)
    _add(v, "Load sample quiz (no AI, for testing)", _load_sample)
    _status = UI.label("", 32)
    v.add_child(_status)
    var back := UI.button("Back", Vector2(0, 110), 44)
    back.pressed.connect(SceneRouter.back)
    v.add_child(back)

func _add(parent: Control, text: String, action: Callable) -> void:
    var b := UI.button(text, Vector2(0, 110), 38)
    b.pressed.connect(action)
    parent.add_child(b)
    _buttons.append(b)

func _begin() -> void:
    _status.text = "Reading your document with AI... this can take a little while."
    for b in _buttons:
        b.disabled = true

func _end() -> void:
    for b in _buttons:
        b.disabled = false

func _pick_file() -> void:
    var fd := FileDialog.new()
    fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
    fd.access = FileDialog.ACCESS_FILESYSTEM
    fd.use_native_dialog = true
    if _mode == "scan":
        fd.filters = PackedStringArray(["*.png, *.jpg, *.jpeg, *.webp ; Images"])
    else:
        fd.filters = PackedStringArray(["*.txt, *.docx, *.pdf, *.png, *.jpg, *.jpeg, *.webp ; Documents and images"])
    fd.file_selected.connect(_on_file_picked)
    add_child(fd)
    fd.popup_centered_ratio(0.9)

func _on_file_picked(path: String) -> void:
    _title = path.get_file().get_basename()
    _begin()
    QuizService.generate_from_file(path)

func _from_paste() -> void:
    _title = "Pasted notes"
    _begin()
    QuizService.generate_from_text(_paste.text)

func _try_sample_text() -> void:
    _title = "Sample: cells"
    _begin()
    QuizService.generate_from_text(SAMPLE_TEXT)

func _load_sample() -> void:
    _title = "Sample: cells (offline)"
    _on_quiz_ready(SAMPLE_QUESTIONS.duplicate(true))

func _on_quiz_ready(questions: Array) -> void:
    var doc := {
        "id": "doc_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 10000],
        "title": _title,
        "created": int(Time.get_unix_time_from_system()),
        "questions": questions,
    }
    SaveManager.save_document(doc)
    SaveManager.queue_sync("document", {"id": doc["id"], "title": _title, "count": questions.size()})
    SceneRouter.go("difficulty", {"doc_id": doc["id"]})

func _on_quiz_failed(message: String) -> void:
    _status.text = message
    _end()
