# Riftosaur

> **ملخص سريع بالعربي:**
> مشروع "Riftosaur" هو إعادة تصور للعبة الديناصور الكلاسيكية (endless runner) كـ Pixel-art 2D مع مسارات رأسية ومهارات عناصر وانتقال بين عوالم متعددة.
> هذا المشروع مبني بمحرك Godot 4.7.2 المستقر. للاطلاع على دليل البداية ودليل المالك، انظر [START_HERE_AR.md](START_HERE_AR.md) (يبدأ من Session 3).

---

## Overview

**Riftosaur** is an original endless-runner platformer built in Godot Engine 4.x. It reimagines the classic desert runner with dynamic verticality, jumping/sliding/diving mechanics, active elemental abilities, and dimension-shifting rifts into alien, volcanic, and neon worlds.

- **Root Directory:** `C:\Users\Tweety\Desktop\DINO`
- **Target Engine:** Godot Engine 4.7.2-stable official (`ed1daf0bf`)
- **Render Mode:** `gl_compatibility` (OpenGL ES 3.0 compatible for broad mobile and desktop support)
- **Logical Viewport:** 480 × 270 (16:9 pixel-perfect logical grid with nearest-neighbor scaling)

---

## Directory Structure

```
Riftosaur/
├── .gitignore               # Git ignore rules for engine cache, builds, keystores
├── CHANGELOG.md             # Milestone changelog
├── project.godot            # Godot 4.x project configuration
├── README.md                # Project documentation and developer overview
├── assets/                  # Original sprites, tiles, audio, and source maps
├── docs/                    # Technical architecture, worklogs, test reports
│   └── WORKLOG.md           # Autonomous session execution log and resume state
├── resources/               # Central gameplay configuration and data resources
├── scenes/                  # Game scenes (main, player, worlds, ui)
│   └── main/                # Main entry point
├── scripts/                 # Typed GDScript modular logic
│   ├── main.gd              # Main scene lifecycle controller
│   └── systems/             # Replay and helper systems
├── tests/                   # Headless SceneTree automated testing framework
│   ├── test_runner.gd       # Headless test runner
│   └── unit/                # Unit and smoke test suites
└── tools/                   # Validation, testing, and automation scripts
    ├── run_tests.ps1        # PowerShell test execution wrapper
    └── validate_l1.gd       # L1 static validation script
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
