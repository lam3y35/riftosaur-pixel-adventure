import re

def update_hud_gd():
    with open("scripts/ui/hud.gd", "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Update _ready() connections
    old_ready_block = """	start_shop_btn.pressed.connect(open_skin_shop)
	game_over_shop_btn.pressed.connect(open_skin_shop)
	shop_close_btn.pressed.connect(close_skin_shop)

	start_quests_btn.pressed.connect(open_challenges)
	game_over_quests_btn.pressed.connect(open_challenges)
	quests_close_btn.pressed.connect(close_challenges)
	quests_bottom_close_btn.pressed.connect(close_challenges)"""

    new_ready_block = """	start_shop_btn.pressed.connect(open_skin_shop)
	game_over_shop_btn.pressed.connect(open_skin_shop)
	shop_close_btn.pressed.connect(close_skin_shop)

	start_quests_btn.pressed.connect(open_challenges)
	game_over_quests_btn.pressed.connect(open_challenges)
	quests_close_btn.pressed.connect(close_challenges)
	quests_bottom_close_btn.pressed.connect(close_challenges)

	if mode_practice_btn:
		mode_practice_btn.pressed.connect(func(): select_mode(3))

	if start_settings_btn:
		start_settings_btn.pressed.connect(func(): open_settings("start"))
	if pause_settings_btn:
		pause_settings_btn.pressed.connect(func(): open_settings("pause"))
	if settings_close_btn:
		settings_close_btn.pressed.connect(close_settings)

	if sound_toggle_btn:
		sound_toggle_btn.pressed.connect(_on_sound_toggle_pressed)
	if vibration_toggle_btn:
		vibration_toggle_btn.pressed.connect(_on_vibration_toggle_pressed)
	if motion_toggle_btn:
		motion_toggle_btn.pressed.connect(_on_motion_toggle_pressed)
	if contrast_toggle_btn:
		contrast_toggle_btn.pressed.connect(_on_contrast_toggle_pressed)
	if handed_toggle_btn:
		handed_toggle_btn.pressed.connect(_on_handed_toggle_pressed)
	if auto_hold_toggle_btn:
		auto_hold_toggle_btn.pressed.connect(_on_auto_hold_toggle_pressed)

	if start_credits_btn:
		start_credits_btn.pressed.connect(open_credits)
	if credits_close_btn:
		credits_close_btn.pressed.connect(close_credits)

	if start_tutorial_btn:
		start_tutorial_btn.pressed.connect(open_tutorial)
	if tutorial_close_btn:
		tutorial_close_btn.pressed.connect(close_tutorial)
	if tutorial_prev_btn:
		tutorial_prev_btn.pressed.connect(_on_tutorial_prev_pressed)
	if tutorial_next_btn:
		tutorial_next_btn.pressed.connect(_on_tutorial_next_pressed)"""

    content = content.replace(old_ready_block, new_ready_block)

    # 2. Add dialog hiding in show_start_menu, hide_start_menu, etc.
    content = content.replace('skin_shop_dialog.visible = false\n\tchallenges_dialog.visible = false',
                            'skin_shop_dialog.visible = false\n\tchallenges_dialog.visible = false\n\tif settings_dialog: settings_dialog.visible = false\n\tif credits_dialog: credits_dialog.visible = false\n\tif tutorial_dialog: tutorial_dialog.visible = false')

    # 3. Add mode 3 handling in select_mode()
    old_select_mode = """	_style_arcade_button(mode_casual_btn, active_bg if mode == 0 else idle_bg, active_border if mode == 0 else idle_border, 9)
	_style_arcade_button(mode_runner_btn, active_bg if mode == 1 else idle_bg, active_border if mode == 1 else idle_border, 9)
	_style_arcade_button(mode_freestyle_btn, active_bg if mode == 2 else idle_bg, active_border if mode == 2 else idle_border, 9)"""

    new_select_mode = """	_style_arcade_button(mode_casual_btn, active_bg if mode == 0 else idle_bg, active_border if mode == 0 else idle_border, 9)
	_style_arcade_button(mode_runner_btn, active_bg if mode == 1 else idle_bg, active_border if mode == 1 else idle_border, 9)
	_style_arcade_button(mode_freestyle_btn, active_bg if mode == 2 else idle_bg, active_border if mode == 2 else idle_border, 9)
	if mode_practice_btn:
		_style_arcade_button(mode_practice_btn, active_bg if mode == 3 else idle_bg, active_border if mode == 3 else idle_border, 9)"""

    content = content.replace(old_select_mode, new_select_mode)

    old_match_mode = """		2: # Freestyle
			mode_desc_label.text = "🌀 Steer Left/Right • Air Control • Master Precision"
			steer_left_btn.visible = true
			steer_right_btn.visible = true
			slide_button.visible = true
			slide_button.offset_left = 130.0
			slide_button.offset_right = 198.0
			slide_button.text = "▼ DUCK" """

    new_match_mode = """		2: # Freestyle
			mode_desc_label.text = "🌀 Steer Left/Right • Air Control • Master Precision"
			steer_left_btn.visible = true
			steer_right_btn.visible = true
			slide_button.visible = true
			slide_button.offset_left = 130.0
			slide_button.offset_right = 198.0
			slide_button.text = "▼ DUCK"
		3: # Practice Mode
			mode_desc_label.text = "🎯 Practice Mode • 70% Speed • Free Hit Shield • Safe Learning"
			slide_button.visible = true
			slide_button.offset_left = 14.0
			slide_button.offset_right = 96.0
			slide_button.text = "▼ SLIDE"
			steer_left_btn.visible = false
			steer_right_btn.visible = false"""

    content = content.replace(old_match_mode, new_match_mode)

    # 4. Append Settings, Credits, Tutorial, and DevOverlay methods
    additional_methods = """
# ==========================================
# Session 9: Settings, Accessibility, Credits & Tutorial
# ==========================================

const TUTORIAL_STEPS: Array[Dictionary] = [
	{
		"title": "🎓 STEP 1/5: RUNNING",
		"desc": "You auto-run forward across ancient biomes. Focus your reflexes on upcoming terrain and speed surges!"
	},
	{
		"title": "🎓 STEP 2/5: JUMPING",
		"desc": "Tap to short-hop over low hurdles. Hold jump to vault higher over elevated platforms!"
	},
	{
		"title": "🎓 STEP 3/5: SLIDING & DIVING",
		"desc": "Tap or swipe down on the left to slide under stone arches and avoid flying hazards. In mid-air, swipe down to dive!"
	},
	{
		"title": "🎓 STEP 4/5: SKILLS & RELICS",
		"desc": "Collect glowing orbs to acquire Bone Blade, Boomerang, Stone Shield, Magnet Relic, or Flight!"
	},
	{
		"title": "🎓 STEP 5/5: POWERS & FLIGHT",
		"desc": "Tap the large SKILL button on the right to unleash your active power. Use flight controls to glide through the skies!"
	}
]

func open_settings(from_menu: String = "start") -> void:
	prev_menu_before_settings = from_menu
	if settings_dialog:
		settings_dialog.visible = true
		refresh_settings_ui()

func close_settings() -> void:
	if settings_dialog:
		settings_dialog.visible = false

func refresh_settings_ui() -> void:
	if save_service == null:
		return
	var sound = save_service.get_setting("sound_enabled", true)
	var vib = save_service.get_setting("vibration_enabled", true)
	var motion = save_service.get_setting("reduce_motion", false)
	var contrast = save_service.get_setting("high_contrast", false)
	var handed = save_service.get_setting("left_handed", false)
	var auto_jump = save_service.get_setting("auto_hold_jump", false)

	if sound_toggle_btn:
		sound_toggle_btn.text = "🔊 SOUND EFFECTS: " + ("ON" if sound else "OFF")
	if vibration_toggle_btn:
		vibration_toggle_btn.text = "📳 HAPTIC VIBRATION: " + ("ON" if vib else "OFF")
	if motion_toggle_btn:
		motion_toggle_btn.text = "🌀 REDUCE MOTION: " + ("ON" if motion else "OFF")
	if contrast_toggle_btn:
		contrast_toggle_btn.text = "👁 HIGH CONTRAST: " + ("ON" if contrast else "OFF")
	if handed_toggle_btn:
		handed_toggle_btn.text = "🖐 CONTROL LAYOUT: " + ("LEFT-HANDED" if handed else "RIGHT-HANDED")
	if auto_hold_toggle_btn:
		auto_hold_toggle_btn.text = "🦘 AUTO-HOLD JUMP: " + ("ON" if auto_jump else "OFF")

func _on_sound_toggle_pressed() -> void:
	if save_service:
		var cur = save_service.get_setting("sound_enabled", true)
		save_service.set_setting("sound_enabled", not cur)
		refresh_settings_ui()

func _on_vibration_toggle_pressed() -> void:
	if save_service:
		var cur = save_service.get_setting("vibration_enabled", true)
		save_service.set_setting("vibration_enabled", not cur)
		refresh_settings_ui()

func _on_motion_toggle_pressed() -> void:
	if save_service:
		var cur = save_service.get_setting("reduce_motion", false)
		save_service.set_setting("reduce_motion", not cur)
		refresh_settings_ui()

func _on_contrast_toggle_pressed() -> void:
	if save_service:
		var cur = save_service.get_setting("high_contrast", false)
		save_service.set_setting("high_contrast", not cur)
		refresh_settings_ui()

func _on_handed_toggle_pressed() -> void:
	if save_service:
		var cur = save_service.get_setting("left_handed", false)
		save_service.set_setting("left_handed", not cur)
		refresh_settings_ui()
		apply_control_layout(not cur)

func _on_auto_hold_toggle_pressed() -> void:
	if save_service:
		var cur = save_service.get_setting("auto_hold_jump", false)
		save_service.set_setting("auto_hold_jump", not cur)
		refresh_settings_ui()

func apply_control_layout(is_left_handed: bool) -> void:
	if not touch_controls:
		return
	if is_left_handed:
		jump_button.anchor_left = 0.0
		jump_button.anchor_right = 0.0
		jump_button.offset_left = 14.0
		jump_button.offset_right = 160.0

		slide_button.anchor_left = 1.0
		slide_button.anchor_right = 1.0
		slide_button.offset_left = -160.0
		slide_button.offset_right = -14.0
	else:
		jump_button.anchor_left = 1.0
		jump_button.anchor_right = 1.0
		jump_button.offset_left = -160.0
		jump_button.offset_right = -14.0

		slide_button.anchor_left = 0.0
		slide_button.anchor_right = 0.0
		slide_button.offset_left = 14.0
		slide_button.offset_right = 96.0

func open_credits() -> void:
	if credits_dialog:
		credits_dialog.visible = true

func close_credits() -> void:
	if credits_dialog:
		credits_dialog.visible = false

func open_tutorial() -> void:
	tutorial_step = 0
	if tutorial_dialog:
		tutorial_dialog.visible = true
		_display_tutorial_step(0)

func close_tutorial() -> void:
	if tutorial_dialog:
		tutorial_dialog.visible = false

func _display_tutorial_step(step: int) -> void:
	tutorial_step = clampi(step, 0, TUTORIAL_STEPS.size() - 1)
	var info = TUTORIAL_STEPS[tutorial_step]
	if tutorial_step_label:
		tutorial_step_label.text = info["title"]
	if tutorial_desc_label:
		tutorial_desc_label.text = info["desc"]
	if tutorial_prev_btn:
		tutorial_prev_btn.visible = (tutorial_step > 0)
	if tutorial_next_btn:
		tutorial_next_btn.text = "FINISH ✔" if (tutorial_step == TUTORIAL_STEPS.size() - 1) else "NEXT ▶"

func _on_tutorial_prev_pressed() -> void:
	if tutorial_step > 0:
		_display_tutorial_step(tutorial_step - 1)

func _on_tutorial_next_pressed() -> void:
	if tutorial_step < TUTORIAL_STEPS.size() - 1:
		_display_tutorial_step(tutorial_step + 1)
	else:
		close_tutorial()

func update_dev_overlay(fps: int, speed: float, state_name: String, seed_val: int) -> void:
	if dev_text:
		dev_text.text = "FPS: %d | SPD: %.0f | %s | 🎲 %d" % [fps, speed, state_name, seed_val]
"""

    if "TUTORIAL_STEPS" not in content:
        content += additional_methods

    with open("scripts/ui/hud.gd", "w", encoding="utf-8") as f:
        f.write(content)
    print("Updated scripts/ui/hud.gd")

if __name__ == "__main__":
    update_hud_gd()
