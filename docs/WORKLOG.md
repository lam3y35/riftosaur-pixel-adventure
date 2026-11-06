# Riftosaur Worklog & Session Tracking

## Current state
- **Session:** Session 7 (Completed)
- **Milestone:** M6 (Four launch worlds, visual identities, transitions, safe chunks, and extensible themes)
- **Last commit:** pending (tag: `m6-complete`)
- **Root folder:** `C:\Users\Tweety\Desktop\DINO`
- **Highest evidence level per area:**
  - Setup & Baseline: L2 Automated (54 tests passing, 0 failures, 0 skips)
  - Movement & Core Loop: L3 Desktop play (Endless runner scene, dynamic world transitions, 4 distinct biomes, parallax cross-fades, safe transition runway)
  - Silhouette / Art: L3 Verified (13 world environment assets: 4 distinct world palettes, 3 parallax background layers per world, ground tilesets, lava hazards)
  - Static Project Validation: L1 Static (0 errors, 0 warnings) + Validator V1 (Analytic reach/rise fairness across all 18 chunks, 0 errors)
  - Android Build: L4 Static APK Verification (67,468,006 bytes, SHA-256 `7782A8CB37E24E5371C71BFCA33D232CB40192F0FE767BF4907A039B0FDCD81A`, aapt2 dump badging, zipalign 4-byte check, apksigner v2/v3 cert check, archive content check)
  - Physical Android Play: L5 Owner Playtest #1 & #2 complete
- **Open Blockers:** 0
- **Open Majors:** 0
- **Owner actions:** Test the updated APK (`releases/Riftosaur-debug.apk`) with 4 distinct biomes and smooth transitions, or proceed with Session 8.
- **Next action:** Execute Session 8 — Procedural generation and fairness (M7).

---

## Session entries

### Session 7 — Worlds and Transitions (M6)
- **Date:** 2026-11-06
- **Milestone:** M6
- **Start commit:** 752b1b6 (`m5-complete`)
- **End commit:** pending (tag: `m6-complete`)
- **Evidence levels reached:**
  - L1 Static: Zero script/parse errors, all scenes instantiable, clean project validation via `tools/validate_l1.gd`.
  - Validator V1: Analytic reach and rise fairness validation via `tools/validate_v1.gd` on all 18 chunks. Safe transition chunk contains 0 hazards and passes all reach/rise rules.
  - L2 Automated: 54 passing automated unit and physics tests in `tests/test_runner.gd` (5 smoke + 1 replay + 9 movement + 4 save service + 8 endless runner loop + 5 vertical platform & springs + 10 skills & collectibles + 5 flight system + 4 world themes & transitions tests).
  - L3 Desktop play: Live verified via `tools/verify_session7_worlds_run.gd`: sequential progression through Prehistoric Plains (0-250m), Overgrown Jungle (250-500m), Frozen Ruins (500-750m), and Volcanic Underworld (750m+), with HUD updates, 1.5s parallax cross-fade tweens, and guaranteed hazard-free runway chunks during transitions.
  - L4 Android Build Verification: Debug APK exported to `releases/Riftosaur-debug.apk` (67,468,006 bytes, SHA-256 `7782A8CB37E24E5371C71BFCA33D232CB40192F0FE767BF4907A039B0FDCD81A`). Verified via `tools/verify_apk.ps1` with `aapt2`, `zipalign`, and `apksigner`.
