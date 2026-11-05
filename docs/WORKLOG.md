# Riftosaur Worklog & Session Tracking

## Current state
- **Session:** Session 3 (Completed)
- **Milestone:** M2 (Endless run loop + first Android debug APK)
- **Last commit:** 9a88d6e (tagged `m2-complete`)
- **Root folder:** `C:\Users\Tweety\Desktop\DINO`
- **Highest evidence level per area:**
  - Setup & Baseline: L2 Automated (22 tests passing, 0 failures, 0 skips)
  - Movement & Core Loop: L3 Desktop play (Endless runner scene, hand-authored chunks, dynamic spawn/recycle, instant retry, pause/resume)
  - Silhouette / Art: L3 Verified (solid black-fill silhouettes verified at 1× and 3×)
  - Static Project Validation: L1 Static (0 errors, 0 warnings)
  - Android Build: L4 Static APK Verification (aapt2 dump badging, zipalign 4-byte check, apksigner v2/v3 cert check, archive content check)
  - Physical Android Play: NOT RUN (No physical device or emulator connected; Owner playtest #1 requested)
- **Open Blockers:** 0
- **Open Majors:** 0
- **Owner actions:** Owner Playtest #1 requested: Install `releases/Riftosaur-debug.apk` on an Android device following `START_HERE_AR.md` and test jump, slide, retry, and pause. Does not block Session 4.
- **Next action:** Execute Session 4 — Build vertical movement, platforms, spring objects, vertical camera tracking, and Validator V1.

---

## Session entries

### Session 3 — Endless run loop + first Android debug APK (M2)
- **Date:** 2026-11-05
- **Milestone:** M2
- **Start commit:** f634775 (`m1-complete`)
- **End commit:** 9a88d6e (tag: `m2-complete`)
- **Evidence levels reached:**
  - L1 Static: Zero script/parse errors, all scenes instantiable, clean project validation via `tools/validate_l1.gd`.
  - L2 Automated: 22 passing automated unit and physics tests in `tests/test_runner.gd` (5 smoke + 1 replay + 8 movement + 4 save service + 4 endless runner loop).
  - L3 Desktop play: Full endless runner loop with chunk sequencing, score/distance accumulation, pause/resume, game over with cause display, and sub-second instant restart.
  - L4 Android Build Verification: Debug APK exported to `releases/Riftosaur-debug.apk` (57,247,541 bytes, SHA-256 `054A19E7A28D692760F9ABCBCDBAE783ABABB44654481F9979598DD12999EC98`). Verified via `tools/verify_apk.ps1` with `aapt2`, `zipalign`, and `apksigner`.
  - L5 Physical Device: NOT RUN (No physical device or emulator attached to workstation). Owner Playtest #1 requested.
- **Bugs opened & closed:**
  - *BUG-M2-01 (Closed):* Godot 4.7 Android export failed with error requiring ETC2/ASTC texture compression. Fixed by setting `textures/vram_compression/import_etc2_astc=true` in `project.godot`.
  - *BUG-M2-02 (Closed):* Headless test runner failed to resolve newly added GDScript classes using `class_name` until editor cache was initialized. Resolved by executing headless editor scan `--editor --quit` to generate `.godot/global_script_class_cache.cfg`.
  - *BUG-M2-03 (Closed):* Runner test assertion failed when accessing HUD after runner world was freed. Fixed by capturing HUD label texts before teardown.
- **Decisions and reasons:**
  - Implemented versioned atomic save system (schema v1) with temporary file staging and automated backup to prevent data loss or save file corruption on sudden process termination.
  - Built 5 hand-authored chunks with increasing challenge rather than pure random obstacles, guaranteeing jumpable hurdle spacing and slide-under clearance.
  - Configured full-height touch zones (left swipe down for slide/dive, right tap/hold for jump) ensuring high responsiveness on mobile devices with $\ge 48\text{ dp}$ UI targets.
- **Documents started / updated:**
  - `START_HERE_AR.md` (quick start guide in Arabic)
  - `docs/ANDROID_INSTALL_GUIDE_AR.md` (detailed installation guide in Arabic)
  - `docs/ANDROID_BUILD_GUIDE_AR.md` (build instructions in Arabic)
  - `docs/TEST_REPORT.md` (test & verification summary)
  - `releases/README.md` & `releases/SHA256SUMS.txt` (build register)
  - `CHANGELOG.md` (updated for M2)
  - `docs/WORKLOG.md` (updated for Session 3)
- **Changes to plan:** None.
- **Blockers:** None.

---

### Session 2 — Dinosaur movement prototype, desktop (M1)
- **Date:** 2026-11-05
- **Milestone:** M1
- **Start commit:** ae88541 (`m0-complete`)
- **End commit:** f634775 (tag: `m1-complete`)
- **Evidence levels reached:**
  - L1 Static: Zero script/parse errors, clean resource resolution, all input actions defined and verified via `tools/validate_l1.gd`.
  - L2 Automated: 14 passing automated unit tests in `tests/test_runner.gd` (5 smoke + 1 replay + 8 movement physics tests).
  - L3 Desktop play: 120-second continuous automated desktop test track run completed (reaching full 464.0 px/s speed cap, 30,312 px covered, 0 orphan nodes, logged in `docs/evidence/desktop_run_2min.log`). Solid silhouette check at 1× and 3× verified in `docs/evidence/`.
- **Bugs opened & closed:**
  - *BUG-M1-01 (Closed):* Held jump failed to reach 84px height in headless tests due to input polling returning false without active window. Fixed by adding virtual input property `jump_held` on `Player` and tuning `jump_hold_force` to 800.0 px/s². Verified with `test_short_hop_vs_held_jump`.
  - *BUG-M1-02 (Closed):* Player premature slide exit under overhang when `CeilingRay` was only single-point and only masked layer 2. Fixed by setting collision mask to 6 (ground + hazard) and adding dual front/back ceiling rays (`CeilingRayBack`).
  - *BUG-M1-03 (Closed):* Lambda closure in GDScript 4 capturing primitive boolean by value prevented test from detecting `died` signal. Fixed by wrapping in an array container `[false]`.
- **Decisions and reasons:**
  - Tuned `jump_hold_force` to 800.0 px/s² in `GameplayConfig` to achieve ~84px max height with 0.35s hold while keeping tap jump at crisp 28-30px.
  - Implemented dual front/back ceiling raycasts on the dinosaur to prevent the tail or snout from clipping into overhead obstacles during standing recovery.
  - Pixel-snapped horizontal camera with 120px horizontal lead keeping dinosaur in the left third of the 480×270 viewport.
- **Documents started / updated:**
  - `docs/DEVELOPER_GUIDE.md` (started)
  - `docs/ARCHITECTURE.md` (started)
  - `docs/ASSET_LICENSES.md` (started)
  - `README.md` (updated)
  - `CHANGELOG.md` (updated for M1)
- **Changes to plan:** None.
- **Blockers:** None.

---

### Session 1 — Preflight + project setup and baseline (M0)
- **Date:** 2026-11-05
- **Milestone:** M0
- **Start commit:** 295627e (root commit)
- **End commit:** ae88541 (tag: `m0-complete`)
- **Evidence levels reached:**
  - L1 Static: Verified headless project load, import, settings, and node/action references with `tools/validate_l1.gd`.
  - L2 Automated: 6 automated tests passed (5 smoke tests in `test_smoke.gd` + 1 replay test in `test_replay.gd`).
- **Preflight Survey Results (1A):**
  - **OS:** Windows 10 Pro (10.0.19045)
  - **CPU:** Intel Core i7-6820HQ @ 2.70GHz (4 cores / 8 threads)
  - **RAM:** 15.88 GB total visible
  - **Free Disk Space:** 23.85 GB on C:
  - **Graphics / Drivers:** Intel HD Graphics 530 & NVIDIA Quadro M2000M
  - **Java:** Microsoft HotSpot JDK 17.0.20
  - **Godot Engine:** Godot 4.7.2.stable.official
  - **Export Templates:** Godot 4.7.2.stable installed in `%APPDATA%\Godot\export_templates\4.7.2.stable\`
  - **Android SDK / adb:** `adb` not in system PATH (to be configured prior to Session 3).
  - **Hardware Virtualization:** False in firmware.
  - **Reachability:** All sources reachable (Godot, GitHub, Google repo, Maven, Gradle, PyPI).
  - **Git & GitHub:** Authenticated as `lam3y35`.
- **Bugs opened / closed:** None.
- **Decisions and reasons:** Pinned Godot 4.7.2, 480×270 viewport, nearest-neighbor texture filtering, gl_compatibility renderer.
- **Changes to plan:** None.
- **Blockers:** None.
