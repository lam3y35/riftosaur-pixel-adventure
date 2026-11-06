# Riftosaur

> **ملخص سريع بالعربي:**
> مشروع "Riftosaur" هو إعادة تصور للعبة الديناصور الكلاسيكية (endless runner) كـ Pixel-art 2D مع مسارات رأسية ومهارات عناصر وانتقال بين عوالم متعددة.
> هذا المشروع مبني بمحرك Godot 4.7.2 المستقر. للاطلاع على دليل البداية ودليل المالك، انظر [START_HERE_AR.md](START_HERE_AR.md) (يبدأ من Session 3).

---

## Overview

**Riftosaur** is an original endless-runner platformer built in Godot Engine 4.x. It reimagines the classic desert runner with dynamic verticality, jumping/sliding/diving mechanics, active elemental abilities, flight pickups, and procedural generation across 4 distinct worlds (Plains, Jungle, Frozen, Volcanic).

- **Current Version:** `v1.0.0` (Production Release)
- **Root Directory:** `C:\Users\Tweety\Desktop\DINO`
- **Target Engine:** Godot Engine 4.7.2-stable official (`ed1daf0bf`)
- **Render Mode:** `gl_compatibility` (OpenGL ES 3.0 compatible for broad mobile and desktop support)
- **Logical Viewport:** 480 × 270 (16:9 pixel-perfect logical grid with nearest-neighbor scaling)
- **Automated Test Suite:** 72 passing tests (100% pass rate) + 20/20 verified procedural patterns.
- **Android Release:** `releases/Riftosaur-release.apk` (60.07 MB, SHA-256: `1247D7D061291DD501C95094E7F56B54251F5368F5D754EAB06B1E8135F11676`)

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