- **Delivered components:**
  - 4 Launch Worlds and Theme Resources:
    1. *World 1: Prehistoric Plains:* Sunlit amber sky, distant volcanic peaks, rolling hills, prehistoric dirt/grass.
    2. *World 2: Overgrown Jungle:* Emerald canopy sky, ancient vine trees, mossy jungle foliage, overgrown ancient earth.
    3. *World 3: Frozen Ruins:* Pale glacier sky, frosted jagged peaks, icy stone ruins, permafrost ground.
    4. *World 4: Volcanic Underworld:* Smoldering ash sky, obsidian crater cliffs, cracked glowing magma hills, volcanic bedrock & lava pool hazards.
  - WorldTheme Resource System (`scripts/world/world_theme.gd`):
    - Data-driven `.tres` resources for theme definitions: id, display name, sky/distant/midground textures, ground tileset, ambient tint, ground y position.
    - Full extensibility demonstrated and unit tested (`test_extensibility_custom_world_theme`).
  - Parallax Layer Controller (`scripts/world/parallax_controller.gd`):
    - Multi-layer parallax handling with separate scroll scale speeds (sky: 0.05, mountains: 0.15, hills: 0.35).
    - Smooth 1.5-second cross-fade tween transitioning between themes without sudden pop or visual tear.
  - Safe Transition Chunk (`scenes/obstacles/chunks/chunk_00_world_transition.tscn`):
    - Guaranteed hazard-free 480px flat transition runway spawned at every world boundary.
  - World Transition HUD:
    - Current world label in TopBar (`WorldLabel`).
    - Cinematic transition announcement card (`WorldTransitionCard`) displaying world entrance titles.
- **Verification evidence:**
  - L1: 0 errors across all scripts and scenes.
  - Validator V1: 18 chunks validated, 0 errors.
  - L2: 54/54 automated tests passed in `test_runner.gd`.
  - L3: `tools/verify_session7_worlds_run.gd` passed with all 4 biomes.
  - L4: APK export verified clean (67,468,006 bytes, SHA-256 `7782A8CB37E24E5371C71BFCA33D232CB40192F0FE767BF4907A039B0FDCD81A`).

---

### Session 6 — Flight (M5)
- **Date:** 2026-11-06
- **Milestone:** M5
- **Start commit:** 7d41118 (`m4-complete`)
- **End commit:** pending (tag: `m5-complete`)
- **Evidence levels reached:**
  - L1 Static: Zero script/parse errors, all scenes instantiable, clean project validation via `tools/validate_l1.gd`.
  - Validator V1: Analytic reach and rise fairness validation via `tools/validate_v1.gd` on all 17 chunks. All flight route platforms and clear strips conform to reach/rise limits.
  - L2 Automated: 50 passing automated unit and physics tests in `tests/test_runner.gd` (5 smoke + 1 replay + 9 movement + 4 save service + 8 endless runner loop + 5 vertical platform & springs + 10 skills & collectibles + 5 flight system tests).
  - L3 Desktop play: Live verified via `tools/verify_session6_flight_run.gd`: pickup of Mechanical Wings & Rocket Relic, vertical ascent/descent, automatic horizontal progress, down input giving gradual descent without grounded actions, 2s landing warning with flashing HUD indicator, smooth landing glide, and timer preservation during pause/resume.
  - L4 Android Build Verification: Debug APK exported to `releases/Riftosaur-debug.apk` (67,426,369 bytes, SHA-256 `436FC7D4C9748BB0AA48271F48F2AC3967520C00FE2B944FF16F9B9EF0A3801C`). Verified via `tools/verify_apk.ps1` with `aapt2`, `zipalign`, and `apksigner`.
- **Delivered components:**
  - Two Flight Pickups:
    1. *Mechanical Wings:* Steady lift (up 210 px/s, glide 130 px/s), 7.0s duration with 4-frame flapping wing overlay animation (`scenes/objects/flight_pickup_wings.tscn`).
    2. *Rocket Relic:* Strong thrust (up 340 px/s, descent 160 px/s), 5.0s duration with 4-frame animated fiery rocket thruster flame (`scenes/objects/flight_pickup_rocket.tscn`).
  - Flight Controls & Physics:
    - Vertical control with up and down inputs (W/S, Up/Down, plus dedicated on-screen `FlightUpButton` and `FlightDownButton`).
    - Flight controls shown *ONLY* during flight.
    - Down input provides gradual descent, never a slide or dive.
    - Gentle landing support: initial exit velocity is 60 px/s glide, smoothly returning to normal physics without a sudden drop.
  - Flight HUD:
    - Flight duration indicator (`FlightTimerBar` in HUD TopBar).
    - 2-second pre-expiry warning indicator flashing yellow/red.
  - Sky Hazard:
    - `ObstacleStormCloud` (`scenes/obstacles/obstacle_storm_cloud.tscn`): Airborne electrical cloud obstacle.
  - 2 New Hand-Authored Chunks:
    - `chunk_16_flight_wings_route.tscn`: Wings flight path with sky gem arcs and cloud hazards.
    - `chunk_17_flight_rocket_route.tscn`: Rocket thrust path with high gems and pterodactyl gauntlet leading to an elevated landing terrace.
  - Automated Tests: 5 comprehensive tests in `tests/unit/test_flight_system.gd` registered in `tests/test_runner.gd`.
