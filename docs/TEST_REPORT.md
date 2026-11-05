# Riftosaur Test & Verification Report

## Environment Details
- **Engine Version:** Godot Engine v4.7.2.stable.official (`ed1daf0bf`)
- **Host OS:** Windows 10 Pro 64-bit
- **Architecture:** x86_64
- **Java Runtime:** JDK 17 HotSpot 64-bit (`C:\Program Files\Eclipse Adoptium\jdk-17.0.12.7-hotspot`)
- **Android SDK:** API 34 (`platforms;android-34`, `build-tools;34.0.0`, `platform-tools` ADB 1.0.41)
- **Report Date:** 2026-11-05
- **Milestone:** M2 (Session 3 Complete)

---

## 1. Level L1: Static Project Validation
- **Tool:** `tools/validate_l1.gd`
- **Result:** PASSED (0 errors, 0 warnings)
- **Checks Executed:**
  - `project.godot` configuration integrity (viewport 480×270, pixel snapping, stretch mode `viewport`, aspect `keep`).
  - Required input actions registered: `jump`, `slide`, `skill`, `pause`.
  - Main scene and core gameplay scenes resolvable and valid.
  - Script compilation and autoload verification.

---

## 2. Level L2: Automated Unit & Physics Tests
- **Runner:** `tests/test_runner.gd` via `tools/run_tests.ps1`
- **Execution Mode:** Headless SceneTree (`--headless --script tests/test_runner.gd`)
- **Overall Result:** PASSED (22 Passed, 0 Failed, 0 Skipped)

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
| **SaveServiceTest** | `test_default_data_schema` | PASS | Version 1, 0 high_score, default sound/controls |
| **SaveServiceTest** | `test_atomic_save_and_load` | PASS | Atomic write via temp file, clean load back |
| **SaveServiceTest** | `test_high_score_update` | PASS | Increases high score; ignores lower score |
| **SaveServiceTest** | `test_corrupted_save_recovery` | PASS | Recovers gracefully to defaults on invalid JSON/schema |
| **EndlessRunnerLoopTest** | `test_runner_initialization` | PASS | Player, camera, initial chunks spawned |
| **EndlessRunnerLoopTest** | `test_distance_and_score_progression` | PASS | Distance and score accumulate with forward run |
| **EndlessRunnerLoopTest** | `test_pause_and_resume` | PASS | `pause_game()` halts physics tick; resume restores |
| **EndlessRunnerLoopTest** | `test_game_over_and_instant_retry` | PASS | Hazard triggers Game Over; `instant_restart()` resets in 1 tick |

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
  - **File Size:** 57,363,089 bytes (54.71 MB)
  - **SHA-256 Checksum:** `DCAE77CE89E7A75FD988F71F675937DC907E7F961537ACD2221C1D9F8D0FAE3F`
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
