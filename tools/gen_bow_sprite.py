#!/usr/bin/env python3
"""Generate the bow viewmodel set (idle + 3 Minecraft-style pull stages).
All frames share identical bow geometry; only the string V, hand position,
and nocked arrow change. Outputs assets/sprites/bow*.png."""
from PIL import Image, ImageDraw
import math, os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
os.makedirs(OUT, exist_ok=True)

WOOD = (122, 80, 44)
WOOD_D = (88, 56, 30)
GRIP = (58, 38, 22)
STRING = (228, 222, 206)
SKIN = (196, 156, 120)
SKIN_D = (170, 130, 98)
ARROW_SHAFT = (150, 114, 66)
ARROW_HEAD = (200, 206, 216)
FLETCH = (178, 64, 52)


def thick_line(d, p1, p2, color, w):
    x1, y1 = p1
    x2, y2 = p2
    ang = math.atan2(y2 - y1, x2 - y1 if False else x2 - x1)
    ang = math.atan2(y2 - y1, x2 - x1)
    dx, dy = math.sin(ang) * w / 2, -math.cos(ang) * w / 2
    d.polygon([(x1 + dx, y1 + dy), (x2 + dx, y2 + dy),
               (x2 - dx, y2 - dy), (x1 - dx, y1 - dy)], fill=color)


def draw_bow_frame(name, hand, arrow_tail=None):
    """hand: (x,y) fist center on the string. arrow_tail: (x,y) or None."""
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # ---- bow geometry: identical every frame ------------------------------
    d.rounded_rectangle([104, 112, 128, 172], radius=8, fill=GRIP)   # riser
    thick_line(d, (116, 116), (134, 78), WOOD, 13)                   # upper limb
    thick_line(d, (134, 78), (142, 44), WOOD_D, 9)
    thick_line(d, (116, 168), (132, 202), WOOD, 13)                  # lower limb
    thick_line(d, (132, 202), (140, 234), WOOD_D, 9)
    d.ellipse([136, 34, 148, 46], fill=WOOD_D)                       # top tip
    d.ellipse([134, 228, 146, 240], fill=WOOD_D)                     # bottom tip

    hx, hy = hand
    if arrow_tail is None:
        # relaxed: straight string between the tips
        thick_line(d, (142, 42), (140, 232), STRING, 3)
        # resting grip hand
        d.rounded_rectangle([hx - 14, hy - 18, hx + 20, hy + 18],
                            radius=10, fill=SKIN)
    else:
        tx, ty = hand[0] - 3, hand[1] - 10     # string meets hand (top)
        bx, by = hand[0] - 3, hand[1] + 8      # string meets hand (bottom)
        thick_line(d, (142, 42), (tx, ty), STRING, 3)
        thick_line(d, (140, 232), (bx, by), STRING, 3)

        # nocked arrow: whole arrow translated back with the hand
        ax, ay = arrow_tail
        head = (ax + 56, ay - 46)
        thick_line(d, (ax, ay), head, ARROW_SHAFT, 7)
        d.polygon([(head[0] - 4, head[1] + 4),
                   (head[0] + 26, head[1] - 22),
                   (head[0] + 8, head[1] + 12)], fill=ARROW_HEAD)
        thick_line(d, (ax + 2, ay + 2), (ax - 12, ay + 16), FLETCH, 9)
        thick_line(d, (ax - 4, ay - 4), (ax - 17, ay + 7), FLETCH, 6)

        # draw arm reaching in from bottom-right to the string
        thick_line(d, (246, 252), (hx + 16, hy + 24), SKIN_D, 26)
        d.rounded_rectangle([hx - 16, hy - 16, hx + 22, hy + 20],
                            radius=11, fill=SKIN)
        for i in range(3):
            thick_line(d, (hx - 8 + i * 10, hy - 12),
                       (hx - 11 + i * 10, hy + 14), SKIN_D, 4)

    img.save(os.path.join(OUT, name))
    print("wrote", name)


draw_bow_frame("bow.png", (141, 139))                      # idle
draw_bow_frame("bow_pull_1.png", (157, 144), (151, 156))   # quarter draw
draw_bow_frame("bow_pull_2.png", (175, 148), (169, 160))   # half draw
draw_bow_frame("bow_pull_3.png", (193, 152), (187, 164))   # full draw