- **Bugs opened & closed:**
  - *BUG-M5-01 (Closed):* GDScript 4 primitive boolean capture in test lambda prevented detection of `flight_ended` signal. Fixed by using reference dictionary container.
- **Files created or modified:**
  - `assets/sprites/pickup_flight_wings.png`
  - `assets/sprites/pickup_flight_rocket.png`
  - `assets/sprites/flight_wings_anim.png`
  - `assets/sprites/flight_flame_anim.png`
  - `assets/sprites/obstacle_storm_cloud.png`
  - `scripts/objects/flight_pickup.gd`
  - `scenes/objects/flight_pickup_wings.tscn`
  - `scenes/objects/flight_pickup_rocket.tscn`
  - `scenes/obstacles/obstacle_storm_cloud.tscn`
  - `scenes/obstacles/chunks/chunk_16_flight_wings_route.tscn`
  - `scenes/obstacles/chunks/chunk_17_flight_rocket_route.tscn`
  - `scripts/player/player.gd`
  - `scripts/gameplay/endless_runner.gd`
  - `scripts/ui/hud.gd`
  - `scenes/ui/hud.tscn`
  - `tests/unit/test_flight_system.gd`
  - `tests/test_runner.gd`
  - `tools/verify_session6_flight_run.gd`
- **Changes to plan:** None.
- **Blockers:** None.

---

### Session 5 — Skills and collectibles (M4)
- **Date:** 2026-11-06
- **Milestone:** M4
- **Start commit:** 4dadf27 (`m3-complete`)
- **End commit:** 7d41118 (tag: `m4-complete`)
- **Evidence levels reached:**
  - L1 Static: Zero script/parse errors, all scenes instantiable, clean project validation via `tools/validate_l1.gd`.
  - Validator V1: Analytic reach and rise fairness validation via `tools/validate_v1.gd` on all 15 chunks. All vertical platform rises conform to <= 80% maximum jump rise; all gaps conform to <= 80% horizontal reach; minimum reaction window verified.
  - L2 Automated: 45 passing automated unit and physics tests in `tests/test_runner.gd` (5 smoke + 1 replay + 9 movement + 4 save service + 8 endless runner loop + 5 vertical platform & springs + 10 skills & collectibles system tests).
  - L3 Desktop play: Live verified via `tools/verify_session5_skills_run.gd`: collection and usage of all 8 skills (Bone Blade, Boomerang, Stone Shield, Ground Slam, Time Shard, Magnet Relic, Air Dash, Bounce Power), collectible gems with magnet pull, animated replacement notices, and cooldown/charge HUD updates.
  - L4 Android Build Verification: Debug APK exported to `releases/Riftosaur-debug.apk` (67,382,478 bytes, SHA-256 `F269B6026965238029B94F4090E104BC0FB35DBD2F60687D878ABC4FB6B11500`). Verified via `tools/verify_apk.ps1` with `aapt2`, `zipalign`, and `apksigner`.
