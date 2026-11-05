# Riftosaur Worklog & Session Tracking

## Current state
- **Session:** Session 2 (Completed)
- **Milestone:** M1 (Dinosaur movement prototype - desktop)
- **Last commit:** f634775 (tagged `m1-complete`)
- **Root folder:** `C:\Users\Tweety\Desktop\DINO`
- **Highest evidence level per area:**
  - Setup & Baseline: L2 Automated (14 tests passing, 0 failures, 0 skips)
  - Movement / Gameplay: L3 Desktop play (120-second continuous desktop playtest logged to `docs/evidence/desktop_run_2min.log`)
  - Silhouette / Art: L3 Verified (solid black-fill silhouettes verified at 1× and 3× in `docs/evidence/silhouette_1x.png`, `docs/evidence/silhouette_3x.png`)
  - Static Project Validation: L1 Static (0 errors, 0 warnings)
  - Android Build: L0 (Scheduled for Session 3)
- **Open Blockers:** 0
- **Open Majors:** 0
- **Owner actions:** None at this time (Owner playtest #1 requested after Session 3).
- **Next action:** Execute Session 3 — Build endless run loop, scoring, hand-authored chunks, instant retry, pause/resume, versioned save, HUD, touch controls, and first Android debug APK.

---

## Session entries

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
