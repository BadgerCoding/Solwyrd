extends Node
# Local, offline-first storage under user:// plus the pending-sync queue.

var doc_dir := ""   # set per account by GameState.enter_account()
const SYNC_FILE := "user://sync_queue.json"

func set_doc_dir(path: String) -> void:
	doc_dir = path
	DirAccess.make_dir_recursive_absolute(doc_dir)

func save_json(path: String, data) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write %s (error %d)" % [path, FileAccess.get_open_error()])
		return
	f.store_string(JSON.stringify(data, "  "))

func load_json(path: String, fallback = {}):
	if not FileAccess.file_exists(path):
		return fallback
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed != null else fallback

func delete_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func list_documents() -> Array:
	var out: Array = []
	if doc_dir == "":
		return out
	var dir := DirAccess.open(doc_dir)
	if dir == null:
		return out
	for file_name in dir.get_files():
		if file_name.ends_with(".json"):
			var doc = load_json("%s/%s" % [doc_dir, file_name], null)
			if doc is Dictionary and doc.has("id") and doc.has("questions"):
				out.append(doc)
	out.sort_custom(func(a, b): return int(a.get("created", 0)) > int(b.get("created", 0)))
	return out

func save_document(doc: Dictionary) -> void:
	save_json("%s/%s.json" % [doc_dir, doc["id"]], doc)

func delete_document(id: String) -> void:
	delete_file("%s/%s.json" % [doc_dir, id])

# Offline-first: every change worth syncing is queued here. SyncService (not built yet)
# will push this queue to the online database when wifi is available, then clear it.
func queue_sync(kind: String, payload: Dictionary) -> void:
	var q = load_json(SYNC_FILE, [])
	if not (q is Array):
		q = []
	q.append({"kind": kind, "account": GameState.account_id, "payload": payload, "time": int(Time.get_unix_time_from_system())})
	save_json(SYNC_FILE, q)
