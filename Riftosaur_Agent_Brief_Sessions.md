# Riftosaur: Autonomous Development Brief (v3, split into numbered sessions)

> **ملاحظة للمالك (بالعربي):** الملف ده فيه كل حاجة في مكان واحد. ابدأ بـ **Session 1**. انسخ للـ agent الملف كله (أو الجزء الأول + السيشن الحالي) وقوله: "نفّذ Session 1". لما يخلص ويكتب الـ Next action في WORKLOG.md، ابدأ شات جديد وقوله: "نفّذ Session 2"، وهكذا.

> **How to use this file (for the agent):**
> - **Part 1** = ground rules. They apply in every session. Read them every time.
> - **Part 2** = Sessions 1 to 12, in execution order. The owner will tell you "Execute Session N". Do only that session's scope, then stop.
> - **Part 3** = reference tables (acceptance criteria, documents, report structures).
> - Each session = one Godot milestone (or half of one). Session numbers are not milestone numbers; the mapping is in the table below.

## Session map

| Session | Contents | Milestone |
|---|---|---|
| 1 | Preflight + project setup and baseline | M0 |
| 2 | Dinosaur movement prototype (desktop) | M1 |
| 3 | Endless run loop + first Android debug APK | M2 |
| 4 | Vertical movement, platforms, springs, camera, Validator V1 | M3 |
| 5 | Skills and collectibles | M4 |
| 6 | Flight | M5 |
| 7 | Worlds and transitions | M6 |
| 8 | Procedural generation and fairness (Validator V2) | M7 |
| 9 | Screens, settings, controls, layout, audio (M8, part 1) | M8a |
| 10 | Progression, save migrations, performance, Android lifecycle (M8, part 2) | M8b |
| 11 | QA, review passes, optimization | M9 |
| 12 | Release and final handoff | M10 |

**Owner gates:** after Session 3, request owner playtest #1 (does not block Session 4). Before the publishing step of Session 12, the owner confirms repository visibility, license, GitHub account name, and package name.

---

# PART 1: Ground rules (apply at all times)

## 1.1 How this brief works

- This brief is the complete specification. Every feature is kept here.
- Everything is in scope for v1.0. Sessions set the build order. They do not remove features. A feature is built in its own session.
- There is no deadline. Quality matters more than speed.
- Do not cut scope to finish faster. If something truly cannot be completed, mark it NOT DONE with the reason in docs/RELEASE_CHECKLIST.md. Never leave a fake, hidden, or non-working feature in the build.
- Numbers marked "start" are starting points. Tune them in playtests and record the final values in the configuration resource.
- You may split or merge sessions' internal tasks. Keep the order and the exit criteria, and record every change in WORKLOG.md.
- **One session per run.** Finish the current session's exit criteria, update WORKLOG.md, commit, and stop. Do not begin the next session on your own.

## 1.2 Roles, owner, and naming

You are the whole engineering team: game designer, Godot engineer, pixel artist, animator, sound designer, Android build engineer, QA engineer, technical writer, and release manager. Handle every technical step yourself.

The product owner is not a developer. The owner wants to install the game on an Android phone, play it, share it with friends, and return to it later. Ask the owner only for:
- Decisions at gates: repository visibility, GitHub account name, license, and package name.
- Playtests on a real phone, using the checklist in docs/ANDROID_INSTALL_GUIDE_AR.md.
- Backing up the release keystore, if one is created.

Never ask the owner to send passwords, access tokens, or private keys through chat. Use only the authenticated tools the environment provides.

**Naming:** the public name is Riftosaur. In the game, repository, releases, and store text, do not use "Chrome", "Google", or "Dino Swords". Call the reference "the classic endless-runner dinosaur." The classic game and Dino Swords are design inspiration only. All skills, worlds, and art are original. (This is naming hygiene, not legal advice.)

## 1.3 Evidence levels

Every claim in code, docs, commits, and reports must state the highest level it has reached:

- **L0 Written:** code or assets exist. Nothing is verified.
- **L1 Static:** the project loads headless with no script, parse, or resource errors, and every reference resolves.
- **L2 Automated:** relevant tests ran. Record pass, fail, and skip counts, with a reason for each skip.
- **L3 Desktop play:** the behavior was exercised to its end state in a real run (scripted or manual), and logs were reviewed.
- **L4 Android build:** the APK was exported and statically verified (APK verification, Session 3 spec D).
- **L5 Device:** the APK was installed and played on a real phone or emulator, with logs captured.

Rules:
- Docs describe each feature only at the level it reached. Never call the project an installable app before an L4 APK exists.
- "Works" and "tested" always need a level and evidence.
- Screenshots prove presentation, not mechanics. Store each one with its capture date and commit.
- Do not write a guide for a control or mechanic until it reaches L3.

## 1.4 Environment rules and blocker policy

**Environment rules:**
- Pin the latest stable Godot 4.x available at project start, verified on the official site. Export templates must match the editor version exactly.
- Use official sources only. Verify checksums where published. Prefer user-scoped or project-local installs. Never run unknown executables or scripts copied from tutorials.
- Prefer Godot's default Android export, which normally does not use a custom Gradle build and needs fewer downloads. Use Gradle only when a plugin requires it or when AAB export needs it, and document why in docs/ANDROID_BUILD_GUIDE_AR.md.
- Install only what is needed. If an installation needs administrator rights, name the exact action and request only that.
- Never bypass OS or network security controls. When a download fails, read the error, record it, and check whether the environment allows that domain.
- Do not claim a tool is installed, a build succeeded, or a device was tested until you have checked it.

**Blocker policy:**
- For each blocker, record what is blocked, the exact error, what the owner must do (if anything), and what can continue.
- Keep working on every unblocked task. Retry blocked items when the environment changes.
- With no emulator or device, device tests are NOT RUN. Provide the owner checklist. Never describe the game as device-tested without evidence.
- If the same fix fails twice, log it in docs/BUG_TRACKER.md, try a different approach, and move on if other work is unblocked.

## 1.5 Code quality and architecture rules

- Small, cohesive components: player movement, movement states, hazards, skills, collectibles, generation, world themes, camera, HUD and UI, audio, persistence, and game state or run session.
- Typed GDScript where it improves reliability.
- Signals for decoupled communication. Disconnect signals and free timers and generated nodes on exit.
- Reusable scenes only for objects with genuinely shared behavior (platforms, springs, collectibles). Use data resources when a variant needs no new behavior.
- Data-driven: worlds, skills, obstacles, patterns, and tuning live in resources/. All tunable values live in one central configuration resource.
- No magic numbers in logic. No duplicated logic. No giant functions. Use composition over inheritance, and inheritance only for shared behavior.
- No unnecessary singletons. An autoload is allowed only when justified and documented (for example, the save service).
- No global mutable state beyond clearly owned services. No speculative features. No dead code.
- No third-party plugins unless justified and documented.
- Object pooling only when profiling shows a benefit.
- Handle missing resources and invalid saves gracefully, with warnings.
- Comments only where behavior is not obvious. Never restate the code. Keep functions short and readable. Avoid compressed one-liners.
- Naming: snake_case for files and functions, PascalCase for class names.
- docs/ARCHITECTURE.md records the key decisions and trade-offs.
- Test extensibility: add a test-only world and a test-only skill, and confirm that no unrelated system had to change.

## 1.6 Error-handling policy (for every bug)

1. Reproduce the failure, and save the steps or a replay.
2. Collect the log: Godot output on desktop, or `adb logcat` on a device.
3. Find the root cause.
4. Fix the cause. Do not hide the error.
5. Add a regression test that fails before the fix and passes after it.
6. Rerun the affected tests and record the results.
7. Update the documents if the behavior changed.

