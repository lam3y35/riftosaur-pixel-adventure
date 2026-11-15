"""
Pro App Icon Processor for Riftosaur.
Processes the high-res master pixel-art illustration into all required desktop
and Android launcher icon densities, including Android 8+ Adaptive Icon
432x432 foreground and background layers.
"""

import os
import shutil
from PIL import Image

MASTER_ARTIFACT = r"C:\Users\Tweety\.gemini\antigravity\brain\e7436405-7dfd-425c-8d24-1662af91fce4\riftosaur_app_icon_fullbleed_1793908777986.jpg"
MASTER_LOCAL = "assets/icons/android/icon_master.png"

def generate_pro_icon():
    os.makedirs("assets/icons/android", exist_ok=True)

    if os.path.exists(MASTER_ARTIFACT):
        img = Image.open(MASTER_ARTIFACT).convert("RGBA")
        img.save(MASTER_LOCAL)
    elif os.path.exists(MASTER_LOCAL):
        img = Image.open(MASTER_LOCAL).convert("RGBA")
    else:
        raise FileNotFoundError("Master icon not found!")

    # 1. Save 512x512 main project icon & Android 512 icon
    icon_512 = img.resize((512, 512), resample=Image.LANCZOS)
    icon_512.save("assets/icon.png")
    icon_512.save("assets/icons/android/icon_512.png")

    # 2. Save standard Android densities
    densities = {
        "icon_48.png": 48,
        "icon_72.png": 72,
        "icon_96.png": 96,
        "icon_144.png": 144,
        "icon_192.png": 192,
    }
    for filename, sz in densities.items():
        scaled = img.resize((sz, sz), resample=Image.LANCZOS)
        scaled.save(f"assets/icons/android/{filename}")

    # 3. Generate Android Adaptive Icon (432x432)
    # Background: smooth deep cosmic indigo radial/vertical gradient (100% opaque, zero seam)
    bg_432 = Image.new("RGBA", (432, 432), (20, 16, 48, 255))
    bg_px = bg_432.load()
    for py in range(432):
        ty = py / 431.0
        for px in range(432):
            dx = (px - 216.0) / 216.0
            dy = (py - 216.0) / 216.0
            radial = max(0.0, 1.0 - (dx * dx + dy * dy) ** 0.5)
            r = int(18 + 22 * radial + 8 * ty)
            g = int(14 + 20 * radial + 6 * ty)
            b = int(46 + 44 * radial + 14 * (1.0 - ty))
            bg_px[px, py] = (r, g, b, 255)
    bg_432.save("assets/icons/android/icon_background_432.png")

    # Foreground 432x432: centered 312x312 hero inside Android 66% (288px) safe zone
    # with feathered circular alpha mask so outer corners remain transparent (0..255 alpha).
    inner_sz = 312
    offset = (432 - inner_sz) // 2
    inner_img = img.resize((inner_sz, inner_sz), resample=Image.LANCZOS)
    fg_432 = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    fg_432.paste(inner_img, (offset, offset))
    fg_px = fg_432.load()
    r_inner = 134.0
    r_outer = 156.0
    for py in range(432):
        for px in range(432):
            dist = ((px - 215.5) ** 2 + (py - 215.5) ** 2) ** 0.5
            r, g, b, a = fg_px[px, py]
            if dist >= r_outer:
                fg_px[px, py] = (0, 0, 0, 0)
            elif dist > r_inner:
                t = (dist - r_inner) / (r_outer - r_inner)
                fade = 0.5 * (1.0 + __import__("math").cos(t * __import__("math").pi))
                fg_px[px, py] = (r, g, b, int(a * fade))
    fg_432.save("assets/icons/android/icon_foreground_432.png")

    print("Generated all high-res Riftosaur app icons (48..512px + 432px Adaptive Icons).")

if __name__ == "__main__":
    generate_pro_icon()
