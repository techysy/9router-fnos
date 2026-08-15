#!/usr/bin/env python3
"""生成 9Router fnOS 应用图标：橙色渐变圆角方块 + 白色 Material 'hub' 网络拓扑图标。

官方样式（来自上游 9Router 品牌标识）：
  <div class="...bg-gradient-to-br from-brand-500 to-brand-700...">
    <span class="material-symbols-outlined text-white">hub</span>
  </div>
即：对角橙红渐变圆角方块，中央白色 Material Symbols 'hub' 图标（中心节点 + 外围节点连线）。

用法（在 repo 根目录运行）：
  python3 scripts/generate-icons.py
  生成 ICON.PNG(64) / ICON_256.PNG(256) 与 app/ui/images/icon_{64,128,256}.png
"""
import os
import subprocess
import tempfile
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Material Symbols 'hub' 图标 SVG (viewBox 0 -960 960 960), fill 白色
HUB_SVG = '''<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 -960 960 960" width="24"><path fill="white" d="M155-75q-35-35-35-85t35-85q35-35 85-35 14 0 26 3t23 8l57-71q-28-31-39-70t-5-78l-81-27q-17 25-43 40t-58 15q-50 0-85-35T0-580q0-50 35-85t85-35q50 0 85 35t35 85v8l81 28q20-36 53.5-61t75.5-32v-87q-39-11-64.5-42.5T360-840q0-50 35-85t85-35q50 0 85 35t35 85q0 42-26 73.5T510-724v87q42 7 75.5 32t53.5 61l81-28v-8q0-50 35-85t85-35q50 0 85 35t35 85q0 50-35 85t-85 35q-32 0-58.5-15T739-515l-81 27q6 39-5 77.5T614-340l57 70q11-5 23-7.5t26-2.5q50 0 85 35t35 85q0 50-35 85t-85 35q-50 0-85-35t-35-85q0-20 6.5-38.5T624-232l-57-71q-41 23-87.5 23T392-303l-56 71q11 15 17.5 33.5T360-160q0 50-35 85t-85 35q-50 0-85-35Zm-35-465q17 0 28.5-11.5T160-580q0-17-11.5-28.5T120-620q-17 0-28.5 11.5T80-580q0 17 11.5 28.5T120-540Zm148.5 408.5Q280-143 280-160t-11.5-28.5Q257-200 240-200t-28.5 11.5Q200-177 200-160t11.5 28.5Q223-120 240-120t28.5-11.5Zm240-680Q520-823 520-840t-11.5-28.5Q497-880 480-880t-28.5 11.5Q440-857 440-840t11.5 28.5Q463-800 480-800t28.5-11.5ZM480-360q42 0 71-29t29-71q0-42-29-71t-71-29q-42 0-71 29t-29 71q0 42 29 71t71 29Zm268.5 228.5Q760-143 760-160t-11.5-28.5Q737-200 720-200t-28.5 11.5Q680-177 680-160t11.5 28.5Q703-120 720-120t28.5-11.5Zm120-420Q880-563 880-580t-11.5-28.5Q857-620 840-620t-28.5 11.5Q800-597 800-580t11.5 28.5Q823-540 840-540t28.5-11.5ZM480-840ZM120-580Zm360 120Zm360-120ZM240-160Zm480 0Z"/></svg>'''


def _hub_png(size: int):
    """用 rsvg-convert 渲染白色 hub 图标为 size x size PNG."""
    svg_path = os.path.join(tempfile.gettempdir(), "hub_9router.svg")
    with open(svg_path, "w") as f:
        f.write(HUB_SVG)
    png_path = os.path.join(tempfile.gettempdir(), f"hub_9router_{size}.png")
    subprocess.run(["rsvg-convert", "-w", str(size * 2), "-h", str(size * 2),
                    svg_path, "-o", png_path], check=True)
    img = Image.open(png_path).convert("RGBA")
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    return img


def _gradient_bg(size, c1=(0xE5, 0x6A, 0x4A), c2=(0xa6, 0x40, 0x27)):
    """对角渐变圆角方块背景 (brand-500 -> brand-700)."""
    bg = Image.new("RGBA", (size, size))
    d = ImageDraw.Draw(bg)
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size - 2)
            r = int(c1[0] + (c2[0] - c1[0]) * t)
            g = int(c1[1] + (c2[1] - c1[1]) * t)
            b = int(c1[2] + (c2[2] - c1[2]) * t)
            d.point((x, y), fill=(r, g, b, 255))
    radius = max(2, int(size * 0.1875))
    mask = Image.new("L", (size, size), 0)
    dm = ImageDraw.Draw(mask)
    dm.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    bg.putalpha(mask)
    return bg


def _make_icon(size: int):
    bg = _gradient_bg(size)
    hub = _hub_png(size).resize((int(size * 0.55), int(size * 0.55)), Image.LANCZOS)
    x = (size - hub.size[0]) // 2
    y = (size - hub.size[1]) // 2
    bg.paste(hub, (x, y), hub)
    return bg


def main():
    sizes = {64: "ICON.PNG", 256: "ICON_256.PNG"}
    for size, name in sizes.items():
        icon = _make_icon(size)
        icon.save(os.path.join(ROOT, name))
        print(f"✓ {name} ({size}x{size})")

    ui_dir = os.path.join(ROOT, "app", "ui", "images")
    for size in (64, 128, 256):
        icon = _make_icon(size)
        icon.save(os.path.join(ui_dir, f"icon_{size}.png"))
        print(f"✓ app/ui/images/icon_{size}.png")


if __name__ == "__main__":
    main()
