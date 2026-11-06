# Riftosaur Bug Tracker

This document records all defects, unexpected behaviors, and regressions identified during development, along with their resolution, evidence level, and regression test verification.

---

## Severity Definitions
- **Blocker:** Crashes, infinite loops, data corruption, APK build failure, or progression blockers. Must be fixed immediately.
- **Major:** Broken core mechanics, unfair patterns, incorrect scoring, missing Android lifecycle handling, or unreadable UI. Must be fixed before release.
- **Minor:** Cosmetic glitches, audio balancing, non-critical layout shifts, or minor timing variances.
- **Tweak:** Gameplay feel, speed curve tuning, or accessibility refinements.

---

## Bug Log

### Milestone M1 & M2 (Movement & Prototype)
- **BUG-M1-01 (Major - Closed):** In Godot 4 `move_and_slide()` takes no arguments; legacy Godot 3 arguments caused script parse errors.
  - *Fix:* Removed legacy parameters and relied on `velocity` property.
  - *Verification:* L2 unit test in `test_movement.gd`.
- **BUG-M1-02 (Minor - Closed):** Initial jump hold did not cap properly when jump input was held indefinitely.
  - *Fix:* Added `jump_hold_timer` with `max_jump_hold_time` cap enforcing variable jump heights between min (tap) and max (held).
  - *Verification:* L2 unit test `test_jump_hold_cap_and_gravity`.

### Milestone M3 (Android Export & Core Loop)
- **BUG-M3-01 (Blocker - Closed):** Godot Android export template was missing debug keystore configuration.
  - *Fix:* Generated local development debug keystore and configured `export_presets.cfg`.
  - *Verification:* L4 APK export verified via `tools/verify_apk.ps1`.
- **BUG-M3-02 (Major - Closed):** Unintended double jumps occurred when tapping jump while falling without floor contact.
  - *Fix:* Enforced strict `coyote_timer` window and cleared `coyote_timer` on jump execution.
  - *Verification:* L2 unit test `test_coyote_time_allows_grace_and_prevents_double_jump`.

### Milestone M4 (Skills & Collectibles)
- **BUG-M4-01 (Major - Closed):** Bone Blade destroyed solid obstacles, violating spec requirement that only Breakable obstacles can be cut.
  - *Fix:* Added category filtering check in `bone_blade_projectile.gd` ensuring only `HazardCategory.BREAKABLE` is destroyed.
  - *Verification:* L2 unit test `test_bone_blade_ignores_solid`.
- **BUG-M4-02 (Minor - Closed):** Stone Shield did not absorb aerial hazard collisions properly when falling into an airborne hazard.
  - *Fix:* Updated `hit_hazard()` in `player.gd` to invoke `skill_manager.absorb_shield_hit()` before applying death state.
  - *Verification:* L2 unit test `test_stone_shield_absorbs_hit`.

### Milestone M5 (Flight System)
- **BUG-M5-01 (Major - Closed):** Down input during flight triggered a crouch/slide instead of a controlled descent.
  - *Fix:* Routed down input during `FLIGHT` state to vertical descent velocity without invoking `_enter_slide()`.
  - *Verification:* L2 unit test `test_flight_down_input_descent_no_slide`.
- **BUG-M5-02 (Minor - Closed):** Flight timer continued counting down during game pause.
  - *Fix:* Wrapped flight timer countdown in `if not is_paused:` guard.
  - *Verification:* L2 unit test `test_flight_pause_preserves_timer` and QA Scenario 9.

### Milestone M6 (Worlds & Transitions)
- **BUG-M6-01 (Major - Closed):** Transition chunks occasionally spawned hazards if selected randomly from generic pool.
  - *Fix:* Built dedicated zero-hazard transition chunk `chunk_00_transition.tscn` forced at biome milestone distances.
  - *Verification:* L2 unit test `test_safe_transition_chunk_zero_hazards`.

### Milestone M7 (Procedural Generation & Fairness)
- **BUG-M7-01 (Minor - Closed):** Generator script referenced `bounce_pad_mushroom.tscn` instead of `bounce_mushroom.tscn`.
  - *Fix:* Corrected path in `generate_session8_chunks_and_patterns.py`.
  - *Verification:* L1 project validation.
- **BUG-M7-02 (Major - Closed):** Validator V1 failed on `chunk_19_volcanic_aerial_chasm.tscn` due to unassisted platform elevation exceeding 80% jump rise.
  - *Fix:* Added assisted bounce pad on platform approach.
  - *Verification:* Validator V1 & V2 passing (20/20 chunks).

### Milestone M8 (Screens, Settings, Progression, Lifecycle)
- **BUG-M8-01 (Minor - Closed):** `SaveServiceTest` failed when schema was bumped to version 2 due to hardcoded `defs["version"] == 1`.
  - *Fix:* Updated test to verify `version >= 1` and test schema v1->v2 migration.
  - *Verification:* L2 unit test `test_save_schema_v1_to_v2_migration`.
- **BUG-M8-02 (Major - Closed):** Android back button exited app without pausing active runner.
  - *Fix:* Implemented hierarchical `_handle_back_action()` prioritizing dialog dismissal, game pause, and unpause.
  - *Verification:* L2 unit test `test_android_back_button_hierarchical_dismissal`.
- **BUG-M8-03 (Minor - Closed):** Android APK build inadvertently included `INTERNET` permission by default.
  - *Fix:* Configured `permissions/internet=false` in `export_presets.cfg` and added automated audit to `tools/verify_apk.ps1`.
  - *Verification:* L4 APK inspection confirms `android.permission.INTERNET: False`.

---

## Status Summary
- **Open Blockers:** 0
- **Open Majors:** 0
- **Open Minors:** 0
- **Total Resolved Bugs:** 11
- **Release Ready (v1.0.0-rc):** YES
