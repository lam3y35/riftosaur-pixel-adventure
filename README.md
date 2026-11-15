# Riftosaur

> **ملخص سريع بالعربي:**
> مشروع "Riftosaur" هو إعادة تصور للعبة الديناصور الكلاسيكية (endless runner) كـ Pixel-art 2D مع مسارات رأسية ومهارات عناصر وانتقال بين عوالم متعددة.
> هذا المشروع مبني بمحرك Godot 4.7.2 المستقر. للاطلاع على دليل البداية ودليل المالك، انظر [START_HERE_AR.md](START_HERE_AR.md) (يبدأ من Session 3).

---

## Overview

**Riftosaur** is an original endless-runner platformer built in Godot Engine 4.x. It reimagines the classic desert runner with dynamic verticality, jumping/sliding/diving mechanics, active elemental abilities, flight pickups, and procedural generation across 4 distinct worlds (Plains, Jungle, Frozen, Volcanic).

- **Current Version:** `v1.3.0` (Production Release)
- **Root Directory:** `C:\Users\Tweety\Desktop\DINO`
- **Target Engine:** Godot Engine 4.7.2-stable official (`ed1daf0bf`)
- **Render Mode:** `gl_compatibility` (OpenGL ES 3.0 compatible for broad mobile and desktop support)
- **Logical Viewport:** 480 × 270 (16:9 pixel-perfect logical grid with nearest-neighbor scaling, locked 60 FPS / 60 Hz physics)
- **Automated Test Suite:** 113 passing tests (100% pass rate) + 24/24 verified procedural patterns (Validator V1 & V2).
- **Android Direct Install APK (Signed):** `releases/Riftosaur-debug.apk` (59.89 MB, SHA-256: `8A03B0D2567FE41BA3DD28492F9805424BA07C9B7AE36EA2C3730DA3B02E60B9`)
- **Android Unsigned Release APK:** `releases/Riftosaur-release.apk` (55.37 MB, SHA-256: `644330A4EA98F023E0EB8F0F2AA7EE21E3FC02E5FF8C366172DBD7A811A57095`)

---

## Download & Setup

### Android (Direct APK Install)
1. Download **`Riftosaur-debug.apk`** (ready-to-install signed Android APK) from the [Latest GitHub Release](https://github.com/lam3y35/riftosaur-pixel-adventure/releases/latest) or the [Riftosaur Website](https://lam3y35.github.io/riftosaur-pixel-adventure/). *(Note: `Riftosaur-release.apk` is an unsigned pre-store export for developer signing.)*
2. Open the downloaded `.apk` on your Android device (Android 7.0+ / API 24+, `arm64-v8a` & `x86_64`) and allow installation from your browser/file manager if prompted.
3. Verify checksum (optional):
   ```powershell
   Get-FileHash Riftosaur-debug.apk -Algorithm SHA256
   ```
   Expected: `8A03B0D2567FE41BA3DD28492F9805424BA07C9B7AE36EA2C3730DA3B02E60B9`
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

## What's New in v1.3.0

- **60 FPS Visual Clarity & Responsive Touch Controls:** Locked `60 FPS` (`vsync_mode=1`, `60 Hz` physics with zero jitter), clamped camera zoom (`0.94..1.04`), edge-only FX, non-overlapping `96×92` multi-touch hit-zones around `Jump` & `Slide`, Slide & Steer across all modes, and instant Frame-1 auto-start directly from a Jump/Slide tap.
- **Difficulty Speeds, Hearts & 4 Hazard Traps:** Gradual opening speeds (`Easy: 196→400 w/ 2♥`, `Medium: 216→460 w/ 1♥`, `Hard: 232→495 w/ 3♥`), HUD hearts & persistent shield aura when immortal, plus 4 independent trap debuffs (`Speed Surge`, `Heavy Gravity`, `Vision Glitch`, `Skill Jam`).
- **4-Skill Loadout, Distance-Rarity Spawning & Infinite Skill Lab:** Pick up to 4 active skills from the 12-skill catalog (default starter deck `[1, 2, 3, 5]`), spawn skills every `70m / 105m / 145m / 195m` by rarity at contextually clearable obstacles, and test any single skill endlessly inside targeted Skill Lab arenas.
- **Interactive 7-Step Tutorial, Animated Enemies Encyclopedia & Linked Map Builder:** Input-gated 7-step tutorial covering every obstacle family, clean HUD with tutorial-only tips, animated ~1.2s Enemies Guide showing jump/slide/stomp/slash tactics, swipe-guarded Skin Shop previews, non-repeatable quest claims, and a 3-size (`2.6k / 3.8k / 5.0k`) Custom Map Builder with live jump-arc/gap-passability validation, per-trap selection, & live linked map progression.
- **Full PS4 Controller Mode & 113/113 Verified Tests:** Complete PS4 menu, pause/game-over, Practice Entry Panel, D-Pad/analog Y release, Slide/Jump/Skill, and flight Y-axis bindings plus `tests/unit/test_v4_overhaul.gd` regression coverage.

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
