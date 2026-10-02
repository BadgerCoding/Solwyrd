# PB Quiz RPG (Godot 4.x, GDScript, Android)

Open this folder in Godot (Project Manager > Import > project.godot) and press Play.

## Try it without a phone or API key
1. Tap to start, choose "Play as guest", pick a name and avatar.
2. Create your own > Upload > "Load sample quiz (no AI, for testing)".
3. Pick a difficulty > Start battle. (The window flips between portrait and landscape.)

## Turn on AI quiz generation
Setting > AI: paste a Gemini API key (free key from Google AI Studio) and check the model name.
The key is stored on the device: fine for testing, not safe for a public release.

## Connect your real Story Mode RPG
scripts/screens/story_flow.gd > _start_story(): replace the placeholder line with
`SceneRouter.launch_scene("res://story/your_scene.tscn")`. Call `SceneRouter.return_to_app()` to come back.

## Android notes
- Export needs the Android SDK, JDK and export templates; enable the INTERNET permission in the export preset.
- File picker: test "Choose file" on a real phone. If the picked path cannot be opened, add a file-picker plugin
  and call QuizService.generate_from_file() with the path it returns.
- Photo capture ("Take photo") is not implemented: it needs a camera plugin.
- Balance numbers (damage, HP, timers, XP) live in scripts/game_state.gd.

## Accounts
Tap to start > Guest / Login / Register > Customize profile > Home. Accounts are local to the phone for now
(see the note at the top of scripts/game_state.gd). Each account has its own profile, saves and documents.

## Where the art goes
- App background (all screens): `assets/backgrounds/app_background.jpg`. Replace the file to change it.
- Story Mode menu wallpaper (wizard): `assets/wizard_wallpaper.png`
- Avatars: `assets/avatars/avatar_0.png` ... `avatar_7.png`; battle sprites: `assets/player.png`, `assets/wizard.png`
- Pixel font: `assets/fonts/pixel.ttf`

## Look and feel
The whole UI is themed from `scripts/app_theme.gd` (palette + button/panel/bar styles, applied once in SceneRouter).
Pixel font: copy a free pixel .ttf to `assets/fonts/pixel.ttf`. In Godot's Import dock select it and set
Antialiasing = None, Hinting = None, Subpixel Positioning = Disabled, then click Reimport.
