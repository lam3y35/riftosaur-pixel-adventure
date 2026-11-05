# Riftosaur Architectural Decisions & Trade-Offs

This document records the foundational architectural decisions, rationale, and rejected alternatives for **Riftosaur**.

---

## 1. Engine & Version Pin

- **Decision:** Godot Engine 4.7.2-stable official (`ed1daf0bf`).
- **Rationale:** Pinned locally with verified matching export templates for Windows, Linux, Web, and Android. Offers strong 2D physics stability, typed GDScript 2.0, and fast headless startup.
- **Alternatives Rejected:** Godot 3.5 (older LTS, lacks modern GDScript typing and improved mobile renderers), Godot 4.8-dev/unstable (risk of regressions in export pipelines).

---

## 2. Logical Viewport & Pixel Snapping

- **Decision:** 480 × 270 viewport (`viewport` stretch mode, `keep` aspect ratio) with nearest-neighbor texture filtering and 2D pixel snapping (`snap_2d_transforms_to_pixel`, `snap_2d_vertices_to_pixel`).
- **Rationale:** 480 × 270 is an exact integer factor of common display resolutions (1080p is $4\times$, 1440p is $5.33\times$, 720p is $2.67\times$, 4K is $8\times$). It provides ample canvas for platforming reaction times while preserving true 16-bit retro aesthetic.
- **Alternatives Rejected:** Free resolution with linear filtering (causes pixel blurring and inconsistent sprite outlines), 320 × 180 (too cramped for high-speed forward reaction times).

---

## 3. Physics-Tick Movement & Input Timing

- **Decision:** All character motion, velocity updates, and input timer windows (`jump_buffer_timer`, `coyote_timer`, `jump_hold_timer`) run in physics time within `_physics_process(delta)`.
- **Rationale:** Ensures deterministic behavior across variable refresh rates (60 Hz, 90 Hz, 120 Hz, 144 Hz). Coyote and buffer windows represent physical seconds rather than arbitrary frame counts.
- **Alternatives Rejected:** Variable `_process(delta)` motion (leads to inconsistent jump heights and clipping under framerate drops).

---

## 4. Player State Machine

- **Decision:** Explicit state machine with 14 discrete states:
  `IDLE`, `RUN`, `JUMP_RISE`, `JUMP_APEX`, `JUMP_FALL`, `LAND`, `SLIDE`, `DIVE`, `DROP_THROUGH`, `AIR_DASH`, `FLIGHT`, `HURT`, `DEAD`, `RESPAWN`.
- **Rationale:** Prevents contradictory or invalid state combinations (e.g., sliding while dead, or attacking while in apex). Provides clear transitions and state timing queries (`time_in_state`).
- **Alternatives Rejected:** Ad-hoc boolean flags (`is_jumping`, `is_sliding`, `is_dead`), which lead to combinatorial bugs and stuck inputs during interrupts.

---

## 5. Centralized Configuration Resource

- **Decision:** Single central `GameplayConfig` resource (`resources/gameplay_config/gameplay_config.tres`).
- **Rationale:** Unifies all tunable game parameters (gravity, jump velocities, slide dimensions, speeds, coyote windows) into a single inspectable resource without hardcoding magic numbers in logic.
- **Alternatives Rejected:** Constants scattered across individual GDScript files.

---

## 6. Rendering Method

- **Decision:** `gl_compatibility` (OpenGL ES 3.0 / WebGL 2.0).
- **Rationale:** Maximum compatibility across older and budget Android devices without Vulkan driver prerequisites, with low power consumption and rapid shader initialization.
- **Alternatives Rejected:** `forward_plus` (designed for high-end 3D desktop), `mobile` (Vulkan-based, higher memory footprint and compatibility issues on older budget chipsets).
