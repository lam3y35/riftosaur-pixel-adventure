import re

def update_hud_tscn():
    with open("scenes/ui/hud.tscn", "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Add ModePracticeBtn to ModeHBox
    practice_btn = """[node name="ModePracticeBtn" type="Button" parent="StartMenu/Panel/VBox/ModeHBox"]
layout_mode = 2
text = "🎯 PRACTICE"
"""
    if "ModePracticeBtn" not in content:
        content = content.replace('[node name="ModeFreestyleBtn" type="Button" parent="StartMenu/Panel/VBox/ModeHBox"]\nlayout_mode = 2\ntext = "🌀 FREESTYLE"\n',
                                '[node name="ModeFreestyleBtn" type="Button" parent="StartMenu/Panel/VBox/ModeHBox"]\nlayout_mode = 2\ntext = "🌀 FREESTYLE"\n\n' + practice_btn)

    # 2. Add ExtraMenuHBox after ShopQuestsHBox
    extra_menu = """[node name="ExtraMenuHBox" type="HBoxContainer" parent="StartMenu/Panel/VBox"]
layout_mode = 2
theme_override_constants/separation = 6
alignment = 1

[node name="StartSettingsBtn" type="Button" parent="StartMenu/Panel/VBox/ExtraMenuHBox"]
layout_mode = 2
size_flags_horizontal = 3
text = "⚙ SETTINGS"

[node name="StartTutorialBtn" type="Button" parent="StartMenu/Panel/VBox/ExtraMenuHBox"]
layout_mode = 2
size_flags_horizontal = 3
text = "🎓 TUTORIAL"

[node name="StartCreditsBtn" type="Button" parent="StartMenu/Panel/VBox/ExtraMenuHBox"]
layout_mode = 2
size_flags_horizontal = 3
text = "📜 CREDITS"
"""
    if "ExtraMenuHBox" not in content:
        content = content.replace('[node name="PlayButton" type="Button" parent="StartMenu/Panel/VBox"]',
                                extra_menu + '\n[node name="PlayButton" type="Button" parent="StartMenu/Panel/VBox"]')

    # 3. Add PauseSettingsBtn to PauseMenu/Panel/VBox
    pause_settings = """[node name="PauseSettingsBtn" type="Button" parent="PauseMenu/Panel/VBox"]
layout_mode = 2
text = "⚙ SETTINGS"
"""
    if "PauseSettingsBtn" not in content:
        content = content.replace('[node name="PauseMenuButton" type="Button" parent="PauseMenu/Panel/VBox"]',
                                pause_settings + '\n[node name="PauseMenuButton" type="Button" parent="PauseMenu/Panel/VBox"]')

    # 4. Add Dialogs & DevOverlay at the end before WorldTransitionCard or after
    new_dialogs = """
[node name="SettingsDialog" type="Control" parent="."]
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="DimOverlay" type="ColorRect" parent="SettingsDialog"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.02, 0.04, 0.1, 0.88)

[node name="Panel" type="PanelContainer" parent="SettingsDialog"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -170.0
offset_top = -120.0
offset_right = 170.0
offset_bottom = 120.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBox" type="VBoxContainer" parent="SettingsDialog/Panel"]
layout_mode = 2
theme_override_constants/separation = 4

[node name="HeaderHBox" type="HBoxContainer" parent="SettingsDialog/Panel/VBox"]
layout_mode = 2

[node name="Title" type="Label" parent="SettingsDialog/Panel/VBox/HeaderHBox"]
layout_mode = 2
size_flags_horizontal = 3
text = "⚙ GAME SETTINGS"
label_settings = SubResource("LabelSettings_title")

[node name="SettingsCloseBtn" type="Button" parent="SettingsDialog/Panel/VBox/HeaderHBox"]
layout_mode = 2
text = "✕ CLOSE"

[node name="SoundToggleBtn" type="Button" parent="SettingsDialog/Panel/VBox"]
layout_mode = 2
text = "🔊 SOUND EFFECTS: ON"

[node name="VibrationToggleBtn" type="Button" parent="SettingsDialog/Panel/VBox"]
layout_mode = 2
text = "📳 HAPTIC VIBRATION: ON"

[node name="MotionToggleBtn" type="Button" parent="SettingsDialog/Panel/VBox"]
layout_mode = 2
text = "🌀 REDUCE MOTION: OFF"

[node name="ContrastToggleBtn" type="Button" parent="SettingsDialog/Panel/VBox"]
layout_mode = 2
text = "👁 HIGH CONTRAST: OFF"

[node name="HandedToggleBtn" type="Button" parent="SettingsDialog/Panel/VBox"]
layout_mode = 2
text = "🖐 CONTROL LAYOUT: RIGHT-HANDED"

[node name="AutoHoldToggleBtn" type="Button" parent="SettingsDialog/Panel/VBox"]
layout_mode = 2
text = "🦘 AUTO-HOLD JUMP: OFF"

[node name="CreditsDialog" type="Control" parent="."]
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="DimOverlay" type="ColorRect" parent="CreditsDialog"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.02, 0.04, 0.1, 0.88)

[node name="Panel" type="PanelContainer" parent="CreditsDialog"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -170.0
offset_top = -105.0
offset_right = 170.0
offset_bottom = 105.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBox" type="VBoxContainer" parent="CreditsDialog/Panel"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="HeaderHBox" type="HBoxContainer" parent="CreditsDialog/Panel/VBox"]
layout_mode = 2

[node name="Title" type="Label" parent="CreditsDialog/Panel/VBox/HeaderHBox"]
layout_mode = 2
size_flags_horizontal = 3
text = "📜 CREDITS & LICENSES"
label_settings = SubResource("LabelSettings_title")

[node name="CreditsCloseBtn" type="Button" parent="CreditsDialog/Panel/VBox/HeaderHBox"]
layout_mode = 2
text = "✕ CLOSE"

[node name="CreditsText" type="Label" parent="CreditsDialog/Panel/VBox"]
layout_mode = 2
text = "RIFTOSAUR • Endless Prehistoric Action\\nEngine: Godot Engine v4.7.2 (MIT License)\\nAudio: Synthesized 16-bit PCM Audio\\nArt: Hand-Crafted Procedural Pixel Engine\\nDeveloped with Google DeepMind Agentic Coding"
label_settings = SubResource("LabelSettings_hud")
horizontal_alignment = 1

[node name="TutorialDialog" type="Control" parent="."]
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="DimOverlay" type="ColorRect" parent="TutorialDialog"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.02, 0.04, 0.1, 0.88)

[node name="Panel" type="PanelContainer" parent="TutorialDialog"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -170.0
offset_top = -105.0
offset_right = 170.0
offset_bottom = 105.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBox" type="VBoxContainer" parent="TutorialDialog/Panel"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="HeaderHBox" type="HBoxContainer" parent="TutorialDialog/Panel/VBox"]
layout_mode = 2

[node name="TutorialStepLabel" type="Label" parent="TutorialDialog/Panel/VBox/HeaderHBox"]
layout_mode = 2
size_flags_horizontal = 3
text = "🎓 STEP 1/5: RUNNING"
label_settings = SubResource("LabelSettings_title")

[node name="TutorialCloseBtn" type="Button" parent="TutorialDialog/Panel/VBox/HeaderHBox"]
layout_mode = 2
text = "✕ SKIP"

[node name="TutorialDescLabel" type="Label" parent="TutorialDialog/Panel/VBox"]
layout_mode = 2
text = "You auto-run forward across prehistoric biomes. Focus your reflexes on upcoming obstacles!"
label_settings = SubResource("LabelSettings_hud")
autowrap_mode = 2

[node name="TutorialActionHBox" type="HBoxContainer" parent="TutorialDialog/Panel/VBox"]
layout_mode = 2
alignment = 1

[node name="TutorialPrevBtn" type="Button" parent="TutorialDialog/Panel/VBox/TutorialActionHBox"]
layout_mode = 2
text = "◀ PREV"

[node name="TutorialNextBtn" type="Button" parent="TutorialDialog/Panel/VBox/TutorialActionHBox"]
layout_mode = 2
text = "NEXT ▶"

[node name="DevOverlay" type="PanelContainer" parent="."]
offset_left = 6.0
offset_top = 58.0
offset_right = 180.0
offset_bottom = 80.0
mouse_filter = 2

[node name="DevText" type="Label" parent="DevOverlay"]
layout_mode = 2
text = "FPS: 60 | SPD: 280 | RUN"
label_settings = SubResource("LabelSettings_subtitle")
"""
    if "SettingsDialog" not in content:
        content += new_dialogs

    with open("scenes/ui/hud.tscn", "w", encoding="utf-8") as f:
        f.write(content)
    print("Updated scenes/ui/hud.tscn")

if __name__ == "__main__":
    update_hud_tscn()
