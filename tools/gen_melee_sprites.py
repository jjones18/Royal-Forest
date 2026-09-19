#!/usr/bin/env python3
"""Generate spear + axe melee viewmodels (day-one placeholder style).
Outputs assets/sprites/{spear,axe}.png."""
from PIL import Image, ImageDraw
import math, os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
os.makedirs(OUT, exist_ok=True)

SKIN = (196, 156, 120)
SKIN_D = (170, 130, 98)
GAUNTLET = (70, 70, 82)
GAUNTLET_D = (52, 52, 62)


def thick_line(d, p1, p2, color, w):
    x1, y1 = p1
    x2, y2 = p2
    ang = math.atan2(y2 - y1, x2 - x1)
    dx, dy = math.sin(ang) * w / 2, -math.cos(ang) * w / 2
    d.polygon([(x1 + dx, y1 + dy), (x2 + dx, y2 + dy),
               (x2 - dx, y2 - dy), (x1 - dx, y1 - dy)], fill=color)


def arm_and_fist(d, fx, fy):
    thick_line(d, (244, 250), (fx + 22, fy + 30), GAUNTLET, 32)
    d.polygon([(222, 228), (250, 256), (256, 248), (230, 220)], fill=GAUNTLET_D)
    d.rounded_rectangle([fx - 18, fy - 18, fx + 22, fy + 18], radius=11, fill=SKIN)
    for i in range(3):
        thick_line(d, (fx - 10 + i * 11, fy - 12), (fx - 13 + i * 11, fy + 14), SKIN_D, 4)


# ---------------- spear: long haft diagonal up-left, leaf head ----------------
img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
HAFT = (110, 76, 44)
HAFT_D = (84, 56, 32)
HEAD = (198, 204, 214)
HEAD_D = (150, 156, 168)

arm_and_fist(d, 150, 170)
# haft runs past the fist both ways
thick_line(d, (196, 216), (60, 60), HAFT, 10)
thick_line(d, (60, 60), (48, 48), HAFT_D, 8)
# leaf-shaped head at the upper-left end
d.polygon([(56, 56), (18, 14), (36, 52), (14, 34)], fill=HEAD)
thick_line(d, (46, 46), (24, 22), HEAD_D, 3)
# binding where head meets shaft
thick_line(d, (66, 66), (54, 54), (60, 42, 26), 9)
img.save(os.path.join(OUT, "spear.png"))
print("wrote spear.png")

# ---------------- axe: heavy bearded blade on a short haft --------------------
img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
HAFT_A = (104, 72, 42)
BLADE = (188, 194, 204)
BLADE_M = (140, 146, 158)
BIND = (150, 126, 66)

# haft FIRST so the fist wraps OVER it
thick_line(d, (196, 214), (86, 80), HAFT_A, 11)          # haft
thick_line(d, (86, 80), (78, 74), HAFT_A, 11)            # butt past the fist
# crescent blade at the top end, cutting edge up-left
d.polygon([(88, 92), (30, 22), (58, 16), (96, 58)], fill=BLADE)
d.polygon([(84, 86), (44, 34), (62, 30), (90, 60)], fill=BLADE_M)   # inner face
thick_line(d, (34, 26), (60, 18), BLADE, 5)              # edge highlight
# binding collar
thick_line(d, (100, 98), (86, 80), BIND, 10)

arm_and_fist(d, 148, 176)   # drawn LAST — hand in front of the haft
img.save(os.path.join(OUT, "axe.png"))
print("wrote axe.png")