Never suppress exceptions, disable validation, remove checks, or mark a failing test as passing. A known failure stays in the test suite, linked to its BUG_TRACKER ID and target session.

**Bug triage:**
- **Blocker:** a crash, a state the player cannot leave, or data loss.
- **Major:** an unfair death, an unresponsive control, a wrong score or save, or an unusable layout on a supported screen.
- **Minor:** a visual glitch, unclear text, or a rare edge case with a documented workaround.
- **Cosmetic:** polish that does not affect play.

Version 1.0.0 needs zero open Blockers and zero open Majors. Minor and Cosmetic items may ship if the release notes list them. A preliminary build may list open Majors, but it must not have open Blockers.

## 1.7 Documentation principles

- Write each document when its content becomes true, not before. Never create an empty document to look complete.
- Each document states its version or commit, the verification levels it relies on, the date, and any unverified items.
- Owner-facing documents are in Arabic (Egyptian Arabic or simple Arabic). Developer-facing documents are in English. README.md includes a short Arabic summary that points to START_HERE_AR.md.
- Owner-facing documents briefly explain each technical term on first use (APK, SDK, Git repository, debug and release builds, export).
- Keep documents short. Prefer tables and numbered steps.
- Create only the files listed in Part 3 (Documents). Any extra file needs a reason recorded in WORKLOG.md. A document whose content stops being true is corrected or removed in the same session.

## 1.8 Session protocol and WORKLOG

docs/WORKLOG.md is the resume point. The project spans many sessions, so every session must leave it accurate.

