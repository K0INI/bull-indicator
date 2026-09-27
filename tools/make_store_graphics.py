"""Builds Play Store icon (512) and feature graphic (1024x500) from brand assets."""
from PIL import Image, ImageDraw, ImageFont
import os
os.makedirs("store/assets", exist_ok=True)
Image.open("app/assets/icon/icon.png").convert("RGB").resize((512, 512), Image.LANCZOS).save("store/assets/play-icon-512.png")
lock = Image.open("site/lockup-white.png").convert("RGBA"); lock = lock.crop(lock.getbbox())
fg = Image.new("RGBA", (1024, 500), (10, 11, 13, 255))
lock.thumbnail((640, 230), Image.LANCZOS)
y = 120
fg.alpha_composite(lock, ((1024 - lock.width) // 2, y))
d = ImageDraw.Draw(fg); f = ImageFont.truetype("site/fonts/Jost_300Light.ttf", 34)
t = "Read the cycle."; w = d.textlength(t, font=f)
d.text(((1024 - w) / 2, y + lock.height + 40), t, font=f, fill=(62, 207, 142, 255))
fg.convert("RGB").save("store/assets/play-feature-1024x500.png")
print("store graphics written")
