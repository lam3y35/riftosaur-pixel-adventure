# Riftosaur

> **ملخص سريع بالعربي:**
> مشروع "Riftosaur" هو إعادة تصور للعبة الديناصور الكلاسيكية (endless runner) كـ Pixel-art 2D مع مسارات رأسية ومهارات عناصر وانتقال بين عوالم متعددة.
> هذا المشروع مبني بمحرك Godot 4.7.2 المستقر. للاطلاع على دليل البداية ودليل المالك، انظر [START_HERE_AR.md](START_HERE_AR.md) (يبدأ من Session 3).

---

## Overview

**Riftosaur** is an original endless-runner platformer built in Godot Engine 4.x. It reimagines the classic desert runner with dynamic verticality, jumping/sliding/diving mechanics, active elemental abilities, flight pickups, and procedural generation across 4 distinct worlds (Plains, Jungle, Frozen, Volcanic).

- **Current Version:** `v1.2.0` (Production Release)
- **Root Directory:** `C:\Users\Tweety\Desktop\DINO`
- **Target Engine:** Godot Engine 4.7.2-stable official (`ed1daf0bf`)
- **Render Mode:** `gl_compatibility` (OpenGL ES 3.0 compatible for broad mobile and desktop support)
- **Logical Viewport:** 480 × 270 (16:9 pixel-perfect logical grid with nearest-neighbor scaling)
- **Automated Test Suite:** 101 passing tests (100% pass rate) + 24/24 verified procedural patterns + 12/12 QA Matrix scenarios.
- **Android Release:** `releases/Riftosaur-release.apk` (55.38 MB, SHA-256: `36A2FC70DD9FA0992802F910C74838C99D9C885D19EDDA6E81F34064404CCED2`)

---

## Download & Setup