**Start of every session (do this before the session's own work):**
1. Read docs/WORKLOG.md. If it does not exist, this is Session 1: create it there.
2. Check git status. Identify uncommitted changes and the unfinished step they belong to. Commit or record them before new work starts.
3. Run L1 validation and the smoke test to confirm the project still loads (not applicable before Session 1 finishes M0 setup).
4. Re-check only the environment items that the log marks as changed or unverified.
5. Confirm the Next action in the log matches the session you were told to run. If it does not, tell the owner and ask which to run.

**End of every session:**
1. Leave the project in a state the next session can validate. If it cannot be validated, record exactly what is broken and why.
2. Commit at a stable point. Tag the milestone exit (for example, `m2-complete`).
3. Update the Current state block and add a session entry.
4. Write exactly one Next action: "Execute Session N+1" plus one concrete first step.
5. Update CHANGELOG.md when a milestone exits.
6. Tell the owner (short, in Arabic): the session finished, what reached which level, anything needed from them, and the number of the next session.

**WORKLOG.md format:**
- **Current state** (top of the file, always current): session number, milestone, last commit, highest evidence level per area, open Blockers and Majors, owner actions, and the Next action.
- **Session entries** below it, newest first. Each records the date from the environment, session number, milestone, start and end commit hashes, evidence levels reached with test counts, bugs opened and closed by ID, decisions and their reasons, changes to the plan with the exit criteria affected (no feature is dropped silently), and blockers with the exact error, the owner action, and what can continue.

**Backups and evidence:**
- Before a risky change (renaming scenes, changing the save format, reorganizing folders, changing export settings), create a tag or branch.
- Keep small logs and screenshots that support a claim in docs/evidence/ (created when first used). Keep input replays in tests/replays/. Large recordings stay local and are not committed; the log records where they are.
- Do not delete a backup, tag, or evidence file until the final deliverables are verified.

## 1.9 Execution rules

- Start right after the session-start checks. Do not stop at a plan, a proposal, or pseudocode.
- Do not ask for approval for routine, reversible work inside the project folder.
- Ask only when the work truly needs account access, an elevated system permission, an external publishing action, or an irreversible action such as deleting data or rotating a key.
- Fix errors before moving on. Recheck affected systems after every change.
- Keep every decision, change, and blocker in WORKLOG.md.
- When a gate blocks a step, continue every unblocked task in the current session.
- Every session's own milestone self-review: check the session's changes against the "Pass 1" list in Session 11 spec E.

## 1.10 Gates (owner decisions and playtests)

- **After Session 3:** request owner playtest #1. This does not block Session 4.
- **Before publishing in Session 12:** the owner confirms repository visibility, license, GitHub account name, and the package name. This blocks publishing only.
- **Before Session 12:** owner final playtest, if the owner is available.
- While waiting for feedback, continue with the next session unless the feedback decides the direction.

---

# PART 2: The sessions, in order

---

## SESSION 1: Preflight and project setup (M0)

**Goal:** a project that loads, tests, and is committed.

### 1A. Preflight (first task of the first session)

Record all results in docs/WORKLOG.md:
- OS, CPU, RAM, free disk space, and graphics driver.
- Java, Android SDK, adb, emulator support (hardware virtualization), and attached devices.
- Reachability of every source you need: Godot downloads, export templates, the Android SDK host, Maven or Gradle repositories (only if a Gradle build is needed), PyPI (only if Python tools are used), and GitHub (API and push).
- Git and GitHub authentication status. Check it. Do not create or request credentials in chat.

Apply the environment rules and blocker policy (1.4).

### 1B. Setup tasks

1. Install and pin Godot and the matching export templates.
2. Create the project skeleton (structure below), local git with .gitignore, a test runner with one smoke test, README, CHANGELOG, and WORKLOG.
3. Set up the test tooling (below).

**Project structure.** Root folder `Riftosaur/`. Record its absolute path in WORKLOG.md and README.md.
- project.godot, README.md, START_HERE_AR.md, CHANGELOG.md, LICENSE, .gitignore
- scenes/: main, menus, gameplay, player, worlds, obstacles, pickups, abilities, ui
- scripts/: player, world, generation, abilities, systems, ui (mirroring scenes/)
- assets/: sprites, spritesheets, tilesets, backgrounds, effects, audio, fonts, sources (pixel-art source maps)
- resources/: world_themes, skills, obstacle_patterns, gameplay_config
- tests/: test runner, unit, integration, end-to-end, replays, fixtures
- docs/: guides, reports, and logs (Part 3)
- tools/: art and audio generation, test runners, build and verification scripts
- releases/: local APKs and checksums (git-ignored; see releases/README.md)

Create folders when they are first used. Do not create empty files to fill the structure. Never overwrite unrelated files or existing projects. Inspect before replacing anything.

**Git:**
- Ignore: .godot/, export outputs, releases/*.apk, keystores, build intermediates, and logs.
- Commit: source, scenes, resources, tests, docs, tools, and the *.import files Godot creates for assets (verify this convention for the chosen version).

**Test tooling:**
- **Validation (L1):** headless project load and import. Zero script or parse errors. All resources exist. All input actions are defined and free of conflicts. Signal connections and node paths are valid. Export settings and Android metadata are correct.
- **Test runner:** a small SceneTree-based runner in tests/, run headless (for example, with `--headless --script`). Adopt GUT or a similar framework only if the custom runner becomes a burden, and record the decision.
- Every randomized test uses a fixed seed. Every test has a name, a purpose, and an expected result.
- Never delete a failing test. Never leave an unexplained skip. A known failure links to a BUG_TRACKER ID and a target session.
- **Input replays:** record input streams with timestamps and replay them to reproduce bugs and run end-to-end sessions.
- **Regression:** every fixed bug gets a test that reproduces it.

**Documents started:** README.md, CHANGELOG.md, .gitignore, docs/WORKLOG.md.

**Exit:** L1 and L2. First commit. Next action: "Execute Session 2".

---

## SESSION 2: Dinosaur movement prototype, desktop (M1)

**Goal:** a dinosaur that looks right and feels right on a flat test track.

**Build:**
- Recognizable dinosaur sprites for idle, run, jump, fall, land, slide, dive, hurt, and death.
- Movement state machine, variable jump, jump buffer, coyote time, ground detection, slide collision shape, squash and stretch, landing dust, a simple horizontal camera, and a flat test track with ground obstacles.

### Spec A: Identity and art direction

- The dinosaur must be recognizable at a glance. Keep the classic side-facing silhouette: large head, short arms, long tail, two strong legs, a minimal body, and a familiar running rhythm. Create an original rendition. Do not replace it with another creature, a mascot, or a human.
- All art is pixel art. No smooth vector art, blurred sprites, mismatched painted backgrounds, or 3D characters.
- The dinosaur's core silhouette stays the same in every world. Worlds may change palette, lighting, particles, and small accents.
- Logical viewport: 480×270 pixels (the "logical pixel" grid used throughout this brief). Use nearest-neighbor filtering. Snap sprites and the camera to whole logical pixels. Prefer integer scaling. Avoid fractional scaling, which shimmers.

**Measurable art rules:**
- Dinosaur frame cell: 32×32 px, body about 30×24 px, the same in every world.
- Tiles: 16×16 px.
- Palette: one palette per world with 12 to 16 colors, plus one UI palette of up to 16 colors. The UI uses the same pixel-art language.
- Outlines: 1 px dark outline on characters, hazards, and pickups. No anti-aliasing on outlines or edges.
- Parallax: 3 to 4 layers per world, plus ground.
- Effects: dust, spark, and shockwave effects are 4 frames each. Global cap: 64 active particles. Per-effect cap: 12.
- Readability: every hazard and pickup must read as a solid black silhouette at 1× and 3×, and must not depend on color alone.

**Animation frames (minimum; add frames only when quality needs them):**

| Animation | Minimum frames | Built in |
|---|---|---|
| Idle | 2 | Session 2 |
| Run (synced to speed) | 6 | Session 2 |
| Jump: rise / apex / fall | 1 / 1 / 1 | Session 2 |
| Land (squash) | 2 | Session 2 |
| Slide or duck | 2 | Session 2 |
| Dive and drop-through | 2 each | Session 2 (drop-through behavior in Session 4) |
| Hurt | 2 | Session 2 |
| Death | 6 | Session 2 |
| Air dash | 2, plus a streak overlay | Session 5 |
| Flight (wing or tail beat) | 4 | Session 6 |
| Collect | 3 | Session 5 |
| Respawn | 4 | Session 9 (or earlier if needed) |
| Skill attack (per skill) | 2 actor frames + 3 to 4 effect frames | Session 5 |
| Pickup and hazard loops | 4 | the session that adds them |

**Asset provenance:**
- Original art: the dinosaur, all skill icons and effects, world-specific obstacles and pickups, and the main UI icons.
- External assets are allowed for generic tiles and background filler (CC0 or equivalent) and for fonts (SIL OFL or equivalent). Record each one in docs/ASSET_LICENSES.md: name, author, source URL, license, files used, and any modifications.
- Do not use an asset whose license is unclear.
- Generate pixel art from source maps (text or palette-index grids) kept in assets/sources/ and converted to PNG by scripts in tools/. Inspect each sprite sheet at enlarged scale before accepting it.
- Placeholder art is allowed during development. Log it in WORKLOG.md and remove it before the session that claims the feature.

### Spec B: Core pacing (needed for the test track)

- The dinosaur runs forward automatically. The player controls jumping, sliding, falling, diving, skills, flight, and route choice.
- Opening speed: about 80% of the classic opening pace. The classic game starts at about 6 px per frame at 60 fps, so start near 290 logical px/s. Increase speed on a configured curve up to a cap (start near 1.6× the opening speed). Difficulty rises through pattern complexity, not speed alone.
- Reaction window: every hazard must be visible for at least 1.0 s before contact at the speed where it first appears.
- Vary elevation, routes, rewards, and modifiers. Include recoverable mistakes where the design allows.
- The game must stay enjoyable without any power-ups.

### Spec C: Movement

**Jump:**
- Hold-based strength only. Never depend on touch pressure, which varies by device.
- Immediate impulse on press. Holding extends the rise up to a maximum hold time. Releasing early cuts upward velocity by a configured factor.
- Consistent gravity. Maximum height and airtime are capped. Holding forever cannot raise the jump further.
- Start values: maximum height about 84 logical px (reached at maximum hold, about 0.35 s); tap height about 30 px; coyote time 0.10 to 0.12 s; jump buffer 0.12 s.
- Capture press events in a buffer so no press is lost between physics ticks. Measure buffer and coyote windows in physics time, not frame counts.
- Coyote time allows a jump shortly after leaving a ledge. It never allows unintended mid-air jumps.
- The jump buffer stores a press shortly before landing and executes it on landing.

**Movement system:**
- An explicit state machine: run, idle, slide, jump rise, apex, fall, land, dive, drop-through, air dash, flight, hurt, dead, respawn. Incompatible states never overlap (for example, slide, attack, and death together). Implement the full state list structure now; fill in later states as their sessions arrive.
- Smooth acceleration, controlled deceleration, and a subtle forward lean when accelerating or dashing.
- Squash on landing, stretch on takeoff, and a small dust puff on landing.
- Air dash: a short burst in the air. The movement system provides the dash, and the Air Dash skill (Session 5) makes it available with limited charges. Charges refill on landing.
- Dive: controlled downward movement in the air. Not available on the ground.
- Collision shapes for standing, jumping, and sliding. Shape changes must not clip into solids.
- Interrupts: being hit mid-jump, landing as an ability expires, or pausing during any state must resolve to a valid state. Animations never lock the player longer than their own duration. No stuck inputs.
- Movement runs in the physics tick. The same inputs produce the same movement at any frame rate.

**Camera (this session's part):** scrolls horizontally, with the dinosaur in the left third of the view.

### Tests (required coverage, movement)

Normal jumps; short hop versus held jump; maximum height; hold cap; buffer timing; coyote timing and no unintended mid-air jumps; ground detection; slide and standing recovery; no falling through solid ground; interrupted state transitions.

**Documents started:** docs/DEVELOPER_GUIDE.md, docs/ARCHITECTURE.md. Add docs/ASSET_LICENSES.md with the first external asset.

**Exit:** L2 for movement tests and L3 for a run of at least two minutes with logs reviewed. Next action: "Execute Session 3".

---

## SESSION 3: Endless run loop and first Android build (M2)

**Goal:** a complete (simple) run loop, and the first installable debug APK.

**Build:**
- Hand-authored ground-obstacle chunks, distance and score, death, instant retry, pause and resume, versioned save with best score, basic HUD, touch controls (tap and hold to jump, swipe down, pause), keyboard map, and the Android debug APK.

### Spec A: Persistence

- A versioned save file (version 1 at first) stores best scores, settings, unlocks, and mission progress.
- Atomic writes: write a temporary file, verify it, then replace the old file. Keep the last good copy as a backup.
- Invalid or missing data: use defaults, keep a copy of the bad file for debugging, log a warning, and never crash.
- Save at meaningful events (game over, settings change, unlock), not every frame.
- Storage errors: keep the game running and show a short message.
- Migrations for future versions, with tests (add by Session 10).

### Spec B: Basic controls and HUD

**Touch controls:**
- Jump: tap and hold in the jump zone, a large area on one side of the screen.
- Swipe down: slide (drop through and dive are added in Session 4).
- Pause: a small corner button outside gesture zones.
- Accidental actions are prevented: swipes need a minimum distance and speed, touch zones do not overlap, pause and restart require taps on visible buttons, and gestures never pause or restart a run.
- Multi-touch: track each touch separately. Conflicting commands resolve predictably.
- Touch targets are at least 48 dp. Essential controls stay out of Android system gesture areas.

**Keyboard (desktop; documented in README and the gameplay guide):** Space or Up to jump (hold for height). Down to slide, drop through, or dive. X or Shift for the skill. Up and Down for flight. Esc or P to pause. R to retry from game over.

**Game over (basic):** score, distance, best score, a short cause label (for example, "Hit by cactus"), and a one-tap retry. Retry takes no more than 1 s.

**HUD (basic):** score, distance, best score. (More HUD items are added with their features.)

### Spec C: Android toolchain and export

**Toolchain:**
- Godot editor (pinned) and matching export templates.
- The Java Development Kit version named in the official Godot docs for the chosen release.
- Android SDK: command-line tools, platform-tools (adb), build-tools (aapt2, apksigner, zipalign), and the platform package for the target API. Accept licenses through the official SDK tool.
- Set the SDK and JDK paths in Godot's editor settings. Set environment variables and export presets as the official docs require.
- Debug keystore: generated according to the official docs. Never committed.
- Record every version in WORKLOG.md and docs/ANDROID_BUILD_GUIDE_AR.md.

**Export presets and settings:**
- "Android Debug" preset produces the debug APK. ("Android Release" is added in Session 12.)
- Package name: `com.riftosaur.game` by default. Early builds use it. Confirm it with the owner before the first release build (Session 12). Changing it after release breaks updates.
- Version code increases with every build. Version name is 0.x.y while the build is preliminary. Use 1.0.0 only when the release rules allow it (Session 12).
- Minimum and target SDK: use the values the chosen Godot template supports, and check them against current requirements. Record both.
- Landscape orientation lock.
- Pixel-art app icon at every required size, generated by tools/.
- Permissions: only what the build uses (see Android lifecycle, Session 10).

### Spec D: APK verification (run for EVERY APK; record the outputs)

1. The file exists and is not empty. Record its size and SHA-256 checksum.
2. Metadata: `aapt2 dump badging` shows the package name, version code and name, minimum and target SDK, launch activity, permissions, and native architectures. Include arm64-v8a for modern phones.
3. Alignment: `zipalign -c -v 4`.
4. Signature: `apksigner verify --print-certs`.
5. Contents: all required scenes, assets, and configuration are present (spot-check the archive listing).
6. Install and launch on an emulator or device: `adb install -r`, launch the app, then review `adb logcat` for errors.
7. Offline check in airplane mode.
8. Test every command before documenting it, and record the tool versions.

Steps 1 to 5 count as L4. Steps 6 and 7 count as L5, and they run only when an emulator or device is available.

**Outputs:** debug APK from this session onward. Put APKs and checksums in releases/ and describe them in releases/README.md.

### Documents for this session

- **docs/ANDROID_INSTALL_GUIDE_AR.md** (Arabic), written with the first debug APK. It starts with the simplest method, with no terminal: where to get the APK, how to transfer it if needed, how to open it, how to allow installation from that one source when Android asks, and how to launch the game. It covers blocked installs, incompatible devices, Play Protect warnings (check the SHA-256 before continuing), and conflicts with an older build. Debug and release builds are signed with different keys, and two debug builds made on different computers can also differ, so Android may refuse an update. The guide states that switching requires uninstalling first, which deletes local save data. It never asks the owner to lower device security globally. It also covers uninstalling, bug reports (phone model, Android version, what you did just before the problem, and a screenshot), and the owner playtest checklist: install, launch, one full run to game over, one retry, pause and resume, sound and vibration toggles, then report. The ADB method goes in a separate advanced section.
- **docs/ANDROID_BUILD_GUIDE_AR.md** (Arabic): started now, finished in Session 12 (details in Part 3).
- **START_HERE_AR.md** (Arabic): started now (details in Part 3).
- **releases/README.md** (English): describes the local release folder, file naming, and checksums.
- **docs/TEST_REPORT.md** (English): started now, updated every session.

**Exit:** L3 for a full run to game over and a retry, L4 for the APK, and L5 if an emulator or device is available. Otherwise, request owner playtest #1 (does not block Session 4). Next action: "Execute Session 4".

---

## SESSION 4: Vertical movement and platforms (M3)

**Goal:** the game gains height: platforms, bounces, and a vertical camera, plus the first fairness validator.

### Spec A: Platforms

- Multiple heights. Solid and one-way platforms look different.
- One-way platforms: land from above, pass through from below, and drop through with the down input while standing on them. Solid terrain is never passable.
- Landing is reliable: no falling through solid tops and no snagging on edges.
- Safe descents lead to lower routes and the ground.
- Optional elevated routes contain valuable items. They carry more risk, so they are real choices.

### Spec B: Spring and boost objects (all required)

- Spring-loaded tree stumps, bouncing mushrooms, collapsible crates, elastic branches, ancient stone launch pads, wind vents, and breakable obstacles that reveal an upward route.
- Each object has readable states (idle, compressed, launching, cooldown) and one consistent launch profile.
- Bounce chains: patterns where the dinosaur bounces between objects and jumps again from height.
- A launch never sends the dinosaur into an unavoidable hazard or outside the playable area.

### Spec C: Contextual descent (down input)

- On the ground: slide or duck.
- On a one-way platform: drop through.
- In the air: dive.
- In flight: gradual descent, never a grounded action (built in Session 6).
- Each action has its own animation.

### Spec D: Full camera

- Scrolls horizontally, with the dinosaur in the left third of the view.
- Tracks vertically with adjustable easing and dead zone. Look-ahead is limited to the direction of travel. Camera bounds apply per designed area.
- Smooth transitions between areas. No abrupt snaps.
- No shake during normal movement. A small impact shake on significant events is optional, and reduce-motion turns it off.
- The camera never hides upcoming hazards or makes landings hard to judge.

### Spec E: Validator V1 (analytic)

For each gap, rise, and bounce connection, check the physics configuration at the pattern's maximum speed:
- Required horizontal distance must be at most 80% of maximum reach.
- Required rise must be at most 80% of maximum jump rise.
- The reaction window must meet the minimum.
- Example: at opening speed with full hold, maximum reach is about 200 px, so a gap must be at most 160 px.

### Tests

Drop-through one-way platforms; landing on elevated platforms; bounce launch; camera tracking and bounds; V1 on all hand-authored patterns; movement with real collision shapes; jumps onto platforms and interactive objects.

**Exit:** L2 for platform, one-way, bounce, and camera tests, and L3 for a platform route. Next action: "Execute Session 5".

---

## SESSION 5: Skills and collectibles (M4)

**Goal:** a single skill slot with eight working skills.

**Build:** collectibles, skill pickups, the single active skill slot, the eight skills, the air dash mechanic with its skill, hazard categories, charges, cooldowns, replacement notices, the skill HUD, and the dedicated skill button. Build the Air dash, Collect, and Skill attack animations from the animation table (Session 2).

### Spec A: Skill system

- One active skill slot, activated by one dedicated control. Durations, charges, and cooldowns come from configuration.
- Each skill has an original icon and visual identity.
- Collecting a usable skill equips it with clear feedback. If it replaces the current skill, show a replacement notice.
- The HUD shows the current skill and its remaining duration, charges, or cooldown. Also add the collectible count to the HUD.
- A skill is disabled when it is invalid, on cooldown, or unavailable. Charges are consumed only when activation actually happens.
- Pickup, activation, expiry, and replacement update the UI immediately.
- Keep on-screen buttons to a minimum. The skill button is large, visible, and away from screen edges. A jump hold and a skill tap must work at the same time (multi-touch).
- Air-dash control: only if needed for usability.

### Spec B: Hazard categories (defined in configuration)

- Solid: rock walls and similar terrain. No skill removes it.
- Breakable: barriers and crates.
- Airborne: birds and flying hazards.
- Crawler: ground enemies.
- Projectile: thrown or fired hazards.
- Environmental: lava, pits, ice hazards, and crushers. No skill removes them. Only movement avoids them.

### Spec C: The eight skills (names and art are original; start values are tunable)

| Skill | What it does and what it affects | Start values |
|---|---|---|
| Bone Blade | Short forward attack. Destroys Breakable hazards. | 0.3 s attack, 0.5 s cooldown |
| Boomerang | Travels forward and returns. Hits Airborne and Crawler hazards on its route. | One at a time, 1.2 s cooldown |
| Stone Shield | Blocks one hit from an Airborne, Crawler, or Projectile hazard, then breaks. Never blocks Solid or Environmental hazards. | Until used |
| Ground Slam | Triggered in the air. The landing shockwave destroys Breakable and Crawler hazards in its radius. | 2 s cooldown |
| Time Shard | Slows Airborne, Projectile, and moving hazards. The player keeps full control response. | 4 s at 50% speed |
| Magnet Relic | Pulls nearby collectibles toward the dinosaur. No hazard effect. | 6 s |
| Air Dash | Gives the movement dash two charges. Charges refill on landing. | 0.18 s dash, 0.6 s cooldown |
| Bounce Power | Springs launch higher. Mushrooms and launch pads launch the dinosaur on landing. | 8 s |

### Tests

Skill collection, replacement, activation, charges, and cooldowns; valid and invalid target categories for each skill; collectible rewards; air-dash limits and cooldowns; skill effects on compatible and incompatible hazards; UI updates on skill events; repeated skill attempts during cooldown.

**Exit:** L2 for skill tests, L3 with each skill used in a real run, and an L4 rebuild. Next action: "Execute Session 6".

---

## SESSION 6: Flight (M5)

**Goal:** flight pickups and flight routes that are fun and safe to exit.

### Spec

- At least two flight pickups with different feel. Example: Mechanical Wings (steady lift and gliding) and Rocket Relic (strong thrust with a cost). An anti-gravity artifact is optional.
- Vertical control with up and down input (buttons, drag, or keyboard). Horizontal progress stays automatic. Up and down flight controls are shown only during flight.
- Flight routes include flight-compatible collectibles and obstacles. Flight must not make hazards irrelevant.
- In flight, the down input gives gradual descent, never a grounded action.
- Show a duration indicator (HUD flight timer, during flight only). Warn about 2 s before expiry (configurable). Return to normal physics gradually, with no sudden drop, and support landing.
- Flight sequences are fewer than running, jumping, sliding, and falling sequences.
- Flight animation: 4 frames minimum.

### Tests

Flight movement and expiry; flight pickup, flight, expiry, and landing (integration); pause and resume while timers are active.

**Exit:** L2 and L3 (flight replay covering the warning, expiry, and landing). Next action: "Execute Session 7".

---

## SESSION 7: Worlds and transitions (M6)

**Goal:** four visibly and mechanically different worlds, driven by data.

### Spec A: Theme system

- Each world is a configuration resource that defines: palette, background and parallax layers, ground tiles and platforms, obstacle families, collectible looks, environmental particles, animation variations, an ambient sound set, one or more gameplay modifiers, obstacle patterns, a difficulty range, and transition rules.
- Adding a theme must not require changes to the player controller.
- Design for future themes, such as a low-gravity lunar world or a mechanical arcade world. Do not build them now.

### Spec B: Four worlds (required at launch)

- **A, Classic Prehistoric Plains:** clear silhouettes, cactus hazards, birds at three heights, rocky terrain, and simple patterns for learning. Baseline modifier.
- **B, Overgrown Jungle:** dense vegetation with sway animation, trees, vines, and branches; elevated canopy paths; bounce mushrooms; breakable barriers that reveal routes; elevated rewards. Modifier: canopy routes with more pickups.
- **C, Frozen Ruins:** icy platforms; slippery segments telegraphed before control changes; frozen barriers; icicle drops; frost particles. Modifier: slippery surfaces only inside marked ice zones.
- **D, Volcanic Underworld:** dark rock; lava (Environmental); embers; glowing hazards; moving hazards (rising lava blobs, rolling boulders); moving platforms; advanced platform patterns; warnings about one second before dangerous changes. Modifier: eruption warnings and moving platforms.

Every world includes animated vegetation or ambient motion, environmental particles, and subtle screen effects, all within the caps in the art rules (Session 2) and the performance rules (Session 10).

### Spec C: Transitions

- Triggered after a configured distance. Start with about one minute of running per world (roughly 15,000 to 20,000 logical px at opening speed).
- The transition zone has no hazards and a safe landing area. The palette and background cross-fade over about 1.5 s. Ground, platforms, particles, ambient sound, and the world-name card change. A one-line introduction explains any new mechanic.
- Never change the fundamental physics during a jump. Modifiers apply only while the dinosaur is grounded or inside a marked safe zone.
- Every world has its own obstacles and patterns. Recoloring the same obstacles does not make a new world.
- HUD: add the world name and a transition indicator.

### Tests

World transitions (including during movement and near hazards); theme validation; extensibility test (a test-only world added with no unrelated system changing).

**Exit:** L2 for transition and extensibility tests, L3 for a run through all four worlds, and an L4 rebuild. Next action: "Execute Session 8".

---

## SESSION 8: Procedural generation and fairness (M7)

**Goal:** endless, fair, reproducible levels.

### Spec A: Generation

- Reusable chunks, about one screen wide (480 px) or two (960 px). Each chunk has entry and exit connectors (height and surface type) that must match its neighbors.
- Generate ahead of the camera. Free or recycle chunks behind it.
- Deterministic seeds: every run's seed is logged and shown in the developer overlay. The same seed produces the same run.
- Pattern library: hand-authored pattern resources tagged with world, difficulty band, required movement (run and jump, slide, dive, bounce, flight), and speed range. Randomization selects and varies patterns from this library.
- Route classes: safe, challenging, and optional-reward. Mark them in data and show them visually.
- Difficulty bands: five bands, each with a speed range and allowed tags. Band 1 is for teaching.

### Spec B: Hard rules

- No overlapping hazards.
- No unavoidable sequences.
- No pattern that needs a skill unless a route without that skill exists.
- Platforms, flight routes, pickups, and world transitions follow the same rules.
- Transitions into and out of special zones are safe.

### Spec C: Validator V2 (simulated)

- Run each pattern headless with a deterministic reference controller. It uses only allowed inputs, a realistic reaction delay (start at 0.25 s), and maximum speed.
- A pattern passes if the reference path completes it without collision. Fix or remove failing patterns.
- Output a validator report with counts per world and band, failures, and exclusions. Store it in tests/ and summarize it in TEST_REPORT.md.

### Tests

Chunk generation and cleanup; chunk generation with camera movement; pattern fairness (V1 and V2); long-run stability.

**Exit:** L2 for generation tests, L3 for a ten-minute headless run with recorded memory and node counts, and a validator report with zero failures or documented exclusions. Next action: "Execute Session 9".

---

## SESSION 9: Screens, settings, controls, layout, and audio (M8, part 1)

**Goal:** every screen, setting, final control layout, and sound.

### Spec A: Screens

Main menu, Play, tutorial, pause and resume, restart, game over, settings, credits and asset acknowledgments, practice mode entry, missions and challenges screen, and cosmetics screen. (The logic behind practice mode, missions, and cosmetics is built in Session 10; build the screens and navigation now, and do not ship a screen that does nothing. If a screen's logic is not ready by the end of this session, keep it out of the build until Session 10.)

- **Game over:** score, distance, best score, a short cause label, and a one-tap retry (max 1 s).
- **HUD (complete):** score, distance, best score, collectible count, equipped skill icon with charges or cooldown, flight timer (during flight only), world name, and transition indicator. Readable on a phone.
- **Tutorial:** short and interactive, about five steps: run, hold to jump, slide, collect a skill, and use a skill. Skippable and replayable.

### Spec B: Settings and accessibility

- Sound effects on or off. Vibration on or off. The two toggles are independent. Master volume.
- Accessibility: reduce motion (no shake, fewer particles), high-contrast hazard outlines, text size, left- or right-handed control layout, and an optional auto-hold jump.

### Spec C: Controls and layout (final)

- Final touch layout: jump zone, swipe down (slide, drop through, or dive by context), large skill button, flight up and down controls (during flight only), pause in a corner outside gesture zones.
- Multi-touch: a jump hold, a skill tap, and a pause tap must work together without conflict.
- Layout checks: test 16:9, 19.5:9, 20:9, and 4:3 tablet layouts in landscape. No stretched pixel art. No essential gameplay hidden under controls. The HUD stays inside safe margins.
- A developer-only overlay shows the seed, speed, state, and FPS. It is disabled in release builds.

### Spec D: Audio and feedback

- Required sound effects: jump, land, slide, air dash, collect, skill activation, breaking obstacles, entering a world, flight start and end, damage, and game over. Optional: pickup, skill replacement, spring launch, and warnings.
- Sounds are original or appropriately licensed. Generate them with an sfxr-style tool or synthesize them in code. Keep each effect under about 0.6 s, with peaks around -6 dBFS. Provide a master volume and a sound-effects toggle.
- Vibration is used for a few significant events only: a hard landing, damage, game over, and skill activation. It has its own toggle.
- Every important event has visual feedback. Never rely on sound alone.
- No excessive particles, flashing, long freezes (hit-stop at most 60 ms), or constant shake.
- Background music is optional. If included, it must be original or licensed and have its own toggle.

### Tests

Every button on every screen performs its action; touch controls do not overlap critical UI; gestures cannot restart or pause a run by accident; the UI fits common landscape resolutions; no clipped or unreadable text; settings persist and take effect.

**Documents:** write each part of docs/GAMEPLAY_GUIDE_AR.md as its mechanic reaches L3.

**Exit:** L2 and L3 for every screen and button built so far, and an L4 rebuild. Next action: "Execute Session 10".

---

## SESSION 10: Progression, save migrations, performance, and Android lifecycle (M8, part 2)

**Goal:** replayability, durable saves, stable performance, and correct Android behavior.

### Spec A: Progression and replayability

- Local best score and best distance.
- Persistent settings.
- Cosmetic unlocks: palette variants of the dinosaur that keep the silhouette, earned through milestones or collectibles. No purchases.
- Simple missions and milestones, for example: collect a set number of items in one run, break a set number of barriers, or reach a world.
- Optional mastery challenges, for example: clear a flight route without touching the ground, or complete a bounce chain without landing on the ground.
- Practice mode: slower start (about 70% speed), longer coyote and buffer windows (1.5×), and one free hit. Practice runs never update best scores.
- Risk and reward: elevated routes and optional pickups give more reward than safe routes.
- Difficulty rises gradually through the pattern bands.
- Retries are immediate. No ads, energy limits, economy, pay-to-win mechanics, login, analytics, or online features.
- Save migrations for future versions, with tests.

### Spec B: Performance and Android lifecycle

- Target 60 FPS on test hardware where possible. Movement uses the fixed physics tick.
- Cap nodes and particles. Free or recycle off-screen objects. Avoid per-frame allocations in hot paths.
- Over a ten-minute run, node count, object count, orphan-node count, and static memory must level off. Record them with the engine's performance monitors. Profile before optimizing, and record the bottlenecks you find.
- **Android lifecycle:** on pause or focus loss, auto-pause gameplay, release held inputs, and stop ability timers. On resume, stay paused until the player chooses to continue. Avoid duplicate timers.
- **Android back button:** pauses a run and goes back one level in menus. It never silently ends a run.
- **Permissions:** the minimum. The release APK has no INTERNET permission. VIBRATE only if vibration ships. Verify both in the built APK.
- **Offline:** the game launches and plays in airplane mode. No login, analytics, or ads.

### Tests

State is correct after pause and resume; the app launches without missing resources; progress survives restarts; score calculation; save and load; persistence of score, settings, and unlocks; corrupted save handling; migrations; practice mode does not update best scores; missions and unlocks trigger correctly.

**Documents:** continue docs/GAMEPLAY_GUIDE_AR.md as mechanics reach L3.

**Exit:** L2 and L3 for every screen and button, and an L4 rebuild. Next action: "Execute Session 11".

---

## SESSION 11: QA, review, and optimization (M9)

**Goal:** prove everything, find what is wrong, fix it.

### Spec A: Full test matrix

**Movement:** normal jumps; short hop versus held jump; maximum height; hold cap; buffer timing; coyote timing and no unintended mid-air jumps; ground detection; slide and standing recovery; drop-through one-way platforms; no falling through solid ground; landing on elevated platforms; bounce launch; air-dash limits and cooldowns; flight movement and expiry; interrupted state transitions.

**Gameplay:** skill collection, replacement, activation, charges, and cooldowns; valid and invalid target categories for each skill; collectible rewards; death and immediate retry; pause and resume; score calculation; save and load; world transitions; chunk generation and cleanup; pattern fairness (V1 and V2); camera tracking and bounds.

**Android and UI:** every button performs its action (check each screen); touch controls do not overlap critical UI; gestures cannot restart or pause a run by accident; the UI fits common landscape resolutions; no clipped or unreadable text; state is correct after pause and resume; the app launches without missing resources; progress survives restarts.

**Integration:** movement with real collision shapes; jumps onto platforms and interactive objects; skill effects on compatible and incompatible hazards; flight pickup, flight, expiry, and landing; chunk generation with camera movement; transitions during movement and near hazards; UI updates on skill events; persistence of score, settings, and unlocks; pause and resume while timers are active.

**Regression:** every fixed bug has a test that reproduces it.

### Spec B: End-to-end scenarios (scripted or manual, logged)

- A normal playthrough to game over.
- Rapid retries: at least 20 in a row.
- A long run: at least 10 minutes of simulated time with a fixed seed.
- Fast, repeated jumps and taps.
- Simultaneous touches: jump hold, skill tap, and pause tap.
- Repeated skill attempts during cooldown.
- Frequent world transitions, using a seed that reaches all four worlds.
- Valid unusual movement: diving into drop-through, and bounce chains.
- Pause and resume during animations and active abilities.
- Repeated save and load cycles.
- A corrupted save file, and read-only storage where feasible.
- Android background and reopen, on a device or emulator when available.

### Spec C: Performance checks

- Frame times during a two-minute desktop run.
- Memory, node, object, and orphan-node counts over a ten-minute run.
- Startup and restart times.
- Stutter checks during transitions.
- Text legibility at each supported layout.

Record the hardware and results in TEST_REPORT.md. If no device is available, say so.

### Spec D: Play it as a player

Play in sessions and record the answers in TEST_REPORT.md:
- Is the dinosaur recognizable immediately? Is the pixel art sharp?
- Are the controls easy to learn? Do jumps feel responsive and predictable?
- Can you land on platforms reliably? Can you descend when you intend to?
- Are skills clear and useful? Do the worlds feel distinct?
- Are obstacles fair? Can you explain each death?
- Is retry fast? Is the HUD readable on a phone?
- Do effects hide hazards? Do the sound and vibration settings work?
- Is the game engaging across several runs without power-ups?

Turn each finding into a bug or a tuning item.

### Spec E: Two review passes

Each earlier session's exit included a short self-review of its own changes against Pass 1. This session runs both full passes.

**Pass 1: correctness and reliability.** Look for:
- Movement faults: wrong jump heights, buffer or coyote errors, conflicting states, and collision edge cases.
- Timing faults: cooldowns or charges that behave incorrectly, and timers that survive pause, expiry, or retry.
- Generation faults: unfair or overlapping patterns, connector mismatches, and cleanup leaks.
- Save faults: unsafe writes, unhandled bad saves, and missing migrations.
- Android faults: pause, focus loss, back-button handling, stuck inputs, and duplicate timers.
- UI faults: buttons that do nothing, clipped text, and gesture conflicts.
- Resource faults: missing or unreferenced assets and broken paths.
- Export-only faults: behavior that differs between the editor and the exported build.

Fix each finding, then rerun the affected tests.

**Pass 2: architecture and maintainability.** Look for duplicated logic, dead or unused code, unnecessary abstractions, oversized functions, inconsistent names, values that belong in configuration, unnecessary global state, unneeded dependencies, repeated calculations, weak error handling, fragile paths, out-of-date documents, and behavior that differs between desktop and Android.

Simplify only where it improves correctness, testability, or maintainability. Do not shorten code merely to reduce the line count. Remove dead code only after a search and the tests confirm that nothing uses it. Follow every refactor with regression tests. Do not start a risky rewrite at the end of the project.

### Spec F: Triage and acceptance

- Triage all bugs (1.6). Resolve all Blockers and Majors before 1.0.0.
- Check every acceptance criterion (Part 3, table 3.1) and record its level and evidence.
- Complete docs/TEST_REPORT.md (structure in 3.3) and start docs/RELEASE_CHECKLIST.md.
- Update all documentation to the verified state.

**Exit:** every acceptance criterion has a level and evidence, and TEST_REPORT.md is complete. Next action: "Execute Session 12" (owner final playtest first, if available).

---

## SESSION 12: Release and final handoff (M10)

**Goal:** a verified release APK, a published repository and release, and the final handoff.

### Task order

1. **Owner gate:** ask the owner to confirm repository visibility, license, GitHub account name, and package name. Until then, all work stays committed locally.
2. **Create the release keystore** (see signing rules below).
3. **Build the Android Release preset**, signed with the release keystore. Run the full APK verification (Session 3 spec D).
4. **AAB (optional):** only after the APK is verified, and only if the export path supports it. AAB export generally requires the Gradle build path, so check the official docs for the chosen version. If it is blocked, mark it NOT RUN with the reason. Friends need the APK. The AAB is only for Google Play.
5. **Add LICENSE** (default for code: MIT; assets follow docs/ASSET_LICENSES.md).
6. **Finalize documents:** START_HERE_AR.md, ANDROID_BUILD_GUIDE_AR.md, TROUBLESHOOTING_AR.md, RELEASE_CHECKLIST.md, CHANGELOG.md.
7. **Run the pre-push checklist, create the repository, push, create the GitHub Release, and create the source ZIP** (below).
8. **Write the final handoff to the owner.**

### Signing and keystore

- Create the release keystore when the release build is first needed (this session at the latest). Use a strong password. Store the file outside the repository, in a location the owner chooses.
- START_HERE_AR.md records the keystore's location and a reminder to back it up. Never record the password in any file.
- Passwords come from environment variables or a local, git-ignored file.
- START_HERE_AR.md and ANDROID_BUILD_GUIDE_AR.md must state clearly that losing the keystore means future updates cannot install over existing installs.
- Never commit *.jks, *.keystore, or credential files. Scan before every push.

### GitHub: access and repository

- Use only the GitHub access the environment provides, and check it during preflight. If access is missing, record the exact error and the owner action needed, then continue other work.
- Never create, request, print, or store tokens, passwords, or keys in the repository, the documents, or the chat.
- Proposed repository name: `riftosaur-pixel-adventure`. Confirm it at the gate.
- Before creating or pushing, check whether a repository with that name already exists. If it does, inspect it. Do not overwrite it, force-push to it, or merge unrelated history without an owner decision. If needed, choose another name and ask.
- Use `main` as the default branch. Commit each coherent change separately, and tag each milestone exit (for example, `m2-complete`).
- Commit messages describe the change and never claim that tests passed. Test results belong in TEST_REPORT.md, tied to a commit hash.

### Pre-push checklist (every push)

1. Read the list of staged files. Nothing generated is staged: no `.godot/`, APKs, build intermediates, or logs.
2. Scan for secrets: keystores (`*.jks`, `*.keystore`), credential or environment files, tokens, passwords, and private keys. Use a secret scanner from an official source if one is available. Otherwise, run pattern searches and review every hit by hand.
3. Scan for personal data: contact details, device identifiers, and personal names inside local paths. Replace any personal name with a placeholder and note the change in WORKLOG.md.
4. Check that every asset in docs/ASSET_LICENSES.md has its license and attribution. Remove any asset whose license is unclear.
5. Check that README.md, START_HERE_AR.md, and CHANGELOG.md describe only the verified state.
6. Run validation and the test suite, and record the counts in WORKLOG.md.

### GitHub Release

- Create a release only when the APK has passed the static checks (Session 3 spec D, steps 1 to 5) for the exact commit, and its SHA-256 and size are recorded in releases/README.md.
- Preliminary builds use `v0.x.y`, matching the APK version name. Use `v1.0.0` only when every acceptance criterion is PASS and the bug rule (1.6) holds. A preliminary release may attach a debug APK, but its notes must say it is a debug build, and it must never be presented as the final release build.
- Attach the exact APK, and put its SHA-256 in the release notes. After upload, download the asset again and compare the hash. If the hashes differ, do not replace the asset quietly. Publish a new version instead.
- Release notes include: a short description of the game; download and install steps (linking docs/ANDROID_INSTALL_GUIDE_AR.md); the permissions from the APK metadata; the Android versions and devices actually tested, with emulators and physical devices listed separately; the evidence level for each feature; known limitations and open bugs, linked to BUG_TRACKER.md; and the commit the build came from.
- Do not describe a release as available until you have verified it: fetch the release URL and confirm the asset downloads. If that cannot be verified, the handoff says "unverified".

### Source ZIP

- Create it from the tagged commit with `git archive`, so only tracked files are included. Name it `Riftosaur-source-<version>.zip`, and attach it to the release.
- It must contain every asset, source map, configuration resource, test, tool, and manifest needed to rebuild the game. It must exclude `.godot/`, APKs, keystores, logs, and caches.
- Run the pre-push checks on the ZIP, and record its size and SHA-256.
- Test it: extract it into an empty folder, open the project in the pinned Godot version, and run validation (L1) and the test suite (L2). Record the results.

### If publishing is blocked

Keep the source ZIP, the APK, and the checksums in `releases/`. Record in START_HERE_AR.md what is missing and the one owner action that unblocks it. Continue all other work.

### Final handoff to the owner (the last thing you write)

Write it in Arabic, briefly and practically.
- No code and no terminal logs.
- Give exact locations and links, and verify each one before writing it. If a link is not verified, say so.
- Do not claim device testing that did not happen, and do not claim the game is bug-free.
- Never ask the owner to search for files.

Use this structure:

1. **العب اللعبة:** [رابط الـ APK المتحقق منه أو المسار المحلي، مع الـ SHA-256 وحجم الملف]
2. **شارك مع أصدقائك:** [رابط صفحة الـ Release، لو اتنشرت واتأكدت منها]
3. **الكود المصدري:** [رابط الريبو وملف الـ ZIP]
4. **التثبيت على الموبايل:** [docs/ANDROID_INSTALL_GUIDE_AR.md]
5. **فهم المشروع:** [START_HERE_AR.md]
6. **إعادة البناء لاحقاً:** [docs/ANDROID_BUILD_GUIDE_AR.md]
7. **حالة الجودة:** [أعلى مستوى تحقق لكل جزء، وأهم القيود المعروفة، وما لم يُختبر]
8. **المطلوب منك:** [أصغر خطوة ممكنة، مثلاً تجربة اللعبة على موبايلك باستخدام قائمة الاختبار، وحفظ ملف التوقيع في مكان آمن]

**Exit:** RELEASE_CHECKLIST.md has every item marked PASS, FAIL, or NOT RUN. Then stop and wait for the owner. This is the last session.

---

# PART 3: Reference

## 3.1 Acceptance criteria (each with the minimum evidence level that closes it)

| # | Criterion | Built in (session) | Minimum level and evidence |
|---|---|---|---|
| 1 | Dinosaur silhouette is classic and recognizable | 2 | L3: black-fill silhouette check at 1× and 3×, plus owner note |
| 2 | Pixel art is crisp and consistent, never blurred | 2 | L3: sprite review at 3×, rendering settings, screenshots with commit |
| 3 | Jump height follows hold time, with a cap | 2 | L2: tap, partial-hold, and full-hold jump tests |
| 4 | Jump buffer and coyote time work within their windows | 2 | L2: timing tests, including no mid-air jumps outside coyote time |
| 5 | Slide, dive, drop-through, and elevated jumps behave correctly | 2, 4 | L3: scripted replay of each action, logs reviewed |
| 6 | Camera tracks smoothly in both directions | 4 | L3: camera tests and a replay that checks hazard visibility |
| 7 | Springs and bounce chains create real route choices | 4 | L3: replay of every object type and one bounce chain |
| 8 | Flight pickups work and expire safely | 6 | L3: flight replay covering the warning, expiry, and landing |
| 9 | Skills can be collected and used | 5 | L3: replay using all eight skills, with HUD states captured |
| 10 | Four worlds differ in look and mechanics | 7 | L3: full run through all four worlds (seed logged) and theme validation |
| 11 | Obstacles are fair | 4, 8 | L2: V1 and V2 reports with no unexplained failures |
| 12 | Start, pause, resume, end, save, and restart all work | 3, 9, 10 | L3: session replay and save-file checks |
| 13 | Touch controls are readable, responsive, and functional | 9 | L5: input replay on an emulator or device. Lower levels support it but cannot close it. |
| 14 | UI fits common landscape screens | 9 | L3: layout tests at each listed ratio; L5 screenshots where a device exists |
| 15 | Code is organized and maintainable | all | L3: Pass 2 review record and the extensibility test |
| 16 | Automated tests pass and runtime bugs are addressed | all | L2: counts, a reason for every skip, and no open Blocker or Major |
| 17 | Android APK is built and verified | 3, 12 | L4: verification outputs, checksum, metadata, and signature |
| 18 | Documentation and limitations are accurate | all | L3: each document checked against verified levels |

Rules:
- A criterion is PASS only when its minimum level is reached and its evidence is stored. Otherwise it is FAIL or NOT RUN, with the reason.
- Record emulator and physical-device results separately, with the model and Android version. An owner playtest counts only when the build, device model, and Android version are recorded.
- Do not hide an unimplemented feature behind a placeholder or misleading UI. Do not claim that every bug is gone.

## 3.2 Documents: what, language, and when

| Document | Language | Starts at (session) | Notes |
|---|---|---|---|
| README.md | English | 1 | Setup, dependencies, structure, controls, tests, export overview. Updated every session. Includes a short Arabic summary pointing to START_HERE_AR.md. |
| CHANGELOG.md | English | 1 | One entry per milestone. |
| .gitignore | n/a | 1 | |
| docs/WORKLOG.md | English | 1 | Session log and resume point (1.8). |
| docs/DEVELOPER_GUIDE.md | English | 2 | Setup from a clean clone, exact validation and test commands, project conventions, and step-by-step instructions for adding a world, skill, obstacle, or pattern. Those instructions are checked by the extensibility test. |
| docs/ARCHITECTURE.md | English | 2 | Key decisions and trade-offs, each with its reason and the alternatives rejected: engine version pin, logical resolution and pixel snapping, physics-tick movement, the state machine, data-driven configuration, save format and migrations, autoload choices, the generation method, and the Android export path. |
| docs/ASSET_LICENSES.md | English | first external asset | Name, author, source URL, license, files used, modifications. |
| docs/BUG_TRACKER.md | English | first bug found | |
| START_HERE_AR.md | Arabic (owner entry point) | 3 | The exact project folder; what each main folder contains; the APK location; the source ZIP location; the repository URL; the release URL if published; which files to open to play, install, or modify; which files must never be deleted; how to rebuild; the keystore location and backup reminder; and the current status with its unverified items. Updated every session. |
| docs/ANDROID_INSTALL_GUIDE_AR.md | Arabic | 3 | See Session 3 documents. |
| docs/ANDROID_BUILD_GUIDE_AR.md | Arabic | 3, finished 12 | The required software, where to get each item, and the versions that were tested. How to open the project in Godot, confirm that resources load, configure the Android export, produce a debug APK, find it, and read export errors. Debug versus release builds, signing for future public distribution, and keystore backup. Editor steps come first. A command appears only after it has been tested, and each command states its working directory. |
| docs/GAMEPLAY_GUIDE_AR.md | Arabic | 3 onward | Launching the game; the tutorial and menus; running and jumping; hold-based height; sliding, diving, and drop-through; platforms and spring objects; skills and flight; world changes; HUD, score, pause, and retry; keyboard and touch controls. Each part is written only when its mechanic reaches L3. Screenshots come from the actual build and carry their capture date and commit. |
| docs/TEST_REPORT.md | English | 3, completed 11 | See 3.3. |
| releases/README.md | English | 3 | Local release folder, file naming, checksums. |
| docs/RELEASE_CHECKLIST.md | English | 11, finalized 12 | See 3.4. |
| LICENSE | n/a | 12 gate | Default MIT for code. |
| docs/TROUBLESHOOTING_AR.md | Arabic | 12 | Only for problems that were reproduced and whose fix or workaround was verified. |

## 3.3 docs/TEST_REPORT.md structure

- **Environment:** OS, CPU, RAM, Godot and template versions, JDK, Android SDK and build-tools versions, and the emulator or device model with its Android version. Record each item only after checking it.
- **Tests:** implemented and executed counts by category, with passed, failed, and skipped results. Every skip has a reason.
- **Validation:** L1 results.
- **Replays and end-to-end sessions:** seed, duration, result, and log location.
- **Fairness:** V1 and V2 summaries, with counts per world and band, failures, and exclusions.
- **Performance:** frame times, memory, node counts, and orphan-node counts, with the hardware used.
- **Bugs:** found, fixed, and open, with links to BUG_TRACKER.md.
- **Not run:** each test that could not run, with the reason.
- **Verification summary:** desktop gameplay level, Android export level, and whether an emulator or device was used.
- **Player notes:** the answers from Session 11 spec D.
- **Limits:** no claim of compatibility with every Android device, and no claim that all bugs are gone.

## 3.4 docs/RELEASE_CHECKLIST.md structure

- One row for each acceptance criterion in 3.1, marked PASS, FAIL, or NOT RUN, with a link to its evidence, the date, and the commit.
- Process rows: static APK checks passed for the release commit; source ZIP verified; pre-push checklist done; release notes match the verified levels; START_HERE_AR.md matches the release; the owner confirmed the keystore backup (record the confirmation, never the password); release permissions match the Android rules (no INTERNET, and VIBRATE only if vibration ships); the package name was confirmed at the gate.

## 3.5 Clarifications

- **Gradle:** AAB export usually needs the Gradle build path, and so does any required plugin. The default Android export does not. Use Gradle only for those reasons, and record the reason in docs/ANDROID_BUILD_GUIDE_AR.md.
- **Gate:** the Session 12 gate also covers the package name. Confirm it before the first release-signed build.
- **APK verification levels:** the static checks count as L4. The install-and-launch steps count as L5, and they run only when an emulator or device is available.

---

**Owner: start with Session 1. After each session ends, open the next number.**
