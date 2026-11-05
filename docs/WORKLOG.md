# Riftosaur Worklog & Session Tracking

## Current state
- **Session:** Session 1 (Completed)
- **Milestone:** M0 (Preflight + project setup and baseline)
- **Last commit:** Pending first commit (Session 1 wrap-up)
- **Root folder:** `C:\Users\Tweety\Desktop\DINO`
- **Highest evidence level per area:**
  - Setup & Baseline: L2 Automated (6 tests passing, 0 failures, 0 skips)
  - Static Project Validation: L1 Static (0 errors, 0 warnings)
  - Movement / Gameplay: L0 (Scheduled for Session 2)
  - Android Build: L0 (Scheduled for Session 3)
- **Open Blockers:** 0
- **Open Majors:** 0
- **Owner actions:** None at this time.
- **Next action:** Execute Session 2 — Build dinosaur movement prototype (states, variable jump, coyote/buffer timing, slide, camera, and flat test track).

---

## Session entries

### Session 1 — Preflight + project setup and baseline (M0)
- **Date:** 2026-11-05
- **Milestone:** M0
- **Start commit:** None (Initial commit)
- **End commit:** Pending initial commit
- **Evidence levels reached:**
  - L1 Static: Verified headless project load, import, settings, and node/action references with `tools/validate_l1.gd`.
  - L2 Automated: 6 automated tests passed (5 smoke tests in `test_smoke.gd` + 1 replay test in `test_replay.gd`).
- **Preflight Survey Results (1A):**
  - **OS:** Windows 10 Pro (10.0.19045)
  - **CPU:** Intel Core i7-6820HQ @ 2.70GHz (4 cores / 8 threads)
  - **RAM:** 15.88 GB total visible
  - **Free Disk Space:** 23.85 GB on C:
  - **Graphics / Drivers:** Intel HD Graphics 530 (Driver 31.0.101.2111) & NVIDIA Quadro M2000M (Driver 32.0.15.8253)
  - **Java:** Microsoft HotSpot JDK 17.0.20 (`C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot\bin\java.exe`)
  - **Godot Engine:** Godot 4.7.2.stable.official (`C:\Users\Tweety\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe`)
  - **Export Templates:** Godot 4.7.2.stable installed in `%APPDATA%\Godot\export_templates\4.7.2.stable\` (includes `android_debug.apk`, `android_release.apk`, `windows_release_x86_64.exe`, etc.)
  - **Android SDK / adb:** `adb` not currently detected in system PATH. Not required for M0/M1; will be configured prior to Session 3 APK build.
  - **Hardware Virtualization / Emulator Support:** CPU Virtualization Firmware Enabled is False. Physical device testing or headless APK export will be prioritized.
  - **Attached Devices:** None attached.
  - **Reachability:**
    - `https://godotengine.org` (200 OK)
    - `https://github.com` & `https://api.github.com` (200 OK)
    - `https://dl.google.com/android/repository/repository2-3.xml` (200 OK)
    - `https://repo.maven.apache.org/maven2/` (200 OK)
    - `https://services.gradle.org/distributions/` (200 OK)
    - `https://pypi.org` (200 OK)
  - **Git & GitHub Authentication:**
    - Git local user configured (`lam3y35 <moazelamey28@gmail.com>`).
    - GitHub CLI authenticated as `lam3y35` (scopes: `repo`, `read:org`, `gist`).
- **Bugs opened / closed:** None (0 opened, 0 closed).
- **Decisions and reasons:**
  - Pinned Godot 4.7.2 stable as it is installed and has matching official export templates already available locally.
  - Configured logical viewport 480×270 with `viewport` stretch mode, `gl_compatibility` renderer, nearest-neighbor texture filter, and 2D pixel snapping to adhere to the retro pixel-art aesthetic without shimmering.
  - Built a headless SceneTree test runner (`tests/test_runner.gd`) to run deterministically with `--headless --script`.
- **Changes to plan:** None.
- **Blockers:** None.
