# Changelog

All notable changes to the Riftosaur project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.2.0] - 2026-11-05 (Milestone M1: Session 2)

### Added
- Original 32×32 pixel-art dinosaur sprite sheet (`assets/sprites/dinosaur_sheet.png`) with 27 frames (idle, 6-frame run, rise, apex, fall, land squash, slide, dive, hurt, 6-frame death).
- Text source maps in `assets/sources/dinosaur_sourcemap.txt` and compilation tool `tools/generate_sprites.py`.
- 1× and 3× solid black silhouette verification in `tools/verify_silhouette.py` and `docs/evidence/`.
- Central gameplay tuning resource `resources/gameplay_config/gameplay_config.tres` and `scripts/resources/gameplay_config.gd`.
- Player state machine `scripts/player/player_state_machine.gd` with 14 discrete states.
- Responsive movement system `scripts/player/player.gd` featuring variable jump, coyote timing (0.11s), jump buffering (0.12s), sliding collision shrink, dive descent, and landing dust puff.
- Pixel-snapped horizontal camera `scripts/world/game_camera.gd` positioning dinosaur in the left third of the 480×270 viewport.
- Flat test track `scenes/gameplay/flat_test_track.tscn` with dynamic chunk pooling and test hazards.
- 8 automated physics movement unit tests in `tests/unit/test_movement.gd` (total 14 passing automated tests).
- 2-minute autonomous desktop playtest runner `tools/run_desktop_playtest.gd` with evidence log in `docs/evidence/desktop_run_2min.log`.
- `docs/DEVELOPER_GUIDE.md`, `docs/ARCHITECTURE.md`, and `docs/ASSET_LICENSES.md`.

---

## [0.1.0] - 2026-11-05 (Milestone M0: Session 1)

### Added
- Pinned Godot Engine 4.7.2-stable official and matching export templates.
- Project skeleton with standard directories (`scenes/`, `scripts/`, `assets/`, `resources/`, `tests/`, `docs/`, `tools/`).
- Configured 480×270 logical viewport with nearest-neighbor texture filtering and 2D pixel snapping in `project.godot`.
- Input action mappings for `jump`, `slide`, `skill`, and `pause`.
- Headless test runner (`tests/test_runner.gd`) and initial smoke test suite (`tests/unit/test_smoke.gd`).
- L1 static project validation script (`tools/validate_l1.gd`).
- Foundation for timestamped input recording and replay (`scripts/systems/input_replay.gd`) with test verification (`tests/unit/test_replay.gd`).
- Automated PowerShell runner (`tools/run_tests.ps1`).
- Initial preflight survey and session tracking in `docs/WORKLOG.md`.
