# Riftosaur Test & Verification Report

## Environment Details
- **Engine Version:** Godot Engine v4.7.2.stable.official (`ed1daf0bf`)
- **Host OS:** Windows 10 Pro 64-bit
- **Architecture:** x86_64
- **Java Runtime:** JDK 17 HotSpot 64-bit (`C:\Program Files\Eclipse Adoptium\jdk-17.0.12.7-hotspot`)
- **Android SDK:** API 34 (`platforms;android-34`, `build-tools;34.0.0`, `platform-tools` ADB 1.0.41)
- **Report Date:** 2026-11-06
- **Milestone:** M8 part 2 (Session 10 Complete)

---

## 1. Level L1: Static Project Validation
- **Tool:** `tools/validate_l1.gd`
- **Result:** PASSED (0 errors, 0 warnings)
- **Checks Executed:**
  - `project.godot` configuration integrity (viewport 480×270, pixel snapping, stretch mode `viewport`, aspect `keep`).
  - Required input actions registered: `jump`, `slide`, `skill`, `pause`.
  - Main scene and core gameplay scenes resolvable and valid.
  - Script compilation, autoloads, and resource definitions verified.

---

## 2. Validator V1: Analytic Reach and Rise Fairness
- **Tool:** `tools/validate_v1.gd`
- **Result:** PASSED (20 Chunks Validated, 0 Errors, 0 Warnings)
- **Checks Executed:**
  - 80% maximum jump rise rule: all platforms comply with max rise 49.6px (80% of 62px peak rise) unless assisted by bounce pad/vent or stepped platform.
  - Reaction window check at max player speed (520 px/s).
  - Unavoidable sequence & vertical hazard trap prevention.

---

## 3. Validator V2: Simulated Reference Controller Validation
- **Tool:** `tools/validate_v2.gd`
- **Output Report:** `tests/validator_v2_report.json`
- **Result:** PASSED (20/20 Patterns Passed, 0 Failures, 0 Exclusions)
- **Reference Controller Specification:**
  - Headless physical simulation through each chunk pattern.
  - Realistic reaction delay: 0.25s perception window.
  - Simulated at maximum pattern speed (up to 520 px/s).
  - Allowed inputs only: Jump, Jump Hold, Slide, Flight Up, Flight Down, Dive.
- **Pattern Distribution:**
  - **Band 1 (Teaching, 0-150m):** 3 patterns (`p00_world_transition`, `p01_safe_breather`, `p02_single_low_hop`)
  - **Band 2 (150-350m):** 4 patterns (`p03_stone_arch_slide`, `p04_double_low_rhythm`, `p06_crate_step_hurdle`, `p08_double_crate_stair`)
  - **Band 3 (350-600m):** 5 patterns (`p05_jump_and_slide`, `p07_triple_low_hurdles`, `p09_mushroom_bounce`, `p13_airborne_pterodactyl`, `p14_crawler_and_barrier`)
  - **Band 4 (600-900m):** 6 patterns (`p10_multi_tier_platforms`, `p11_bounce_pad_chain`, `p12_wind_vent_ascent`, `p15_skill_gem_cache`, `p16_flight_wings_route`, `p18_grand_ruins_gauntlet` [960px])
  - **Band 5 (900m+):** 2 patterns (`p17_flight_rocket_route`, `p19_volcanic_aerial_chasm` [960px])
- **Worlds Coverage:** All 4 worlds (`plains`, `jungle`, `frozen`, `volcanic`) mapped and validated.

---

## 4. Level L2: Automated Unit & Physics Tests
- **Runner:** `tests/test_runner.gd` via `tools/run_tests.ps1`
- **Execution Mode:** Headless SceneTree (`--headless --script tests/test_runner.gd`)
- **Overall Result:** PASSED (71 Passed, 0 Failed, 0 Skipped)
- **Suite Breakdown:**
  1. `SmokeTest`: 5 tests
  2. `ReplayDeterministicTest`: 1 test
  3. `PlayerMovementTest`: 9 tests
  4. `SaveServiceTest`: 4 tests
  5. `EndlessRunnerLoopTest`: 8 tests
  6. `VerticalPlatformSpringTest`: 5 tests
  7. `SkillsAndCollectiblesTest`: 10 tests
  8. `FlightSystemTest`: 5 tests
  9. `WorldThemesAndTransitionsTest`: 4 tests
  10. `ProceduralGenerationAndFairnessTest`: 6 tests
  11. `UIAndScreensTest`: 6 tests
  12. `ProgressionAndLifecycleTest`: 8 tests (Schema v2 migration, missing save fallback, pause on focus loss, resume retention, input release on focus loss, back button closes dialogs, back button pauses running game, back button unpauses).

---

## 5. Level L3: Long-Run Stability & Memory Verification
- **Tool:** `tools/verify_session8_stability.gd`
- **Result:** PASSED (10.0 minutes game time simulated, 36,000 steps, 53,117.1m run)
- **Metrics Recorded:**
  - Max Active Chunks in Memory: 5 (bound <= 10)
  - Start Static Memory: 42.31 MB
  - Warmup Static Memory: 115.16 MB
  - Final Static Memory: 69.02 MB
  - Steady-State Drift: -46.14 MB (Zero leak, stable memory footprint)

### Detailed Suite Breakdown

