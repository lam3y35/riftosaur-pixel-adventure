# Changelog

All notable changes to the Riftosaur project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-11-06 (Milestones M3 - M10: Production Release)

### Added
- **Full Release & Production Signing (M10):**
  - Production release APK (`releases/Riftosaur-release.apk`, 60.07 MB) signed with dedicated release keystore (`riftosaur-release.keystore`).
  - Debug APK (`releases/Riftosaur-debug.apk`, 64.52 MB).
  - Clean source distribution archive `Riftosaur-source-v1.0.0.zip`.
  - Zero-internet permission guarantee (`android.permission.INTERNET: False`) and enabled haptic vibration (`android.permission.VIBRATE: True`).
  - Standard MIT License in `LICENSE` file.
  - Comprehensive troubleshooting guide `docs/TROUBLESHOOTING_AR.md`.
- **Quality Assurance & Optimization (M9):**
  - Full automated QA matrix `tools/verify_session11_qa_matrix.gd` executing 12 end-to-end scenarios (10-minute stability run over 30km, rapid retries, simultaneous touches, flight pause retention, 50 atomic save cycles, corrupted save recovery).
  - Multi-resolution layout verification across 5 aspect ratios (16:9 480x270, 16:9 FHD, 19.5:9, 20:9, 4:3).
  - Benchmarked 301ms startup time, 1.77ms immediate retry, 0.055ms average frame pacing, and 0 orphan nodes.
  - Bug tracker `docs/BUG_TRACKER.md` documenting all 11 resolved defects.
  - Release checklist `docs/RELEASE_CHECKLIST.md` verifying all 18 acceptance criteria as PASS.
- **Progression, Migrations & Android Lifecycle (M8 part 2):**
  - Save schema v2 with automated migration pipeline (`migrate_data`) initializing mastery challenges and milestones.
  - Android application lifecycle pause (`NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_APPLICATION_FOCUS_OUT`) auto-pausing the runner, releasing held touches, and retaining pause on focus return.
  - Hierarchical Android back-button navigation: modal dismissal -> active run pause -> paused run resume.
- **Screens, Settings & Audio Synthesis (M8 part 1):**
  - 12 synthesized 16-bit retro PCM WAV sound effects (`assets/audio/`) and pooled `AudioManager`.
  - Complete menu suite: Mode Selection (Spicy, Runner, Freestyle, Practice), Skin Shop, Quests, Settings Dialog, 5-Step Illustrated Tutorial, Credits Dialog, and DevOverlay.
  - Practice Mode: 70% speed, 1.5x coyote time & jump buffer, free hit Stone Shield protection, high score isolation.
  - Comprehensive Arabic gameplay guide `docs/GAMEPLAY_GUIDE_AR.md`.
- **Procedural Generation & Fairness (M7):**
  - Deterministic `LevelGenerator` with seed reproduction, 5 difficulty progression bands, and camera-lead chunk spawning/cleanup.
  - 20 chunk patterns including 960px gauntlets (`chunk_18_grand_ruins_gauntlet.tscn`, `chunk_19_volcanic_aerial_chasm.tscn`).
  - Validator V1 (analytic reach/rise limits) and Validator V2 (simulated reference controller at 520 px/s with 0.25s reaction window) verifying 100% fair patterns.
- **World Themes & Transitions (M6):**
  - 4 distinct biomes: Plains, Jungle, Frozen, and Volcanic, each with custom color palettes, background layers, and hazards.
  - Guaranteed zero-hazard transition chunk `chunk_00_transition.tscn` with parallax crossfading.
- **Flight System (M5):**
  - 2 distinct flight pickup mechanics: Mechanical Wings (gliding) and Rocket Relic (high-thrust).
  - Flight controls: vertical up/down steering without ground slide collisions, 2.0s flashing expiry warning, and cushioned glide descent landing.
- **Skills & Collectibles (M4):**
  - 8 distinct abilities: Bone Blade, Boomerang, Stone Shield, Ground Slam, Time Shard, Magnet Relic, Air Dash, and Bounce Power.
  - Amber gem collectibles with audio pickups and magnet attraction.
  - Multi-hit breakable barriers and aerial hazards.
- **Vertical Platforms & Springs (M3):**
  - Stepped elevated platforms, one-way platforms with downward drop-through, spring bounce pads, and vertical camera lead.

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