### Android (Direct APK Install)
1. Download **`Riftosaur-release.apk`** from the [Latest GitHub Release](https://github.com/lam3y35/riftosaur-pixel-adventure/releases/latest).
2. Open the downloaded `.apk` on your Android device (Android 7.0+ / API 24+, `arm64-v8a` & `x86_64`) and allow installation from your browser/file manager if prompted.
3. Verify checksum (optional):
   ```powershell
   Get-FileHash Riftosaur-release.apk -Algorithm SHA256
   ```
   Expected: `36A2FC70DD9FA0992802F910C74838C99D9C885D19EDDA6E81F34064404CCED2`
4. See [docs/ANDROID_INSTALL_GUIDE_AR.md](docs/ANDROID_INSTALL_GUIDE_AR.md) for a step-by-step Arabic installation guide.

### Desktop / Run from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/lam3y35/riftosaur-pixel-adventure.git
   cd riftosaur-pixel-adventure
   ```
2. Open the folder in **Godot Engine 4.7.2-stable** and press `F5` (or run from CLI):
   ```powershell
   & "C:\Users\Tweety\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --path .
   ```

---

## What's New in v1.2.0

- **3-Slot Multi-Skill System & Traps:** Equip up to 3 simultaneous skills out of 12 total abilities with independent HUD activation buttons, tier/rarity badges, and `TrapPickup` speed-surge hazards.
- **16+ Dinosaur Skins & Cosmetics Shop:** 11 new unlockable skins (including *Chromatic God*, *Void Walker*, *Diamond Apex*, *Celestial*, *Crimson Rex*, and more) with starter/passive perks plus obstacle, map, and trail cosmetics.
- **Tutorial & Practice Hub:** Interactive first-launch tutorial, practice immortality with adaptive hints, section practice, custom map builder, and isolated per-mode high scores.
- **Quests & Player Leveling:** 25+ quests with XP progression and level-up diamond bonuses.
- **Controls & PS4 Gamepad Support:** Slide-hold continuation, air-only left steering, crawler stomp (+1 gem), and PS4 controller mode with custom button remapping.

---

## Directory Structure

```
Riftosaur/
├── .gitignore               # Git ignore rules for engine cache, builds, keystores
├── CHANGELOG.md             # Milestone changelog
├── project.godot            # Godot 4.x project configuration
├── README.md                # Project documentation and developer overview
├── assets/                  # Original sprites, tiles, audio, and source maps
│   ├── sources/             # Human-readable text source maps for pixel art
│   └── sprites/             # Compiled pixel-art sheets (dinosaur, tiles, particles)
├── docs/                    # Technical architecture, worklogs, test reports
│   ├── ARCHITECTURE.md      # Key decisions and technical trade-offs
│   ├── ASSET_LICENSES.md    # Provenance register and CC0 licensing
│   ├── DEVELOPER_GUIDE.md   # Developer setup, conventions, and extension guide
│   ├── WORKLOG.md           # Autonomous session execution log and resume state
│   └── evidence/            # Verification logs and silhouette checks
├── resources/               # Central gameplay configuration and data resources
│   └── gameplay_config/     # Central GameplayConfig resource (.tres)
├── scenes/                  # Game scenes (main, player, obstacles, gameplay)
│   ├── gameplay/            # Flat test track with pooling
│   ├── main/                # Main entry point
│   ├── obstacles/           # Low rocks and overhang hazards
│   └── player/              # Player scene with animations and collision
├── scripts/                 # Typed GDScript modular logic
│   ├── gameplay/            # Test track generation controller
│   ├── obstacles/           # Hazard damage dispatchers
│   ├── player/              # Player movement & 14-state machine
│   ├── resources/           # Configuration schema definitions
│   └── systems/             # Replay and helper systems
├── tests/                   # Headless SceneTree automated testing framework
│   ├── test_runner.gd       # Headless test runner
│   └── unit/                # Unit, smoke, replay, and movement physics tests
└── tools/                   # Validation, testing, and automation scripts
    ├── generate_sprites.py  # Procedural pixel-art sheet generator
    ├── run_desktop_playtest.gd # 2-minute L3 desktop playtest runner
    ├── run_tests.ps1        # PowerShell test execution wrapper
    ├── validate_l1.gd       # L1 static validation script
    └── verify_silhouette.py # Solid silhouette 1x/3x validation tool
```

---

## Dependencies & Requirements

- **Engine:** Godot Engine 4.7.2-stable (`Godot_v4.7.2-stable_win64_console.exe` pinned at `C:\Users\Tweety\Godot\4.7.2\`)
- **Export Templates:** Godot 4.7.2.stable installed in `%APPDATA%\Godot\export_templates\4.7.2.stable\`
- **Java:** JDK 17 (Microsoft HotSpot 17.0.20 pinned at `C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot\`)
- **Python:** 3.12 (for build tools and source map generators)
- **Version Control:** Git with active GitHub CLI authentication (`gh`)

---

## Controls (Default Keybindings)

| Action | Primary Key | Alternate Key | Mobile / Touch |
|---|---|---|---|
| **Jump** | `Space` | `Up Arrow`, `W` | Screen Tap / Jump Virtual Button |
| **Slide / Duck** | `Down Arrow` | `S` | Slide Virtual Button |
| **Skill** | `E` | `J` | Skill Virtual Button |
| **Pause** | `Escape` | `P` | Pause Virtual Button |

---

## Running Validation and Tests

### L1 Static Validation
Runs headless static checks verifying project settings, viewport dimensions, nearest-neighbor filtering, required input actions, and scene existence:
```powershell
& "C:\Users\Tweety\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script tools/validate_l1.gd
```

### L2 Automated Test Suite
Runs the headless unit test runner executing all registered test suites:
```powershell
& "C:\Users\Tweety\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script tests/test_runner.gd
```

### Combined Runner (PowerShell)
```powershell
powershell -ExecutionPolicy Bypass -File tools/run_tests.ps1
```
