# Changelog

All notable changes to the Riftosaur project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.3.0] - 2026-11-05 (Milestone M2: Session 3)

### Added
- Endless runner core gameplay loop (`scenes/gameplay/endless_runner.tscn`, `scripts/gameplay/endless_runner.gd`).
- 5 modular hand-authored ground chunks (480px width each) with low hurdles, overhangs, double hurdles, and jump-and-slide sequences (`scenes/obstacles/chunks/chunk_01` to `chunk_05`).
- Chunk base controller `scripts/world/ground_chunk.gd` and generator `tools/build_chunks.py`.
- Dynamic chunk spawning ahead of camera and automated cleanup of recycled chunks behind camera.
- HUD system (`scenes/ui/hud.tscn`, `scripts/ui/hud.gd`) featuring distance tracking, real-time score, all-time best score display, and pause overlay.
- Game Over screen with cause-of-death display, final distance, final score, and instant retry (<1s) mechanism.
- Touch controls: full-height right-side tap-and-hold jump zone and left-side downward swipe gesture detection for slide/dive. Minimum 48 dp touch targets.
- Versioned atomic save system (`scripts/systems/save_service.gd`) with schema v1, temporary-file write staging, automatic backup, and corrupted save recovery.
- Automated tests for save system (`tests/unit/test_save_service.gd`) and endless runner loop (`tests/unit/test_endless_runner.gd`), bringing test suite to 22 passing tests.
- High-res original pixel-art Android app launcher icons in 48px, 72px, 96px, 144px, 192px, and 512px resolutions (`tools/generate_icon.py`, `assets/icons/android/`).
- Android export preset configured with ETC2/ASTC compression, landscape orientation, package `com.riftosaur.game`, arm64-v8a and x86_64 binaries.
- Automated APK verification script `tools/verify_apk.ps1` inspecting aapt2 badging, zipalign, apksigner, and inner assets (L4).
- First signed debug APK release artifact: `releases/Riftosaur-debug.apk` (54.6 MB, SHA-256 verified).
- Arabic user guides: `START_HERE_AR.md`, `docs/ANDROID_INSTALL_GUIDE_AR.md`, and `docs/ANDROID_BUILD_GUIDE_AR.md`.

---

## [0.2.0] - 2026-11-05 (Milestone M1: Session 2)

### Added
- Original 32×32 pixel-art dinosaur sprite sheet (`assets/sprites/dinosaur_sheet.png`) with 27 frames (idle, 6-frame run, rise, apex, fall, land squash, slide, dive, hurt, 6-frame death).
- Text source maps in `assets/sources/dinosaur_sourcemap.txt` and compilation tool `tools/generate_sprites.py`.
- 1× and 3× solid black silhouette verification in `tools/verify_silhouette.py` and `docs/evidence/`.
- Central gameplay tuning resource `resources/gameplay_config/gameplay_config.tres` and `scripts/resources/gameplay_config.gd`.
- Player state machine `scripts/player/player_state_machine.gd` with 14 discrete states.
- Responsive movement system `scripts/player/player.gd` featuring variable jump, coyote timing (0.11s), jump buffering (0.12s), sliding collision shrink, dive descent, and landing dust puff.
- Pixel-snapped horizontal camera `scripts/world/game_camera.gd` positioning dinosaur in the left third of the 480×270 viewport.
- Flat test track `scenes/gameplay/flat_test_track.tscn` with dynamic chunk pooling and test hazards.
- 8 automated physics movement unit tests in `tests/unit/test_movement.gd` (total 14 passing automated tests).
- 2-minute autonomous desktop playtest runner `tools/run_desktop_playtest.gd` with evidence log in `docs/evidence/desktop_run_2min.log`.
- `docs/DEVELOPER_GUIDE.md`, `docs/ARCHITECTURE.md`, and `docs/ASSET_LICENSES.md`.

---

## [0.1.0] - 2026-11-05 (Milestone M0: Session 1)

### Added
- Pinned Godot Engine 4.7.2-stable official and matching export templates.
- Project skeleton with standard directories (`scenes/`, `scripts/`, `assets/`, `resources/`, `tests/`, `docs/`, `tools/`).
- Configured 480×270 logical viewport with nearest-neighbor texture filtering and 2D pixel snapping in `project.godot`.
- Input action mappings for `jump`, `slide`, `skill`, and `pause`.
- Headless test runner (`tests/test_runner.gd`) and initial smoke test suite (`tests/unit/test_smoke.gd`).
- L1 static project validation script (`tools/validate_l1.gd`).
- Foundation for timestamped input recording and replay (`scripts/systems/input_replay.gd`) with test verification (`tests/unit/test_replay.gd`).
- Automated PowerShell runner (`tools/run_tests.ps1`).
- Initial preflight survey and session tracking in `docs/WORKLOG.md`.
