"""Generate 11 additional high-tier pixel-art dinosaur skins & icons."""
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import generate_pro_dino as base

NEW_SKIN_PALETTES = {
	"cobalt": {
		"outline": (16, 36, 84, 255),
		"body":    (46, 112, 224, 255),
		"belly":   (132, 206, 255, 255),
		"spine":   (210, 245, 255, 255),
		"eye":     (255, 245, 130, 255),
	},
	"obsidian": {
		"outline": (12, 10, 20, 255),
		"body":    (36, 32, 54, 255),
		"belly":   (88, 76, 128, 255),
		"spine":   (190, 90, 255, 255),
		"eye":     (255, 72, 120, 255),
	},
	"amethyst": {
		"outline": (48, 16, 78, 255),
		"body":    (138, 52, 208, 255),
		"belly":   (212, 148, 255, 255),
		"spine":   (255, 200, 255, 255),
		"eye":     (120, 255, 230, 255),
	},
	"inferno": {
		"outline": (64, 14, 8, 255),
		"body":    (220, 68, 18, 255),
		"belly":   (255, 168, 40, 255),
		"spine":   (255, 244, 140, 255),
		"eye":     (255, 255, 255, 255),
	},
	"plasma": {
		"outline": (18, 28, 64, 255),
		"body":    (0, 198, 212, 255),
		"belly":   (128, 255, 244, 255),
		"spine":   (255, 68, 204, 255),
		"eye":     (255, 255, 110, 255),
	},
	"jade_emperor": {
		"outline": (10, 48, 36, 255),
		"body":    (24, 178, 128, 255),
		"belly":   (150, 248, 204, 255),
		"spine":   (255, 214, 72, 255),
		"eye":     (255, 240, 180, 255),
	},
	"crimson_rex": {
		"outline": (54, 6, 18, 255),
		"body":    (176, 18, 48, 255),
		"belly":   (242, 92, 116, 255),
		"spine":   (255, 224, 190, 255),
		"eye":     (255, 232, 64, 255),
	},
	"celestial": {
		"outline": (26, 28, 86, 255),
		"body":    (88, 114, 238, 255),
		"belly":   (198, 224, 255, 255),
		"spine":   (255, 236, 128, 255),
		"eye":     (255, 255, 255, 255),
	},
	"void_walker": {
		"outline": (8, 4, 18, 255),
		"body":    (28, 14, 64, 255),
		"belly":   (110, 44, 190, 255),
		"spine":   (0, 245, 212, 255),
		"eye":     (255, 60, 220, 255),
	},
	"diamond_apex": {
		"outline": (24, 68, 96, 255),
		"body":    (110, 226, 255, 255),
		"belly":   (210, 250, 255, 255),
		"spine":   (255, 255, 255, 255),
		"eye":     (32, 128, 255, 255),
	},
	"chromatic_god": {
		"outline": (42, 14, 68, 255),
		"body":    (248, 86, 168, 255),
		"belly":   (104, 248, 216, 255),
		"spine":   (255, 232, 82, 255),
		"eye":     (255, 255, 255, 255),
	},
}

def main():
	os.makedirs("assets/sprites", exist_ok=True)
	for skin_id, pal in NEW_SKIN_PALETTES.items():
		sheet = Image.new("RGBA", (32 * 27, 32), (0, 0, 0, 0))
		for f in range(27):
			fx = f * 32
			if f in (0, 1):
				base.draw_template(sheet, fx, 0, base.UPRIGHT_BODY, pal, leg_mode=0)
			elif 2 <= f <= 7:
				lm = 1 if (f % 2 == 0) else 2
				by = -1 if (f in (3, 6)) else 0
				base.draw_template(sheet, fx, by, base.UPRIGHT_BODY, pal, leg_mode=lm)
			elif f in (8, 9, 10):
				base.draw_template(sheet, fx, -1, base.UPRIGHT_BODY, pal, leg_mode=3)
			elif f == 11:
				base.draw_template(sheet, fx, 1, base.UPRIGHT_BODY, pal, leg_mode=0)
			elif f in (12, 13, 14, 15):
				base.draw_template(sheet, fx, 0, base.SLIDE_BODY, pal)
			elif f in (16, 17, 18):
				base.draw_template(sheet, fx, 0, base.UPRIGHT_BODY, pal, leg_mode=3)
			else:
				base.draw_template(sheet, fx, 0, base.DEAD_BODY, pal)

		sheet_path = f"assets/sprites/dinosaur_sheet_{skin_id}.png"
		sheet.save(sheet_path)
		icon = sheet.crop((64, 0, 96, 32)).resize((48, 48), Image.NEAREST)
		icon_path = f"assets/sprites/skin_icon_{skin_id}.png"
		icon.save(icon_path)
		print(f"Generated {skin_id}: {sheet_path}, {icon_path}")

if __name__ == "__main__":
	main()
