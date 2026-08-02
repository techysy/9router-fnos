#!/usr/bin/env python3
"""生成 9Router fnOS 应用图标：对角渐变圆角方块 + 白色空心hub图标。
官方样式：1 个中心大空心圆环 + 5 个外围小空心圆环(五边形分布) + 5条直线连接。
"""
from PIL import Image, ImageDraw
import math

def lerp(a, b, t):
    return int(a + (b - a) * t)

def make_gradient_bg(w, h, c1, c2, radius):
    img = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(img)
    for y in range(h):
        for x in range(w):
            t = (x + y) / (w + h - 2)
            d.point((x, y), fill=(lerp(c1[0],c2[0],t), lerp(c1[1],c2[1],t), lerp(c1[2],c2[2],t), 255))
    mask = Image.new("L", (w, h), 0)
    dm = ImageDraw.Draw(mask)
    dm.rounded_rectangle([0,0,w-1,h-1], radius=radius, fill=255)
    img.putalpha(mask)
    return img

def make_icon(size):
    c1, c2 = (0xE5,0x6A,0x4A), (0xa6,0x40,0x27)
    # 官方 fnOS 圆角标准: 圆角 = 边长 × 18.75% (256px → 48px)
    radius = max(2, int(size * 0.1875))
    icon = make_gradient_bg(size, size, c1, c2, radius)
    d = ImageDraw.Draw(icon)
    cx = cy = size / 2
    # 中心大圆环 与 外围小圆环 的半径
    center_r = int(size * 0.12)
    node_r   = int(size * 0.075)
    R = int(size * 0.30)            # 外围节点分布半径(中心→外围中心)
    stroke = max(2, int(size * 0.04))  # 线宽/描边
    # 5 个外围节点: 五边形分布,从顶部(-90度)顺时针
    positions = []
    for i in range(5):
        ang = math.radians(-90 + i * 72)
        x = cx + R * math.cos(ang)
        y = cy + R * math.sin(ang)
        positions.append((x, y))
    # 连接线(在下层): 从中心圆环外缘到外围圆环内缘(不穿过圆环内部)
    for (x, y) in positions:
        dx = x - cx; dy = y - cy
        dist = math.hypot(dx, dy)
        ux, uy = dx/dist, dy/dist
        x1 = cx + ux * center_r    # 中心大圆环外缘
        y1 = cy + uy * center_r
        x2 = x - ux * node_r       # 外围小圆环内缘
        y2 = y - uy * node_r
        d.line([x1, y1, x2, y2], fill=(255,255,255,255), width=stroke)
    # 中心大空心圆环
    d.ellipse([cx-center_r, cy-center_r, cx+center_r, cy+center_r], outline=(255,255,255,255), width=stroke)
    # 外围小空心圆环
    for (x, y) in positions:
        d.ellipse([x-node_r, y-node_r, x+node_r, y+node_r], outline=(255,255,255,255), width=stroke)
    return icon

for s, path in [(64,"ICON.PNG"), (256,"ICON_256.PNG"),
                (64,"app/ui/images/icon_64.png"), (128,"app/ui/images/icon_128.png"), (256,"app/ui/images/icon_256.png")]:
    make_icon(s).save(path)
    print("saved", path)
make_icon(512).save("/tmp/9router_icon_6ring_512.png")
print("preview /tmp/9router_icon_6ring_512.png")
