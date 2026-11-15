# Changelog

All notable changes to the Riftosaur project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] - Asset visual pass

### Changed
- Obstacle, boost, pickup, platform and skill sprites re-shaded (stronger color, rim light, gradient, deeper outlines) via `tools/enhance_asset_pop.py` (originals backed up in `assets/sprites/_orig_before_pop/`).
- Gem redrawn as a faceted crystal; dust puffs redrawn.

### Added
- `AssetJuice` (`scripts/effects/asset_juice.gd`): pulsing glow halos, ground shadows, twinkles and particle bursts on gems, pickups, bounce pads, hazards and on collect/destroy.

## [1.3.0] - 2026-11-15 (60 FPS Clarity, Controls, Skill Deck & Lab, 4 Traps, Hearts, Linked Map Builder & PS4 Overhaul)

### Added & Improved
- **60 FPS Clarity & Responsive Controls (`project.godot`, `scripts/ui/hud.gd`, `scripts/player/player.gd`, `scripts/gameplay/endless_runner.gd`):**
  - Locked `max_fps=60`, `vsync_mode=1`, `physics_ticks_per_second=60`, `physics_jitter_fix=0.0`; clamped `GameCamera` zoom (`0.94..1.04`) and moved speed-line FX to screen edges only.
  - Added `96×92` corner `HitZoneLayer` pads behind `84×44` `JumpButton` & `SlideButton` with direct multi-touch `gui_input` routing (zero overlap with Steer/Skill buttons), enabled Slide & Steer across all 4 modes, guarded `trigger_jump_press()` at `velocity.y >= -10.0`, and wired Jump/Slide taps on idle launch to auto-start and act on frame 1.
- **Difficulty Speeds, Hearts & 4 Hazard Traps (`scripts/gameplay/endless_runner.gd`, `scripts/objects/trap_pickup.gd`, `scripts/ui/hud.gd`):**
  - Tuned opening speeds and difficulty hearts: `Easy (196→400 px/s, 2♥)`, `Medium (216→460 px/s, 1♥)`, `Hard (232→495 px/s, 3♥, dense spawn profile)`, `Practice (196→310 px/s)`, with forward-assist recovery when surviving environmental hazards via hearts/immortality.
  - Expanded `TrapPickup` to 4 distinct traps (`SPEED_SURGE`, `HEAVY_GRAVITY` with `1.55×` gravity, `VISION_GLITCH` overlay, `SKILL_JAM`) with independent debuff timers, multi-lane placement, and dedicated HUD debuff feedback.
- **4-Skill Loadout, Distance-Rarity Spawning & Infinite Skill Lab (`scripts/systems/save_service.gd`, `scripts/systems/skill_manager.gd`, `scripts/ui/practice_hub_ui.gd`):**
  - Enforced `MAX_ENABLED_MAP_SKILLS = 4` (starter deck `[1, 2, 3, 5]`) with `4-STARTER`/`CLEAR` toggles and distance-based rarity intervals (`70m / 105m / 145m / 195m`) placed with horizontal hazard clearance at contextually relevant obstacles.
  - Added infinite Skill Lab mode (`skill_lab_infinite` keeps charges `>= 1` and cooldown `<= 0.30s`) inside dedicated obstacle-matched test arenas.
- **7-Step Live Tutorial, Animated Enemies Encyclopedia, Quests, Skin Shop & Linked Map Builder:**
  - Upgraded tutorial to 7 input-gated phases (`player.jumped` required on Step 1) with persistent `active_immortal_shield` visual in Practice & immortal custom maps, and restricted tip popups exclusively to Tutorial/Practice mode while clearing them on exit/restart.
  - Added 9-entry Enemies Encyclopedia dialog with ~1.2s animated `_EnemyPreviewCanvas` sprites and counter-strategy notes; added visual `_CosmeticPreviewCanvas` swatches, persistent map tint across biome transitions, and swipe-guarded horizontal drag scrolling in `ShopScroll`; enforced single-claim quest guards in `ChallengeService`.
  - Switched `LevelGenerator` to shuffled bag pattern ordering (`_shuffled_bag_ids`) + biome-exclusive chunks (lava volcanic-only).
  - Expanded Custom Map Builder to `2.6k / 3.8k / 5.0k` (`5000px` save cap) with per-trap variant cycling, live jump-arc & green/amber/red gap-passability checks, visual obstacle silhouettes, and live multi-map progression & course completion (`linked_next_id`).
- **PS4 Controller & Verification (`scripts/ui/hud.gd`, `tests/unit/test_v4_overhaul.gd`):**
  - Fixed PS4 menu, Practice Entry Panel, Pause/GameOver/dialog navigation, analog Y release tracking without Cross-button jitter, and `clear_touch_inputs()` state reset.
  - Verified **113/113** automated unit tests (`test_v4_overhaul.gd` added with full v1.3.0 regression coverage), `L1` static validation (0 errors), `Validator V1 & V2` (`24/24` patterns), and L4 Android APK verification (`versionCode=4`, `versionName="1.3.0"`).

---

## [1.2.0] - 2026-11-15 (Multi-Skill Slots, 16+ Skins, Practice Hub, Leveling & Controls Overhaul)

