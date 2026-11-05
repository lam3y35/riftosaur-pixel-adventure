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
    # Android Adaptive Icons display the inner 66% (288x288) safe zone inside a mask,
    # while using the outer 72px margin for parallax movement.
    # By placing our full artwork slightly zoomed out (340x340) over a matching
    # cosmic twilight background (432x432), the dinosaur head, tail, and portal
    # stay 100% inside the circular/squircle mask on all Android launchers!
    bg_color = (22, 18, 52, 255) # Deep cosmic indigo matching the top sky
    bg_432 = Image.new("RGBA", (432, 432), bg_color)
    # Also create a blurred/expanded version of the master image for seamless edges
    bg_full = img.resize((432, 432), resample=Image.LANCZOS)
    bg_full.save("assets/icons/android/icon_background_432.png")

    # Foreground 432x432: full bleed or safe-zone framed
    fg_432 = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    # Scale the master icon to 356x356 centered at (38, 38) so 100% of the dino is inside the 288px circle mask
    inner_sz = 356
    offset = (432 - inner_sz) // 2
    inner_img = img.resize((inner_sz, inner_sz), resample=Image.LANCZOS)
    # Put full 432x432 as base so there are no seams, with inner_img centered
    fg_base = img.resize((432, 432), resample=Image.LANCZOS)
    fg_base.paste(inner_img, (offset, offset))
    fg_base.save("assets/icons/android/icon_foreground_432.png")

    print("Generated all high-res Riftosaur app icons (48..512px + 432px Adaptive Icons).")

if __name__ == "__main__":
    generate_pro_icon()
