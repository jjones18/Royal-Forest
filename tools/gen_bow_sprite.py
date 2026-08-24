#!/usr/bin/env python3
"""Generate the bow viewmodel placeholder (matches tools/gen_placeholder_sprites.py style).
Run once; outputs assets/sprites/bow.png. Delete this script after use."""
from PIL import Image, ImageDraw
import math, os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
os.makedirs(OUT, exist_ok=True)

img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

WOOD = (122, 80, 44)
WOOD_D = (88, 56, 30)
GRIP = (58, 38, 22)
STRING = (228, 222, 206)
SKIN = (196, 156, 120)
SKIN_D = (170, 130, 98)
ARROW_SHAFT = (150, 114, 66)
ARROW_HEAD = (200, 206, 216)
FLETCH = (178, 64, 52)


def thick_line(p1, p2, color, w):
    """Draw a polygon line of given thickness."""
    x1, y1 = p1
    x2, y2 = p2
    ang = math.atan2(y2 - y1, x2 - x1)
    dx, dy = math.sin(ang) * w / 2, -math.cos(ang) * w / 2
    d.polygon([(x1 + dx, y1 + dy), (x2 + dx, y2 + dy),
               (x2 - dx, y2 - dy), (x1 - dx, y1 - dy)], fill=color)


# --- bow: vertical recurve, held slightly left-of-center, seen at a slight ---
# --- angle so both limbs and the string stay readable ------------------------
# riser (rigid middle) the fist wraps
d.rounded_rectangle([104, 112, 128, 172], radius=8, fill=GRIP)
# upper limb: curves up and right from the riser
thick_line((116, 116), (134, 78), WOOD, 13)
thick_line((134, 78), (142, 44), WOOD_D, 9)
# lower limb: curves down and right from the riser
thick_line((116, 168), (132, 202), WOOD, 13)
thick_line((132, 202), (140, 234), WOOD_D, 9)
# limb tips / nock points
d.ellipse([136, 34, 148, 46], fill=WOOD_D)
d.ellipse([134, 228, 146, 240], fill=WOOD_D)

# --- string: taut between tips, drawn BEHIND the hand but OVER the limbs ------
thick_line((142, 42), (140, 232), STRING, 3)

# --- draw hand pulling the string to mid-chest (right of the grip) -----------
# forearm enters from bottom-right toward the nock point on the string
thick_line((244, 250), (186, 168), SKIN_D, 26)
# fist AT the string — fingers wrap the nock
d.rounded_rectangle([158, 138, 196, 176], radius=11, fill=SKIN)
for i in range(3):
    thick_line((166 + i * 10, 142), (163 + i * 10, 172), SKIN_D, 4)
# string bends to the fingers (drawn bow): two segments from the tips
thick_line((142, 42), (176, 152), STRING, 3)
thick_line((140, 232), (176, 160), STRING, 3)

# --- nocked arrow along the draw line, pointing up-right past the bow ---------
thick_line((168, 156), (224, 108), ARROW_SHAFT, 7)
d.polygon([(220, 102), (252, 76), (232, 118)], fill=ARROW_HEAD)     # broadhead
thick_line((172, 160), (156, 178), FLETCH, 9)                        # fletching vane
thick_line((164, 154), (149, 169), FLETCH, 6)

img.save(os.path.join(OUT, "bow.png"))
print("wrote", os.path.abspath(os.path.join(OUT, "bow.png")))
