"""
App icon generator for Riftosaur.
Generates pixel-art app icon at all required Android mipmap densities and base project icon.
"""

import os
from PIL import Image

def generate_icons():
    os.makedirs("assets/icons/android", exist_ok=True)

    # Base design on 48x48 pixel grid
    base = Image.new("RGBA", (48, 48), (0, 0, 0, 0))

    # Border & Badge background (emerald green badge with rounded pixel corners)
    # Circle/rounded badge radius ~22
    for y in range(48):
        for x in range(48):
            dx, dy = x - 24, y - 24
            dist_sq = dx * dx + dy * dy
            if dist_sq <= 23 * 23:
                if dist_sq >= 21 * 21:
                    base.putpixel((x, y), (24, 24, 27, 255)) # Dark border
                elif dist_sq >= 19 * 19:
                    base.putpixel((x, y), (22, 101, 52, 255)) # Dark green ring
                else:
                    base.putpixel((x, y), (34, 197, 94, 255)) # Vibrant green fill

    # Dinosaur head silhouette in center
    # Head outline & fill
    dino_head = [
        # x, y, color
        # Teeth / jaw
        (28, 26), (29, 26), (30, 26), (31, 26), (32, 26),
        (26, 28), (27, 28), (28, 28), (29, 28), (30, 28)
    ]
    # Snout
    for y in range(16, 26):
        for x in range(18, 35):
            base.putpixel((x, y), (240, 253, 244, 255)) # Ivory white dinosaur head

    # Eye
    base.putpixel((24, 19), (24, 24, 27, 255))
    base.putpixel((24, 20), (24, 24, 27, 255))
    base.putpixel((25, 19), (24, 24, 27, 255))
    base.putpixel((25, 20), (24, 24, 27, 255))

    # Save base 48x48
    base.save("assets/icons/android/icon_48.png")
    base.save("assets/icon.png")

    # Generate other densities using nearest neighbor scaling to keep pixel art sharp
    densities = {
        "icon_72.png": 72,
        "icon_96.png": 96,
        "icon_144.png": 144,
        "icon_192.png": 192,
        "icon_512.png": 512
    }
    for filename, sz in densities.items():
        scaled = base.resize((sz, sz), resample=Image.NEAREST)
        scaled.save(f"assets/icons/android/{filename}")

    print("Generated app icons at 48, 72, 96, 144, 192, and 512 px.")

if __name__ == "__main__":
    generate_icons()