- **Delivered components:**
  - `SkillManager` (`scripts/systems/skill_manager.gd`): Single active skill slot managing duration, cooldown, charges, activation preconditions, and replacement notices.
  - 8 Tunable Skills:
    1. *Bone Blade:* 0.3s slash, 0.5s cooldown; destroys `BREAKABLE` hazards.
    2. *Boomerang:* Ranged looping projectile destroying `AIRBORNE` and `CRAWLER` hazards.
    3. *Stone Shield:* Absorbs 1 hit from `AIRBORNE`, `CRAWLER`, or `PROJECTILE` hazard, then breaks; never blocks `SOLID` or `ENVIRONMENTAL`.
    4. *Ground Slam:* Mid-air dive creating a 140px landing shockwave destroying `BREAKABLE` and `CRAWLER` hazards.
    5. *Time Shard:* 4.0s slow (50% speed) applied to moving, airborne, and crawler hazards.
    6. *Magnet Relic:* 6.0s magnetic aura pulling nearby amber gems directly into dinosaur.
    7. *Air Dash:* 2 charges (0.18s horizontal burst, 0.6s cooldown) refilled upon touching the ground.
    8. *Bounce Power:* 8.0s booster increasing spring launch force by +35% with cushioned bouncy landings.
  - Hazard Categories in `scripts/obstacles/hazard.gd`: Enum `Category { SOLID, BREAKABLE, AIRBORNE, CRAWLER, PROJECTILE, ENVIRONMENTAL }` with `destroy_hazard()` and `set_time_scale()`.
  - Collectibles & Pickups: `Collectible` (`scripts/objects/collectible.gd`, `scenes/objects/collectible_gem.tscn`) and `SkillPickup` (`scripts/objects/skill_pickup.gd`, `scenes/objects/skill_pickup.tscn`).
  - New Hazard Scenes: `obstacle_pterodactyl.tscn` (AIRBORNE), `obstacle_crawler.tscn` (CRAWLER), `obstacle_wooden_barrier.tscn` (BREAKABLE).
  - 3 New Hand-Authored Chunks: `chunk_13_airborne_pterodactyl.tscn`, `chunk_14_crawler_and_barrier.tscn`, `chunk_15_skill_gem_cache.tscn`.
  - Skill UI & Controls: Dedicated `SkillButton` on mobile touch overlay, HUD active skill slot with charges and cooldown overlay, gem counter label, and replacement notice toast.
  - Automated Tests: 10 new comprehensive unit tests in `tests/unit/test_skills_system.gd` registered in `tests/test_runner.gd`.
- **Bugs opened & closed:**
  - *BUG-M4-01 (Closed):* GDScript 4 primitive variable capture in test lambda prevented detection of `skill_replaced` signal. Fixed by using reference dictionary container.
  - *BUG-M4-02 (Closed):* Non-existent texture resource reference `crate_platform.png` in barrier scene. Fixed by referencing `obstacle_crate.png`.
  - *BUG-M4-03 (Closed):* Platform rise in `chunk_15` exceeded 80% maximum single jump rise in Validator V1. Fixed by adjusting platform Y to 188.0 (42px rise).
- **Files created or modified:**
  - `assets/sprites/skill_bone_blade.png`
  - `assets/sprites/skill_boomerang.png`
  - `assets/sprites/skill_stone_shield.png`
  - `assets/sprites/skill_ground_slam.png`
  - `assets/sprites/skill_time_shard.png`
  - `assets/sprites/skill_magnet_relic.png`
  - `assets/sprites/skill_air_dash.png`
  - `assets/sprites/skill_bounce_power.png`
  - `assets/sprites/collectible_gem.png`
  - `assets/sprites/pickup_skill_orb.png`
  - `assets/sprites/obstacle_pterodactyl.png`
  - `assets/sprites/obstacle_crawler.png`
  - `scripts/systems/skill_manager.gd`
  - `scripts/obstacles/hazard.gd`
  - `scripts/player/player.gd`
  - `scripts/objects/boomerang_projectile.gd`
  - `scripts/objects/collectible.gd`
  - `scripts/objects/skill_pickup.gd`
  - `scripts/gameplay/endless_runner.gd`
  - `scripts/ui/hud.gd`
  - `scenes/ui/hud.tscn`
  - `scenes/objects/collectible_gem.tscn`
  - `scenes/objects/skill_pickup.tscn`
  - `scenes/obstacles/obstacle_pterodactyl.tscn`
  - `scenes/obstacles/obstacle_crawler.tscn`
  - `scenes/obstacles/obstacle_wooden_barrier.tscn`
  - `scenes/obstacles/chunks/chunk_13_airborne_pterodactyl.tscn`
  - `scenes/obstacles/chunks/chunk_14_crawler_and_barrier.tscn`
  - `scenes/obstacles/chunks/chunk_15_skill_gem_cache.tscn`
  - `tests/unit/test_skills_system.gd`
  - `tests/test_runner.gd`
  - `tools/verify_session5_skills_run.gd`
