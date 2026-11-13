#!/usr/bin/env python3
"""Generate WedGo launcher icons (pure stdlib, no Pillow needed).

Writes android/app/src/main/res/mipmap-*/ic_launcher.png: solid deep-rose
background (#a4133c) with a white bitmap "W". Run in CI before the build
because the PNGs are binary and cannot travel through the text-only GitHub
snapshot push; also safe to run locally.
"""
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")

BG = (0xA4, 0x13, 0x3C)  # WedGo deep rose
FG = (0xFF, 0xFF, 0xFF)  # white

# 5x7 bitmap "W"
W = [
    "10001",
    "10001",
    "10001",
    "10001",
    "10101",
    "10101",
    "01010",
]

SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def png_chunk(kind, data):
    chunk = kind + data
    return struct.pack(">I", len(data)) + chunk + struct.pack(">I", zlib.crc32(chunk) & 0xFFFFFFFF)


def write_png(path, size):
    scale = max(1, size // 10)
    gw, gh = 5 * scale, 7 * scale
    ox, oy = (size - gw) // 2, (size - gh) // 2
    raw = bytearray()
    for y in range(size):
        raw.append(0)  # filter: none
        for x in range(size):
            on = False
            if ox <= x < ox + gw and oy <= y < oy + gh:
                on = W[(y - oy) // scale][(x - ox) // scale] == "1"
            raw.extend(FG if on else BG)
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n"
    png += png_chunk(b"IHDR", ihdr)
    png += png_chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += png_chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


for name, size in SIZES.items():
    d = os.path.join(RES, name)
    os.makedirs(d, exist_ok=True)
    write_png(os.path.join(d, "ic_launcher.png"), size)
    print(f"wrote {name}/ic_launcher.png {size}x{size}")
