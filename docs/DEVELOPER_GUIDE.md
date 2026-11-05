# Riftosaur Developer Guide

This document describes the environment setup, architectural guidelines, testing workflows, and extension mechanisms for developing and extending **Riftosaur**.

---

## 1. Clean Clone & Environment Setup

1. **Prerequisites:**
   - **Godot Engine 4.7.2-stable official** (installed at `C:\Users\Tweety\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe`).
   - Matching official export templates in `%APPDATA%\Godot\export_templates\4.7.2.stable\`.
   - **Python 3.12+** with Pillow (`PIL`) for procedural pixel-art compilation.
   - **Java JDK 17** (for subsequent Android export milestones).

2. **First Run & Resource Scan:**
   Run Godot headless once to compile `.godot/` cache and global class definitions:
   ```powershell
   & "C:\Users\Tweety\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --editor --quit
   ```

---

## 2. Validation & Test Execution

- **L1 Static Validation:**
  Validates project settings, viewport dimensions (480×270), renderer (`gl_compatibility`), nearest-neighbor filters, input actions (`jump`, `slide`, `skill`, `pause`), and scene references:
  ```powershell
  & "C:\Users\Tweety\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script tools/validate_l1.gd
  ```

- **L2 Automated Unit & Physics Tests:**
  Runs the custom SceneTree-based test suite covering project contracts, input replays, jump physics, variable hold height, buffer/coyote timing, slide collision shrinking, dive descent, and hazard hits:
  ```powershell
  & "C:\Users\Tweety\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script tests/test_runner.gd
  ```

- **PowerShell Wrapper:**
  ```powershell
  powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1
  ```

- **L3 2-Minute Desktop Playtest:**
  Runs 120 seconds of automated flat track gameplay, recording metrics to `docs/evidence/desktop_run_2min.log`:
  ```powershell
  & "C:\Users\Tweety\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script tools/run_desktop_playtest.gd
  ```

---

## 3. Project Conventions

- **Viewport & Scaling:** Logical resolution is strictly 480 × 270. Pixel snapping is enabled for transforms and vertices. Nearest-neighbor filtering (`default_texture_filter=0`) must be preserved.
- **Physics Tick:** All motion calculations run strictly in `_physics_process(delta)`. Never tie movement velocity or timer windows to `_process` frame rates.
- **Configuration Contract:** Physics constants (gravity, jump impulse, coyote window, buffer window, speeds) must never be hardcoded in scripts. Store and edit them in `resources/gameplay_config/gameplay_config.tres` via `GameplayConfig`.
- **Typing:** Use explicit GDScript static types (`var speed: float = 0.0`, `func jump() -> void:`) to detect misalignments during static analysis.

---

## 4. Step-by-Step Extension Instructions

### Adding a New Obstacle
1. Create a scene inheriting `Area2D` under `scenes/obstacles/` (e.g. `obstacle_boulder.tscn`).
2. Attach `scripts/obstacles/hazard.gd` (or extend it for special behaviors).
3. Set `collision_layer = 4` (Hazard layer) and `collision_mask = 1` (Player layer).
4. Add a `Sprite2D` using pixel art from `assets/sprites/` and a `CollisionShape2D` tightly bounding the threat.
5. In your obstacle pattern or track generator, instantiate the scene with reaction spacing $\ge 1.0\text{ s}$ ($> 300\text{ px}$ at opening speed).

### Adding a New Skill (Architecture Foundation)
1. Define a data resource under `resources/skills/` extending `SkillData`.
2. Define skill attributes: name, icon, duration, cooldown, charges.
3. Connect the skill activation to the `skill` input action.