- **Changes to plan:** None.
- **Blockers:** None.

---

### Session 4 — Vertical movement and platforms (M3)
- **Date:** 2026-11-06
- **Milestone:** M3
- **Start commit:** 00718ae (`m2-complete`)
- **End commit:** c8d8ed3 (tag: `m3-complete`)
- **Evidence levels reached:**
  - L1 Static: Zero script/parse errors, all scenes instantiable, clean project validation via `tools/validate_l1.gd`.
  - Validator V1: Analytic reach and rise fairness validation via `tools/validate_v1.gd` on all 12 chunks. All vertical platform rises conform to <= 80% maximum jump rise; all gaps conform to <= 80% horizontal reach; minimum reaction window verified.
  - L2 Automated: 35 passing automated unit and physics tests in `tests/test_runner.gd` (5 smoke + 1 replay + 9 movement + 4 save service + 8 endless runner loop + 5 vertical platform & springs).
  - L3 Desktop play: Full vertical movement, landing on elevated solid platforms, passing through and landing on one-way platforms, drop-through on down input, spring bounce pads with squash & stretch (mushrooms, stumps, launch pads, wind vents), and vertical camera tracking with dead zone.
  - L4 Android Build Verification: Debug APK exported to `releases/Riftosaur-debug.apk` (67,307,109 bytes, SHA-256 `727B3554B8A56C07ABA421A0B6EEA995A1916F1BD0542763B9F199B966E614B0`). Verified via `tools/verify_apk.ps1` with `aapt2`, `zipalign`, and `apksigner`.
- **Delivered components:**
  - `Platform` (`scripts/world/platform.gd`): Solid stone platforms (`scenes/objects/platform_solid.tscn`) and one-way wooden platforms (`scenes/objects/platform_one_way.tscn`).
  - `BouncePad` (`scripts/objects/bounce_pad.gd`): Interactive boost objects with 4 states (`IDLE`, `COMPRESSED`, `LAUNCHING`, `COOLDOWN`) across 4 variants (`scenes/objects/bounce_mushroom.tscn`, `bounce_stump.tscn`, `bounce_launchpad.tscn`, `boost_wind_vent.tscn`).
  - Contextual Descent in `scripts/player/player.gd`: Drop-through on one-way platforms via `drop_through_one_way_platform()`, slide on solid ground, and dive in mid-air.
  - Full Vertical Camera Tracking in `scripts/world/game_camera.gd`: Ground dead zone anchoring camera at baseline Y (135.0), smooth vertical follow with easing when ascending onto elevated ledges, upper camera bounds, and impact camera shake with reduce-motion option.
  - Validator V1 (`tools/validate_v1.gd`): Automated analytic verification of reach, rise, and reaction windows.
  - 4 New Hand-Authored Chunks: `chunk_09_mushroom_bounce.tscn`, `chunk_10_multi_tier_platforms.tscn`, `chunk_11_bounce_chain.tscn`, `chunk_12_wind_vent_ascent.tscn`.
- **Bugs opened & closed:**
  - *BUG-M3-01 (Closed):* Container node `Platforms` at (0,0) in `chunk_10` was matched by string name prefix in initial validator scan. Fixed by filtering for `child is Platform` or `StaticBody2D`.
  - *BUG-M3-02 (Closed):* Validator evaluated local `p.position.y` instead of chunk-relative global position for nested platforms. Fixed by using `p.global_position.y - chunk.global_position.y`.
