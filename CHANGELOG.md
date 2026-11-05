# Changelog

All notable changes to the Riftosaur project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