### Added & Improved
- **Multi-Skill System & Traps:**
  - Upgraded `SkillManager` and HUD to support 3 simultaneous skill slots with independent activation buttons (`scripts/systems/skill_manager.gd`, `scripts/ui/hud.gd`).
  - Expanded to 12 skills with tiers, rarity, short tags, usage hints, and `SkillTagBadge` visuals on `SkillPickup` (`scenes/objects/skill_pickup.tscn`, `scripts/objects/skill_pickup.gd`).
  - Added `TrapPickup` (`scenes/objects/trap_pickup.tscn`, `scripts/objects/trap_pickup.gd`) applying speed-surge debuffs.
- **Expanded Skins, Cosmetics & Perks:**
  - Added 11 new dinosaur skins (`Amethyst`, `Celestial`, `Chromatic God`, `Cobalt`, `Crimson Rex`, `Diamond Apex`, `Inferno`, `Jade Emperor`, `Obsidian`, `Plasma`, `Void Walker`) with sprite sheets and shop icons (`assets/sprites/`).
  - Added obstacle, map, and trail cosmetics in the Skin Shop plus passive/starter skin perks (`scripts/systems/save_service.gd`, `scripts/player/player.gd`).
- **Tutorial & Practice Hub:**
  - Added `PracticeHubUI` (`scripts/ui/practice_hub_ui.gd`) with first-launch auto-tutorial flow, live tutorial steps & skip, practice immortality with adaptive hints, section practice, and custom map builder.
  - Isolated per-mode high scores (`mode_best_scores`) with score/best hidden in Tutorial & Practice mode.
- **Quests & Player Leveling:**
  - Expanded `ChallengeService` to 25+ quests and added XP-based player leveling with diamond bonus rewards (`scripts/systems/challenge_service.gd`).
- **Controls & PS4 Gamepad Support:**
  - Added slide-hold continuation, air-only left steering, crawler stomp from above/dive (+1 gem), and PS4 controller mode with custom remapping (`scripts/player/player.gd`, `scripts/obstacles/hazard.gd`, `scripts/ui/hud.gd`).
- **Rendering, Camera & Parallax Polish:**
  - Enabled `physics_interpolation` and disabled pixel-snap jitter in `project.godot`.
  - Improved high-jump camera ground locking (`scripts/world/game_camera.gd`) and 1440px parallax tiling with `SkyBackdropLayer` (`scripts/world/parallax_controller.gd`).
- **Testing & Post-Release Regression Fixes:**
  - Expanded the L2 automated test suite to 104/104 passing tests across all suites, including regression coverage for `PracticeHubUI` viewport bounds & non-overlapping overlays, visible/unblocked Jump & Slide touch controls with `FOCUS_NONE`, and step-by-step live tutorial progression & ground alignment.
  - Fixed `v1.2.0` regressions in `scripts/ui/practice_hub_ui.gd`, `scripts/ui/hud.gd`, and `scripts/gameplay/endless_runner.gd` (full-viewport anchoring and panel clamping for dialogs/banners, TopBar non-overlapping Practice quick bar, restored visible Jump/Slide touch buttons and removed the bottom dead-zone, real mechanic checks and respawn recovery for the 5-step interactive tutorial with ground-aligned obstacles).

---

## [1.1.0] - 2026-11-15 (Security Hardening, Visual/Audio Upgrade & Biome Expansion)

### Added & Improved
- **Save Security & Input Replay Hardening:**
  - Added HMAC-SHA256 signature verification, tamper rejection/quarantine, canonical skin pricing validation, and type-confusion guards in `scripts/systems/save_service.gd`.
  - Added action whitelist and monotonic timestamp guards in `scripts/systems/input_replay.gd`.
- **Visuals, VFX & Audio:**
  - Added `FXManager` (`scripts/effects/fx_manager.gd`) for pixel-art particles, shockwaves, slash arcs, afterimages, speed lines, and biome ambient effects.
  - Upgraded character sprite sheets, parallax backgrounds, subground strata (`assets/sprites/subground_strata.png`), and launcher icons (`tools/generate_enhanced_art.py`, `tools/generate_icon.py`).
  - Added looping menu and gameplay background music (`assets/audio/bgm_menu.wav`, `assets/audio/bgm_run.wav`) and expanded synthesized SFX in `scripts/systems/audio_manager.gd` (`tools/generate_enhanced_audio.py`).
- **Biomes, Hazards & Procedural Patterns:**
  - Added 4 biome-specific chunks (`scenes/obstacles/chunks/chunk_20_jungle_canopy_run.tscn` through `chunk_23_plains_sky_trail.tscn`) and `scenes/obstacles/hazard_lava_pit.tscn`, bringing total verified chunks/patterns to 24/24.
  - Added near-miss combo/fever feedback, HUD layout/safe-area refinements, and practice mode state resets (`scripts/gameplay/endless_runner.gd`, `scripts/ui/hud.gd`).
- **Testing & Android Packaging:**
  - Expanded the L2 automated test suite to 90/90 passing tests with `tests/unit/test_v2_improvements_and_security.gd`.
  - Configured strict APK exclusion filters in `export_presets.cfg` (`gini/*,docs/*,tests/*,tools/*,.agents/*,.godot_tmp/*,releases/*,*.md,*.ps1,*.py`) and privacy leak checks in `tools/verify_apk.ps1`.

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