- **Files created or modified:**
  - `assets/sprites/platform_solid.png`
  - `assets/sprites/platform_oneway.png`
  - `assets/sprites/boost_mushroom.png`
  - `assets/sprites/boost_stump.png`
  - `assets/sprites/boost_launchpad.png`
  - `assets/sprites/boost_wind_vent.png`
  - `scripts/world/platform.gd`
  - `scripts/objects/bounce_pad.gd`
  - `scripts/world/game_camera.gd`
  - `scripts/player/player.gd`
  - `scripts/gameplay/endless_runner.gd`
  - `scenes/objects/platform_solid.tscn`
  - `scenes/objects/platform_one_way.tscn`
  - `scenes/objects/bounce_mushroom.tscn`
  - `scenes/objects/bounce_stump.tscn`
  - `scenes/objects/bounce_launchpad.tscn`
  - `scenes/objects/boost_wind_vent.tscn`
  - `scenes/obstacles/chunks/chunk_09_mushroom_bounce.tscn`
  - `scenes/obstacles/chunks/chunk_10_multi_tier_platforms.tscn`
  - `scenes/obstacles/chunks/chunk_11_bounce_chain.tscn`
  - `scenes/obstacles/chunks/chunk_12_wind_vent_ascent.tscn`
  - `tools/validate_v1.gd`
  - `tools/run_tests.ps1`
  - `tests/unit/test_vertical_platforms.gd`
  - `tests/test_runner.gd`
- **Changes to plan:** None.
- **Blockers:** None.

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
  - *BUG-M2-15 (Closed):* [Owner Playtest #2 - Issue 4] Overhead slide obstacle bypassed by jumping and sliding: The overhang obstacle was only a 20×14 floating box at y = 208 with empty air above y = 201, allowing even a 30px tap jump to fly above the collision shape. Fixed by redesigning `ObstacleOverhang` into a towering 32×240 prehistoric stone archway with a 26×240 hazard collision shape and static ceiling body extending all the way off the top of the screen (y = -254) down to the 14px slide crawlspace (y = -14), making it physically and fatally impossible to jump over or dive through, strictly enforcing ground slide. Verified with automated test `test_overhang_slide_clearance_and_jump_fatal`.
  - *BUG-M2-16 (Closed):* [Owner Playtest #2 - Issue 5] Background disconnected from ground during jump: The rolling hills texture stopped at y = 225 leaving a 5px gap before ground at y = 230, and the camera moved vertically 1:1 on every jump, dropping ground by up to 84px and revealing raw blue sky between hills and ground. Fixed by: 1) Regenerating `bg_hills.png` and `bg_mountains.png` at full 480×270 height with seamless periodic waveforms so green meadows extend all the way down behind the ground track (y = 270); 2) Locking `game_camera.gd` to `baseline_y = 135.0` with deadzone during ground jumps so the camera does not jerk vertically on jumps. Verified with automated test `test_camera_ground_lock_during_jump`.
  - *BUG-M2-17 (Closed):* [Owner Playtest #2 - Issue 6] Mode 0 (Casual) was boring and lacked challenge: Mode 0 ran at a flat 240 px/s with only 1 single cactus hurdle pattern. Overhauled Mode 0 into high-intensity "1. SPICY JUMP" arcade mode: 1) Dynamic acceleration speed curve starting at 310 px/s and ramping up with distance to 520 px/s; 2) Built 3 new procedural chunk scenes (`chunk_06_crate_step.tscn`, `chunk_07_triple_low.tscn`, `chunk_08_double_crate.tscn`) adding double hurdles, triple rhythm hurdles, and stepping crate launchpads; 3) Enabled full-screen tap-to-jump on touch devices for responsive one-touch arcade play.
  - *BUG-M2-18 (Closed):* [Feature Request - Challenges, Points, and Skin Shop] Added full in-game economy and progression: 1) Persistent Points currency system saved in `SaveService` with 50 PTS welcome bonus and distance/score earnings per run; 2) 8-quest Challenge tracker (`ChallengeService`) monitoring jumps, slides, distances, and modes with animated in-game completion toasts and rewards; 3) 5 distinct dinosaur skins (Classic Charcoal, Emerald Raptor, Ruby Carnotaur, Cyber Rift, Golden Fossil) each with generated 27-frame 864×32 spritesheets and 32×32 preview icons; 4) Interactive Skin Shop & Challenges dialogs accessible from both Start Menu and Game Over screen; 5) Automated tests expanded to 28 passing unit/physics tests. Verified with L4 Android export.
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
