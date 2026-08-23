#!/usr/bin/env python3
"""Generate placeholder pixel-art textures for Royal Forest (day-one build).
Run once; outputs PNGs into assets/sprites/. Delete this script after use."""
from PIL import Image, ImageDraw
import os, math, random

OUT = os.path.join(os.path.dirname(__file__), "assets", "sprites")
os.makedirs(OUT, exist_ok=True)
rng = random.Random(7)


def save(img, name):
    img.save(os.path.join(OUT, name))
    print("wrote", name)


def px(d, x, y, c, w=1, h=1):
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=c)


# ---------------- shambler: 64x64 zombie-ish humanoid, front view -------------
S = 64
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
SKIN = [(96, 118, 82), (82, 102, 70), (110, 134, 94)]      # sickly greens
RAG = [(70, 60, 78), (58, 50, 66), (84, 72, 94)]           # dark rags
EYE = (210, 60, 40)
# legs
px(d, 22, 46, RAG[1], 8, 18)
px(d, 34, 46, RAG[2], 8, 18)
# torso (ragged tunic)
for yy in range(24, 48):
    for xx in range(18, 46):
        if rng.random() < 0.12:
            continue  # ragged edges
        d.point((xx, yy), fill=rng.choice(RAG))
# arms hang low
px(d, 10, 26, SKIN[0], 8, 20)
px(d, 46, 26, SKIN[2], 8, 20)
# head
d.rectangle([22, 6, 41, 23], fill=SKIN[1])
px(d, 22, 6, SKIN[0], 4, 4)   # hair patch
px(d, 36, 16, SKIN[2], 6, 2)  # jaw shadow
# eyes glow red
px(d, 26, 13, EYE, 3, 3)
px(d, 35, 13, EYE, 3, 3)
# mouth
px(d, 28, 19, (40, 30, 30), 8, 2)
save(img, "shambler.png")

