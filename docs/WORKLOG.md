# Riftosaur Worklog & Session Tracking

## Current state
- **Session:** Session 3 (Completed)
- **Milestone:** M2 (Endless run loop + first Android debug APK)
- **Last commit:** 9a88d6e (tagged `m2-complete`)
- **Root folder:** `C:\Users\Tweety\Desktop\DINO`
- **Highest evidence level per area:**
  - Setup & Baseline: L2 Automated (22 tests passing, 0 failures, 0 skips)
  - Movement & Core Loop: L3 Desktop play (Endless runner scene, start menu, parallax background, hand-authored chunks, dynamic spawn/recycle, instant retry, pause/resume)
  - Silhouette / Art: L3 Verified (solid black-fill silhouettes verified at 1× and 3×, multi-layer parallax background, deadly crystal spikes)
  - Static Project Validation: L1 Static (0 errors, 0 warnings)
  - Android Build: L4 Static APK Verification (aapt2 dump badging, zipalign 4-byte check, apksigner v2/v3 cert check, archive content check)
  - Physical Android Play: L5 Owner Playtest #1 & #2 complete (All reported issues resolved: layout deconfliction, instant restart fix, main menu return button, 3 difficulty modes, pro art overhaul; latest APK verified)
- **Open Blockers:** 0
- **Open Majors:** 0
- **Owner actions:** Test the updated APK (`releases/Riftosaur-debug.apk`) or approve launch of Session 4.
- **Next action:** Execute Session 4 — Build vertical movement, platforms, spring objects, vertical camera tracking, and Validator V1 upon owner instruction.

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
  - L4 Android Build Verification: Debug APK exported to `releases/Riftosaur-debug.apk` (57,363,089 bytes, SHA-256 `DCAE77CE89E7A75FD988F71F675937DC907E7F961537ACD2221C1D9F8D0FAE3F`). Verified via `tools/verify_apk.ps1` with `aapt2`, `zipalign`, and `apksigner`.
  - L5 Physical Device: Owner Playtest #1 completed. 9 concrete issues reported and addressed (orientation, restart dead lock, resolution scaling, start menu, parallax background, crystal spikes hazard, dual touch zones + buttons, badass icon). Updated APK exported and verified.
- **Bugs opened & closed:**
  - *BUG-M2-01 (Closed):* Godot 4.7 Android export failed with error requiring ETC2/ASTC texture compression. Fixed by setting `textures/vram_compression/import_etc2_astc=true` in `project.godot`.
  - *BUG-M2-02 (Closed):* Headless test runner failed to resolve newly added GDScript classes using `class_name` until editor cache was initialized. Resolved by executing headless editor scan `--editor --quit` to generate `.godot/global_script_class_cache.cfg`.
  - *BUG-M2-03 (Closed):* Runner test assertion failed when accessing HUD after runner world was freed. Fixed by capturing HUD label texts before teardown.
  - *BUG-M2-04 (Closed):* [Owner Playtest #1 - Issue 3] Player stuck on ground after restart: `PlayerStateMachine` rejected transition from `DEAD` to `RUN` because dead state only allowed transition to `RESPAWN`. Fixed by adding comprehensive `player.reset()` transitioning through `RESPAWN` to `RUN`, clearing velocity, timers, and resetting sprite rotation/scale.
  - *BUG-M2-05 (Closed):* [Owner Playtest #1 - Issue 2] App opened in portrait / vertical view because `export_presets.cfg` had `screen/orientation=1` (portrait). Fixed by setting `screen/orientation=0` (landscape locked) in `export_presets.cfg` and `window/handheld/orientation=0` in `project.godot`.
  - *BUG-M2-06 (Closed):* [Owner Playtest #1 - Issues 4 & 9] Blurry resolution, letterboxing, and misplaced white box over gray void: fixed by removing static 480x270 `ColorRect` in world space, switching stretch mode to `canvas_items` and aspect to `expand`, and setting default clear color to deep twilight sky.
  - *BUG-M2-07 (Closed):* [Owner Playtest #1 - Issue 6] Missing background: added 3-layer parallax pixel art background (`bg_sky`, `bg_mountains`, `bg_hills`) with atmospheric twilight sky, distant volcanic peaks, and prehistoric monoliths.
  - *BUG-M2-08 (Closed):* [Owner Playtest #1 - Issue 5] Instant run start without title screen: added `StartMenu` with stylized title, controls breakdown, best score, and Play button; dino stays in breathing `IDLE` state until player starts.
  - *BUG-M2-09 (Closed):* [Owner Playtest #1 - Issue 8] Touch jump misses and swipe down triggering jump: fixed by dynamically splitting screen width (`vp_width * 0.5`), dedicating right 50% strictly to Jump and left 50% strictly to Slide/Dive, and adding on-screen semi-transparent `SlideButton` and `JumpButton`.
  - *BUG-M2-10 (Closed):* [Owner Playtest #1 - Issue 7] Obstacle looked like a stepping stone: replaced dull stone with sharp, glowing crystalline ruby/magenta spikes (`obstacle_low.png`) and tuned hitbox to fair 10x16 dimensions.
  - *BUG-M2-11 (Closed):* [Owner Playtest #1 - Issue 1] App icon quality: generated badass roaring Riftosaur profile with glowing neon-cyan rift eye, dorsal spines, and dimensional rift fissure across all Android densities.
  - *BUG-M2-12 (Closed):* [Owner Playtest #2 - Issue 1] Steer buttons overlap on slide button in Freestyle mode: repositioned `SlideButton` in Mode 2 to `offset_left = 130`, `offset_right = 196`, completely deconflicted from steer buttons at `14..64` and `72..122`.
  - *BUG-M2-13 (Closed):* [Owner Playtest #2 - Issue 2] Instant microsecond death on "Play Again" with score 0: fixed by calling `chunk_container.remove_child(c)` before `queue_free()` to immediately detach colliders from active physics tree, adding 0.35s spawn invulnerability shield, and spawning two empty runway chunks (960px).
  - *BUG-M2-14 (Closed):* [Owner Playtest #2 - Issue 3] Inability to return to main menu to change difficulty modes: added "MAIN MENU" buttons to both Pause and GameOver menus wired to `endless_runner.go_to_title_menu()`.
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
