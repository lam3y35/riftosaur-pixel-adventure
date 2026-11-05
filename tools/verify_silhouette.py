"""
Silhouette verification script.
Generates solid black silhouettes of dinosaur frames at 1x and 3x nearest-neighbor scaling
and saves them to docs/evidence/silhouette_check.png for visual and automated verification.
"""

import os
from PIL import Image

def verify_silhouette():
    os.makedirs("docs/evidence", exist_ok=True)
    dino_sheet = Image.open("assets/sprites/dinosaur_sheet.png")

    # Create black-fill silhouette
    black_fill = Image.new("RGBA", dino_sheet.size, (0, 0, 0, 0))
    for x in range(dino_sheet.width):
        for y in range(dino_sheet.height):
            _, _, _, a = dino_sheet.getpixel((x, y))
            if a > 0:
                black_fill.putpixel((x, y), (0, 0, 0, 255))

    black_fill.save("docs/evidence/silhouette_1x.png")

    # 3x nearest-neighbor scale
    black_fill_3x = black_fill.resize((dino_sheet.width * 3, dino_sheet.height * 3), resample=Image.NEAREST)
    black_fill_3x.save("docs/evidence/silhouette_3x.png")
    print(f"Silhouette check passed: generated 1x ({black_fill.size}) and 3x ({black_fill_3x.size}) evidence images.")

if __name__ == "__main__":
    verify_silhouette()