# ---------------- crawler: 48x32 spidery thing -------------------------------
img = Image.new("RGBA", (48, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
BODY = (74, 52, 88)
LEG = (52, 38, 62)
# legs (angular)
for i, sx in enumerate((4, 14, 30, 40)):
    side = 1 if i < 2 else -1
    d.line([(sx + 2, 14), (sx, 26), (sx + 6 * side, 30)], fill=LEG, width=2)
    d.line([(sx + 2, 14), (sx + 4, 27), (sx - 4 * side, 30)], fill=LEG, width=2)
# body
d.ellipse([12, 6, 35, 20], fill=BODY)
d.ellipse([15, 9, 25, 17], fill=(92, 68, 108))
# eyes cluster
for ex, ey in ((17, 11), (21, 10), (25, 12), (29, 11)):
    px(d, ex, ey, (230, 170, 40), 2, 2)
save(img, "crawler.png")

# ---------------- sword viewmodel: 256x256 held sword w/ arm, bottom-right ---
img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
BLADE = [(200, 206, 216), (160, 168, 182), (228, 232, 240)]
GRIP = (86, 58, 38)
GUARD = (150, 126, 66)
GAUNTLET = (70, 70, 82)
GAUNTLET_D = (52, 52, 62)
SKIN = (196, 156, 120)

def thick_line(p1, p2, color, w):
    """Draw a polygon line of given thickness."""
    x1, y1 = p1
    x2, y2 = p2
    ang = math.atan2(y2 - y1, x2 - x1)
    dx, dy = math.sin(ang) * w / 2, -math.cos(ang) * w / 2
    d.polygon([(x1 + dx, y1 + dy), (x2 + dx, y2 + dy),
               (x2 - dx, y2 - dy), (x1 - dx, y1 - dy)], fill=color)

# forearm entering from bottom-right, angled up-left toward grip
thick_line((236, 250), (168, 178), GAUNTLET, 34)
# gauntlet cuff
d.polygon([(214, 226), (246, 258), (254, 246), (222, 214)], fill=GAUNTLET_D)
# fist gripping the handle area
d.rounded_rectangle([128, 118, 176, 166], radius=12, fill=SKIN)
# finger lines over the grip
for i in range(3):
    thick_line((136 + i * 12, 122), (132 + i * 12, 158), (170, 130, 98), 4)

# grip under the fingers
thick_line((140, 124), (112, 152), GRIP, 14)
# pommel
d.ellipse([96, 142, 118, 164], fill=GUARD)

# crossguard perpendicular to blade axis
d.ellipse([116, 96, 134, 114], fill=GUARD)   # upper guard boss
d.ellipse([146, 126, 164, 144], fill=GUARD)  # lower guard boss

# blade — thick tapered polygon from guard up-right, with fuller + highlight
blade_pts = [(122, 108), (206, 40), (216, 50), (148, 118)]
d.polygon(blade_pts, fill=BLADE[0])
# tip triangle
d.polygon([(206, 40), (232, 18), (216, 50)], fill=BLADE[2])
# edge highlight along lower edge
thick_line((128, 110), (212, 44), BLADE[2], 3)
# central fuller
thick_line((134, 104), (200, 46), BLADE[1], 5)
save(img, "sword.png")

# ---------------- key sprite: 32x32 ------------------------------------------
img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
GOLD = (222, 178, 60)
GOLD_D = (160, 122, 34)
d.ellipse([4, 6, 14, 16], outline=GOLD, width=3)          # bow (ring)
d.line([(14, 11), (27, 11)], fill=GOLD, width=3)          # shaft
d.line([(23, 11), (23, 17)], fill=GOLD, width=3)          # teeth
d.line([(27, 11), (27, 15)], fill=GOLD_D, width=3)
px(d, 6, 8, GOLD_D, 2, 2)
save(img, "key.png")

# ---------------- chest: 48x40, front view, closed ---------------------------
img = Image.new("RGBA", (48, 40), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
WOOD = (122, 80, 44)
WOOD_D = (92, 58, 30)
IRON = (120, 124, 132)
# body
d.rectangle([4, 16, 43, 37], fill=WOOD_D)
for xx in range(4, 44, 8):
    px(d, xx, 16, WOOD, 4, 22)
# lid (slightly domed)
d.rectangle([4, 8, 43, 16], fill=WOOD)
d.arc([4, 4, 43, 18], 180, 360, fill=WOOD_D, width=2)
# iron bands
px(d, 4, 14, IRON, 40, 3)
px(d, 4, 33, IRON, 40, 3)
px(d, 20, 8, IRON, 8, 30)
# lock plate
px(d, 21, 20, IRON, 6, 8)
px(d, 23, 26, (40, 40, 46), 2, 3)
save(img, "chest_closed.png")

# same but lid open (dark opening on top half)
open_img = img.copy()
od = ImageDraw.Draw(open_img)
od.rectangle([6, 9, 41, 17], fill=(18, 12, 8))
od.rectangle([6, 9, 41, 12], fill=WOOD_D)
save(open_img, "chest_open.png")

# ---------------- locked door: 48x64 -----------------------------------------
img = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
PLANK = (98, 66, 38)
PLANK_D = (74, 48, 26)
BAND = (110, 112, 120)
d.rounded_rectangle([2, 2, 45, 61], radius=6, fill=PLANK)
for xx in range(2, 46, 9):
    px(d, xx + 4, 2, PLANK_D, 1, 60)
# iron bands + rivets
px(d, 2, 12, BAND, 44, 4)
px(d, 2, 46, BAND, 44, 4)
for xx in range(6, 44, 12):
    px(d, xx, 13, (160, 162, 170), 2, 2)
    px(d, xx, 47, (160, 162, 170), 2, 2)
# keyhole plate
px(d, 19, 26, BAND, 10, 14)
px(d, 23, 29, (20, 20, 24), 3, 5)
px(d, 23, 33, (20, 20, 24), 3, 4)
save(img, "door_locked.png")

# ---------------- stone wall tile: 64x64, tileable ---------------------------
img = Image.new("RGB", (64, 64), (58, 58, 66))
d = ImageDraw.Draw(img)
rng = random.Random(3)
row_h = 16
for row in range(4):
    y = row * row_h
    offset = 0 if row % 2 == 0 else 16
    x = -offset
    while x < 64:
        w = rng.choice((24, 30, 36))
        shade = rng.randint(-8, 8)
        base = (58 + shade, 58 + shade, 66 + shade)
        d.rectangle([x + 1, y + 1, min(x + w - 1, 63), y + row_h - 1],
                    fill=base,
                    outline=(42, 42, 50))
        # a few darker speckles
        for _ in range(6):
            sx = rng.randint(x + 2, max(x + 2, min(x + w - 2, 63)))
            sy = rng.randint(y + 2, y + row_h - 2)
            d.point((sx, sy), fill=(46, 46, 54))
        x += w
save(img.convert("RGBA"), "wall_stone.png")

print("all placeholder textures generated in", OUT)