| Suite | Test Name | Result | Duration / Notes |
|---|---|---|---|
| **SmokeTest** | `test_project_name_and_identity` | PASS | Verified project name "Riftosaur" |
| **SmokeTest** | `test_viewport_resolution_and_pixel_art` | PASS | Verified 480×270, nearest filtering |
| **SmokeTest** | `test_required_input_actions` | PASS | Verified jump, slide, skill, pause |
| **SmokeTest** | `test_main_scene_load_and_instance` | PASS | Instance and node tree initialization |
| **SmokeTest** | `test_deterministic_random_seed` | PASS | Seed reproduciblity check |
| **InputReplayTest** | `test_input_recording_and_playback` | PASS | Frame-accurate action capture & playback |
| **MovementTestSuite** | `test_ground_detection_and_running` | PASS | 10 ticks: on floor, velocity.x = 180 px/s |
| **MovementTestSuite** | `test_short_hop_vs_held_jump` | PASS | Tap apex 29.8px, hold apex 83.9px (~84px spec) |
| **MovementTestSuite** | `test_jump_hold_cap_and_gravity` | PASS | Hold limit at 0.35s, fall speed cap 720 px/s |
| **MovementTestSuite** | `test_jump_buffer_timing` | PASS | Action queued 4 ticks before landing triggers jump |
| **MovementTestSuite** | `test_coyote_time_allows_grace_and_prevents_double_jump` | PASS | Jump permitted 0.08s after leaving ledge; single use |
| **MovementTestSuite** | `test_slide_and_collision_shape_shrink_and_recovery` | PASS | Height shrinks 28px -> 14px, restores after exit |
| **MovementTestSuite** | `test_dive_mechanic` | PASS | Mid-air slide accelerates downward to 650 px/s |
| **MovementTestSuite** | `test_interrupted_state_hazard_hit` | PASS | Hazard collision transitions to Hurt/Dead, stops speed |
| **MovementTestSuite** | `test_overhang_slide_clearance_and_jump_fatal` | PASS | Slide passes 14px crawlspace safely; mid-air jump/dive into arch is fatal |
| **SaveServiceTest** | `test_default_data_schema` | PASS | Version 1, 0 high_score, default sound/controls |
| **SaveServiceTest** | `test_atomic_save_and_load` | PASS | Atomic write via temp file, clean load back |
| **SaveServiceTest** | `test_high_score_update` | PASS | Increases high score; ignores lower score |
| **SaveServiceTest** | `test_corrupted_save_recovery` | PASS | Recovers gracefully to defaults on invalid JSON/schema |
| **SaveServiceTest** | `test_points_addition_and_spending` | PASS | Welcome bonus, additions, and atomic spending validation |
| **SaveServiceTest** | `test_skin_unlock_and_equip` | PASS | Unlocking, equipping, and persistence of dino skins |
| **SaveServiceTest** | `test_challenge_service_progress_tracking` | PASS | Event tracking, milestone detection, and point reward grants |
| **EndlessRunnerLoopTest** | `test_runner_initialization` | PASS | Player, camera, initial chunks spawned |
| **EndlessRunnerLoopTest** | `test_distance_and_score_progression` | PASS | Distance and score accumulate with forward run |
| **EndlessRunnerLoopTest** | `test_pause_and_resume` | PASS | `pause_game()` halts physics tick; resume restores |
| **EndlessRunnerLoopTest** | `test_game_over_and_instant_retry` | PASS | Hazard triggers Game Over; `instant_restart()` resets in 1 tick |
| **EndlessRunnerLoopTest** | `test_camera_ground_lock_during_jump` | PASS | Camera Y locked to 135.0 baseline on jumps; zero disconnect |
| **EndlessRunnerLoopTest** | `test_skin_switching_and_shop_dialog` | PASS | Player skin texture swap and HUD modal visibility toggles |

---

## 3. Level L3: Desktop Gameplay Verification
- **Runners:**
  - `scenes/gameplay/flat_test_track.tscn` (M1 movement playtest)
  - `scenes/gameplay/endless_runner.tscn` (M2 endless run loop)
- **Findings:**
  - 120-second continuous desktop playtest logged to `docs/evidence/desktop_run_2min.log`.
  - Reached full speed cap of 464.0 px/s with 0 orphan nodes.
  - Chunk recycling dynamically frees chunks falling behind camera (`global_position.x + chunk_width < despawn_x`) and spawns ahead.
  - Solid silhouette verification confirmed clean 1× and 3× black fills (`docs/evidence/silhouette_1x.png`, `docs/evidence/silhouette_3x.png`).

---

## 4. Level L4: Android Package (APK) Verification
- **Artifact:** `releases/Riftosaur-debug.apk`
- **Verification Script:** `tools/verify_apk.ps1`
- **Result:** PASSED (L4 Verified)
- **Specification Compliance (Spec D):**
  - **File Size:** 62,290,160 bytes (59.40 MB)
  - **SHA-256 Checksum:** `EF4F4C2768D1A51CFD33732E6A376ED8B9DC24E40A6C0894A873AB4E90A03037`
  - **Package Identifier:** `com.riftosaur.game`
  - **Version:** `versionCode='1'`, `versionName='0.3.0'`
  - **SDK Target:** `minSdkVersion='24'`, `targetSdkVersion='36'`
  - **Orientation:** Landscape locked (`screen/orientation=0`)
  - **Architectures Included:** `arm64-v8a`, `x86_64`
  - **4-byte Alignment (zipalign):** Verified successful
  - **Code Signature (apksigner):** Verified with Godot debug certificate
  - **Internal Assets:** `classes.dex`, `libgodot_android.so` for both architectures, textures and scenes bundled.

---

## 5. Level L5: Physical Device Playtest
- **Status:** **NOT RUN**
- **Reason:** No physical Android device or hardware-accelerated emulator attached to the build workstation (`adb devices` list empty; host BIOS virtualization disabled).
- **Action Taken:** Generated Owner Installation & Playtest Guides (`START_HERE_AR.md`, `docs/ANDROID_INSTALL_GUIDE_AR.md`). Requested **Owner Playtest #1** per project protocol.
