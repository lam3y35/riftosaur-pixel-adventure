# Riftosaur v1.4.0 — Release Notes

**Tag:** `v1.4.0`  
**Target Engine:** Godot Engine 4.7.2-stable official  
**Android Target:** API 24+ (Android 7.0+), Version Code `5`, Version Name `1.4.0`  
**Test Suite:** 114 / 114 passing automated tests (100% Pass)  

---

## 🚀 Key Highlights & New Features

### 1. 🎯 Normal Game Skill Selection & Distance-Rarity Spawning
- **Direct Start Menu Skills Deck:** Added a dedicated `SKILLS DECK` button (`StartSkillsBtn`) directly on the main Start Menu. You can now customize your active 4-skill loadout specifically for standard runs without having to go through the Practice Hub.
- **Contextual Meter Spawning:** Skills in regular gameplay now spawn based on distance traveled and tier rarity:
  - Common: Every `70m`
  - Rare: Every `105m`
  - Epic: Every `145m`
  - Legendary: Every `195m`
- Skills spawn placed fairly at contextually relevant obstacle formations where their specific ability can be actively used.

### 2. 📖 Animated Enemies Encyclopedia
- **Real Animated Sprites:** Added an interactive `ENEMIES GUIDE` accessible from both the Start Menu and Practice Hub.
- Displays all 10 obstacles, enemies, and traps with real game ~1.0s animated loops (Pterodactyl wing flapping, Ground Spikes gleaming, Lava Pit bubbling, Bounce Pads flexing, Traps oscillating).
- **Tactical Breakdown:** Indicates exact spawn lanes (Ground, Air, Elevated), obstacle categories, and clear counteractions (Slide, Jump, Stomp, Bone Blade, Boomerang, Dash).

### 3. ❤️ Difficulty Hearts Model Rebalance
- Inverted and refined hearts according to speed and hazard density:
  - **Easy Mode:** `1♥` (focused on baseline reflexes and relaxed speeds)
  - **Medium Mode:** `2♥` (allows 1 hit recovery before defeat)
  - **Hard Mode:** `3♥` (high obstacle density & rapid speed progression requiring extra resilience)
  - **Practice Mode:** Unlimited / immortal

### 4. ⚖️ Fair Procedural Obstacle Placement & Spacing
- Introduced physics-based spacing validation (`_is_hazard_placement_fair`): checks distance clearance between adjacent hazards against runner speed and jump arc trajectory.
- Prevents unfair consecutive hazard walls while applying subtle deterministic micro-shuffles so runs remain fresh, dynamic, and non-repetitive without ever being impossible.

### 5. 🦅 Flying Skill Overhaul & Overhang Clearance
- **Equip Before Flight:** Collecting `Mechanical Wings` or `Rocket Relic` pickups now equips them into active skill slots rather than auto-activating immediately. Players choose exactly when to activate flight.
- **Overhang Top Removed:** Removed the tall top pillar collision from overhang obstacles (`scenes/obstacles/obstacle_overhang.tscn`, `assets/sprites/obstacle_high.png`). Flying dinosaurs can now freely fly over overhang obstacles without fatal collisions.

### 6. 🗺️ Dynamic 10,000 px Linked Map Builder
- Expanded custom map canvas capacity from 5,000 px to **10,000 px** (supporting up to 300 placed objects).
- Added 1x/2x zoom toggles, horizontal meter grid markings, live reachability ghost previews, `+NEW` canvas reset, undo, right-click eraser, and seamless multi-map course linking (`linked_next_id`).

### 7. 🧹 Transient Tips & Builder Mortality Fix
- Gameplay tips and toasts now automatically dismiss immediately upon game over, pause, quitting to menu, or starting a new run.
- Fixed unwanted immortality shield aura showing in Custom Map Builder when mortality is turned on (`Mortality: ON` / `immortal: false`).

### 8. 🎮 PlayStation 4 Controller Polish
- Circle button (`○`) during gameplay cleanly ducks/slides without triggering `ui_cancel` pause events.
- Full D-pad and shoulder bumper navigation across all subdialogs, skill deck selectors, and enemy guides.

### 9. ⚡ 60 FPS Performance & Pixel Shimmer Fix
- Adaptive VSync (`VSYNC_ADAPTIVE`) and integer-aligned ground camera zoom lock (`1.0`) eliminate pixel shimmer at high runner speeds.

---

## 📦 Android Builds & Verification

| File | Target | Version Code | Version Name | Size | SHA-256 Checksum | Evidence Level |
|---|---|---|---|---|---|---|
| `Riftosaur-debug.apk` | Android (arm64-v8a, x86_64) | 5 | 1.4.0 | 62,863,962 bytes (59.95 MB) | `24A8083C5364D60EFF6779792D96FEDF09477C6604E7DE14CEC1326BF2B4F5A5` | L4 Static Debug APK Verification (v1.4.0 Debug Signed) |
| `Riftosaur-release.apk` | Android (arm64-v8a, x86_64) | 5 | 1.4.0 | 58,120,028 bytes (55.43 MB) | `546C3430F716587E8DFD111190C6467937C0A5657F41E501341D5E23A223DAB3` | L4 Static Release APK Verification (`-AllowUnsigned`, zipaligned) |

---

## 🛠️ Verification & Test Results
- **L1 Static Validation:** PASSED (0 errors, 0 warnings)
- **Validator V1 & V2:** PASSED (24/24 procedural patterns analytically verified)
- **L2 Automated Tests:** 114 / 114 PASSED (0 Failed, 0 Skipped)
- **L4 Android Package:** Verified 4-byte zipalign, correct permissions (`VIBRATE` enabled, `INTERNET` disabled / 100% offline).
