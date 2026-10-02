extends Node
# Screen navigation + orientation switching. Every screen is a script in scripts/screens/.

const SCREENS := ["title", "auth_menu", "login", "register", "profile_setup", "main_menu", "story_flow", "story_placeholder", "cyo_hub", "cyo_documents",
	"cyo_upload", "difficulty", "battle", "results", "online", "settings", "placeholder"]
const LANDSCAPE := ["story_placeholder", "battle"]   # story_flow switches orientation itself
const PARENT := {
	"title": "", "auth_menu": "title", "login": "auth_menu", "register": "auth_menu", "main_menu": "", "profile_setup": "", "story_flow": "main_menu", "story_placeholder": "main_menu",
	"cyo_hub": "main_menu", "cyo_documents": "cyo_hub", "cyo_upload": "cyo_hub", "difficulty": "cyo_documents",
	"battle": "cyo_hub", "results": "cyo_hub", "online": "main_menu", "settings": "main_menu", "placeholder": "main_menu",
}

var current: Control
var current_name := ""
var args: Dictionary = {}
var skip_title := false   # set by return_to_app() so coming back from the RPG skips "Tap to start"
var _landscape := false

func _ready() -> void:
	get_tree().root.theme = AppTheme.build()

func go(screen: String, data: Dictionary = {}) -> void:
	if not SCREENS.has(screen):
		push_error("Unknown screen: %s" % screen)
		return
	args = data
	current_name = screen
	set_landscape(screen in LANDSCAPE)
	if is_instance_valid(current):
		current.queue_free()
	var node := Control.new()
	node.set_script(load("res://scripts/screens/%s.gd" % screen))
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(node)
	current = node

func set_landscape(on: bool) -> void:
	if on == _landscape:
		return
	_landscape = on
	get_tree().root.content_scale_size = Vector2i(1920, 1080) if on else Vector2i(1080, 1920)
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE if on else DisplayServer.SCREEN_PORTRAIT)
	else:
		DisplayServer.window_set_size(Vector2i(960, 540) if on else Vector2i(540, 960))

# Back button / Android back gesture.
func back() -> void:
	if is_instance_valid(current) and current.has_method("on_back"):
		current.on_back()
	else:
		go_parent()

func go_parent() -> void:
	var target: String = args.get("back", PARENT.get(current_name, ""))
	if target == "":
		get_tree().quit()
	else:
		go(target)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()

# ---- Hand-off to your real RPG scenes -------------------------------------------------------
# Story Mode: call SceneRouter.launch_scene("res://story/your_scene.tscn") from story_flow.gd.
# When the story scene wants to return to the app, call SceneRouter.return_to_app().
func launch_scene(path: String) -> void:
	if is_instance_valid(current):
		current.queue_free()
	get_tree().change_scene_to_file(path)

func return_to_app() -> void:
	skip_title = true
	set_landscape(false)
	get_tree().change_scene_to_file("res://boot.tscn")
