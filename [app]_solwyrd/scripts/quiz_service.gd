extends Node
# Turns a document (TXT / DOCX / PDF / image) into a pool of quiz questions using the Gemini API.
# TXT: read directly. DOCX: unzipped + parsed here. PDF and images: sent to Gemini as inline data.

signal quiz_ready(questions: Array)
signal quiz_failed(message: String)

const ENDPOINT := "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"
const POOL_SIZE := 20
const MAX_TEXT_CHARS := 60000
const MAX_INLINE_BYTES := 15 * 1024 * 1024
const MIME := {"pdf": "application/pdf", "png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg", "webp": "image/webp"}

var busy := false
var _http: HTTPRequest
var _body := ""
var _retries := 0

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = 90.0
	add_child(_http)
	_http.request_completed.connect(_on_done)

func generate_from_text(text: String) -> void:
	if text.strip_edges() == "":
		quiz_failed.emit("The document has no readable text.")
		return
	_start([{"text": _prompt()}, {"text": "MATERIAL:\n" + text.left(MAX_TEXT_CHARS)}])

func generate_from_file(path: String) -> void:
	var ext := path.get_extension().to_lower()
	if ext in ["txt", "md"]:
		generate_from_text(FileAccess.get_file_as_string(path))
	elif ext == "docx":
		generate_from_text(_read_docx(path))
	elif MIME.has(ext):
		var bytes := FileAccess.get_file_as_bytes(path)
		if bytes.is_empty():
			quiz_failed.emit("Could not read the file. On Android the picker may return a path the app cannot open.")
			return
		if bytes.size() > MAX_INLINE_BYTES:
			quiz_failed.emit("This file is too large (limit about 15 MB). Try a smaller file or fewer pages.")
			return
		_start([{"text": _prompt()}, {"inline_data": {"mime_type": MIME[ext], "data": Marshalls.raw_to_base64(bytes)}}])
	else:
		quiz_failed.emit("Unsupported file type: .%s" % ext)

func _read_docx(path: String) -> String:
	var zip := ZIPReader.new()
	if zip.open(path) != OK:
		return ""
	var xml_bytes := zip.read_file("word/document.xml")
	zip.close()
	var parser := XMLParser.new()
	if xml_bytes.is_empty() or parser.open_buffer(xml_bytes) != OK:
		return ""
	var out := ""
	var in_text := false
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var n := parser.get_node_name()
				if n == "w:t":
					in_text = true
				elif n == "w:tab":
					out += " "
			XMLParser.NODE_ELEMENT_END:
				var e := parser.get_node_name()
				if e == "w:t":
					in_text = false
				elif e == "w:p":
					out += "\n"
			XMLParser.NODE_TEXT:
				if in_text:
					out += parser.get_node_data()
	return out

func _prompt() -> String:
	return """You are a quiz writer for students. Using ONLY the information in the provided material, write %d quiz questions.
Rules:
- About 60%% multiple choice (type "mcq", exactly 4 choices) and 40%% true/false (type "tf", choices exactly ["True", "False"]).
- answer_index is the 0-based index of the correct choice.
- Do not invent facts that are not in the material. Cover different parts of the material.
- Write in the same language as the material (keep the tf choices as "True" and "False").
- If the material has too little content, write fewer questions instead of making things up.
- Keep every question under 200 characters and add a one-sentence explanation.""" % POOL_SIZE

func _schema() -> Dictionary:
	return {
		"type": "OBJECT",
		"properties": {
			"questions": {
				"type": "ARRAY",
				"items": {
					"type": "OBJECT",
					"properties": {
						"type": {"type": "STRING"},
						"question": {"type": "STRING"},
						"choices": {"type": "ARRAY", "items": {"type": "STRING"}},
						"answer_index": {"type": "INTEGER"},
						"explanation": {"type": "STRING"},
					},
					"required": ["type", "question", "choices", "answer_index", "explanation"],
				},
			},
		},
		"required": ["questions"],
	}

func _start(parts: Array) -> void:
	if busy:
		return
	var key: String = str(GameState.settings.get("api_key", "")).strip_edges()
	if key == "":
		quiz_failed.emit("No Gemini API key set. Add one in Setting > AI.")
		return
	_body = JSON.stringify({
		"contents": [{"parts": parts}],
		"generationConfig": {"responseMimeType": "application/json", "responseSchema": _schema(), "temperature": 0.4},
	})
	_retries = 0
	busy = true
	_send()

func _send() -> void:
	var model: String = str(GameState.settings.get("model", "gemini-2.5-flash-lite")).strip_edges()
	var headers := PackedStringArray(["Content-Type: application/json", "x-goog-api-key: " + str(GameState.settings["api_key"]).strip_edges()])
	var err := _http.request(ENDPOINT % model, headers, HTTPClient.METHOD_POST, _body)
	if err != OK:
		_fail("Could not start the request (error %d)." % err)

func _on_done(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail("No connection or the request failed. Check your internet and try again.")
		return
	if code == 429 or code >= 500:
		if _retries < 2:
			_retries += 1
			await get_tree().create_timer(4.0 * _retries).timeout
			_send()
			return
		_fail("The AI service is busy or rate-limited. Wait a minute and try again.")
		return
	if code != 200:
		_fail("AI request failed (HTTP %d). Check your API key and model name in Setting > AI." % code)
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	var text := ""
	if data is Dictionary and data.has("candidates") and data["candidates"].size() > 0:
		var parts = data["candidates"][0].get("content", {}).get("parts", [])
		for p in parts:
			text += str(p.get("text", ""))
	var questions := _validate(JSON.parse_string(text))
	if questions.is_empty():
		if _retries < 2:
			_retries += 1
			_send()
			return
		_fail("The AI did not return usable questions. Try again, or use a document with more text.")
		return
	busy = false
	quiz_ready.emit(questions)

func _validate(parsed) -> Array:
	var out: Array = []
	if not (parsed is Dictionary) or not parsed.has("questions") or not (parsed["questions"] is Array):
		return out
	for q in parsed["questions"]:
		if not (q is Dictionary):
			continue
		var kind := str(q.get("type", "")).to_lower()
		var question := str(q.get("question", "")).strip_edges()
		var choices = q.get("choices", [])
		if question == "" or not (choices is Array):
			continue
		if kind == "tf" and choices.size() != 2:
			continue
		if kind == "mcq" and choices.size() != 4:
			continue
		if kind != "tf" and kind != "mcq":
			continue
		var idx := int(q.get("answer_index", -1))
		if idx < 0 or idx >= choices.size():
			continue
		out.append({"type": kind, "question": question, "choices": choices, "answer_index": idx, "explanation": str(q.get("explanation", ""))})
	return out

func _fail(message: String) -> void:
	busy = false
	quiz_failed.emit(message)
