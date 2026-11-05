# Riftosaur Asset Provenance & Licenses

This document tracks the author, provenance, and license terms for all art, audio, font, and asset files in **Riftosaur**.

---

## Asset Provenance Register

| Asset | Category | Author | Source URL | License | Files Used | Modifications |
|---|---|---|---|---|---|---|
| **Dinosaur Sprite Sheet** | Sprite / Animation | Riftosaur Team (Original) | `assets/sources/dinosaur_sourcemap.txt` | CC0 1.0 Universal (Public Domain) | `assets/sprites/dinosaur_sheet.png` | Hand-crafted text source maps compiled via `tools/generate_sprites.py`. |
| **Landing Dust Puff** | Particle FX | Riftosaur Team (Original) | `tools/generate_sprites.py` | CC0 1.0 Universal (Public Domain) | `assets/sprites/dust_puff.png` | Procedural 4-frame 16×16 dust animation. |
| **Ground Tiles** | Environment / Tileset | Riftosaur Team (Original) | `tools/generate_sprites.py` | CC0 1.0 Universal (Public Domain) | `assets/sprites/ground_tile.png` | 16×16 pixel-art ground surface and fill tile. |
| **Obstacles (Low & Overhang)** | Obstacle / Hazard | Riftosaur Team (Original) | `tools/generate_sprites.py` | CC0 1.0 Universal (Public Domain) | `assets/sprites/obstacle_low.png`, `assets/sprites/obstacle_high.png` | Original 16×24 ground obstacle and 24×32 overhang barrier. |

---

## Policy

- All characters, hazards, and UI assets are original pixel art generated from version-controlled text maps in `assets/sources/`.
- No proprietary or third-party copyrighted assets without explicit open-source licenses (CC0, CC-BY, SIL OFL) are permitted.
