extends Node
# Entry point. Also the scene Godot reloads when the story/RPG scene hands control back to the app.

# true  = "Tap to start" on every app launch
# false = "Tap to start" only when nobody is logged in
const TAP_TO_START_EVERY_LAUNCH := true

func _ready() -> void:
	var logged_in := GameState.restore_session()   # auto-login with the last account used
	var first := "title"
	if SceneRouter.skip_title:
		SceneRouter.skip_title = false
		first = GameState.next_screen()
	elif logged_in and not TAP_TO_START_EVERY_LAUNCH:
		first = GameState.next_screen()
	SceneRouter.go.call_deferred(first)
