extends Node
# Local accounts (stored on this phone), the active profile, settings and balance tables.
# All balance numbers are placeholders: tune freely.
#
# ACCOUNTS ARE LOCAL ONLY for now: usernames and (salted, hashed) passwords live in user://accounts.json,
# so an account only works on the phone where it was registered. Replace register()/login() with calls
# to an online backend later; the rest of the app only uses enter_account(), next_screen() and logout().

const SETTINGS_FILE := "user://settings.json"
const ACCOUNTS_FILE := "user://accounts.json"
const SESSION_FILE := "user://session.json"
const MAX_LEVEL := 100

# Only Shop = level 10 was specified. The others are placeholders set to 1.
const UNLOCK_LEVELS := {"quest": 1, "achievement": 1, "ranking": 1, "shop": 10}

# win_ratio: fraction of the questions you must answer correctly to defeat the wizard.
const DIFFICULTIES := {
	"easy": {"label": "Easy", "player_hp": 100, "player_dmg": 5, "enemy_dmg": 5, "win_ratio": 0.6, "timer": 15, "xp_per_correct": 8},
	"normal": {"label": "Normal", "player_hp": 100, "player_dmg": 5, "enemy_dmg": 10, "win_ratio": 0.75, "timer": 10, "xp_per_correct": 10},
	"hard": {"label": "Hard", "player_hp": 100, "player_dmg": 5, "enemy_dmg": 15, "win_ratio": 0.9, "timer": 8, "xp_per_correct": 14},
}

var account_id := ""        # "" = nobody logged in, "guest" = guest, otherwise the lower-case username
var profile_file := ""
var cyo_save_file := ""
var story_save_file := ""
var profile: Dictionary = {}
var settings: Dictionary = {"animation": true, "sound": true, "api_key": "", "model": "gemini-2.5-flash-lite"}

func _ready() -> void:
	var s = SaveManager.load_json(SETTINGS_FILE, {})
	if s is Dictionary:
		settings.merge(s, true)

# ---- accounts ----------------------------------------------------------------------------------

func _accounts() -> Dictionary:
	var a = SaveManager.load_json(ACCOUNTS_FILE, {})
	return a if a is Dictionary else {}

func _hash(salt: String, password: String) -> String:
	var h := password
	for i in 2000:
		h = (salt + h).sha256_text()
	return h

# Returns "" on success, otherwise a message to show the player.
func register(username: String, password: String) -> String:
	var uname := username.strip_edges()
	var re := RegEx.new()
	re.compile("^[A-Za-z0-9_]{3,16}$")
	if re.search(uname) == null:
		return "Username must be 3-16 letters, numbers or underscores."
	if password.length() < 6:
		return "Password must be at least 6 characters."
	var id := uname.to_lower()
	if id == "guest":
		return "That username is reserved."
	var accounts := _accounts()
	if accounts.has(id):
		return "That username is already taken on this phone."
	var salt := Crypto.new().generate_random_bytes(16).hex_encode()
	accounts[id] = {"username": uname, "salt": salt, "hash": _hash(salt, password), "created": int(Time.get_unix_time_from_system())}
	SaveManager.save_json(ACCOUNTS_FILE, accounts)
	enter_account(id)
	return ""

# Returns "" on success, otherwise a message to show the player.
func login(username: String, password: String) -> String:
	var id := username.strip_edges().to_lower()
	var accounts := _accounts()
	if not accounts.has(id):
		return "Wrong username or password."
	var acc: Dictionary = accounts[id]
	if str(acc.get("hash", "")) != _hash(str(acc.get("salt", "")), password):
		return "Wrong username or password."
	enter_account(id)
	return ""

# Switches to an account: points every save path at its own folder and loads its profile.
func enter_account(id: String) -> void:
	account_id = id
	var dir := "user://accounts/%s" % id
	DirAccess.make_dir_recursive_absolute(dir)
	profile_file = dir + "/profile.json"
	cyo_save_file = dir + "/cyo_save.json"
	story_save_file = dir + "/story_save.json"
	SaveManager.set_doc_dir(dir + "/documents")
	var p = SaveManager.load_json(profile_file, {})
	profile = p if p is Dictionary else {}
	for k in ["level", "xp", "avatar"]:
		if profile.has(k):
			profile[k] = int(profile[k])
	SaveManager.save_json(SESSION_FILE, {"account_id": id})

# Auto-login with the account that was active last time. Returns true if one was restored.
func restore_session() -> bool:
	var sess = SaveManager.load_json(SESSION_FILE, {})
	var id := str(sess.get("account_id", "")) if sess is Dictionary else ""
	if id == "" or (id != "guest" and not _accounts().has(id)):
		return false
	enter_account(id)
	return true

func is_logged_in() -> bool:
	return account_id != ""

# Where to go after an auth step.
func next_screen() -> String:
	if not is_logged_in():
		return "auth_menu"
	return "main_menu" if has_profile() else "profile_setup"

func account_username() -> String:
	if account_id == "guest":
		return "Guest"
	var acc: Dictionary = _accounts().get(account_id, {})
	return str(acc.get("username", account_id))

# Ends the session. Account data stays on the phone, so logging in again brings everything back.
func logout() -> void:
	SaveManager.delete_file(SESSION_FILE)
	account_id = ""
	profile = {}
	profile_file = ""
	cyo_save_file = ""
	story_save_file = ""

# ---- profile / settings ------------------------------------------------------------------------

func has_profile() -> bool:
	return profile.has("username")

func create_profile(username: String, avatar: int) -> void:
	profile = {"username": username, "avatar": avatar, "level": 1, "xp": 0}
	save_profile()

func save_profile() -> void:
	if profile_file == "":
		return
	SaveManager.save_json(profile_file, profile)
	SaveManager.queue_sync("profile", profile)

func save_settings() -> void:
	SaveManager.save_json(SETTINGS_FILE, settings)

func level() -> int:
	return int(profile.get("level", 1))

func xp() -> int:
	return int(profile.get("xp", 0))

func xp_needed(lvl: int) -> int:
	return 50 + lvl * 25

# Returns true if the player levelled up.
func add_xp(amount: int) -> bool:
	var leveled := false
	profile["xp"] = xp() + amount
	while level() < MAX_LEVEL and xp() >= xp_needed(level()):
		profile["xp"] = xp() - xp_needed(level())
		profile["level"] = level() + 1
		leveled = true
	if level() >= MAX_LEVEL:
		profile["xp"] = 0
	save_profile()
	return leveled

func is_unlocked(feature: String) -> bool:
	return level() >= int(UNLOCK_LEVELS.get(feature, 1))
