#!/usr/bin/python3
"""Round-trip self-check for scale-psf.py.

Builds a tiny PSF1 font (8x8, unicode table), scales it 3x through
scale-psf.py's main(), then loads the PSF2 result with the same Font
class phone-statusbar uses on the device. The unicode-table translation
(endianness, surrogate pairs) is where the accents bug lived, so it is
what this pins down.

Run from the repo: python3 test-scale-psf.py
"""
import importlib.machinery
import importlib.util
import os
import struct
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))


def module(filename, name):
    path = os.path.join(HERE, filename)
    spec = importlib.util.spec_from_file_location(
        name, path, loader=importlib.machinery.SourceFileLoader(name, path))
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


scale = module("scale-psf.py", "scale_psf")
Font = module("phone-statusbar", "phone_statusbar").Font

# glyph index -> 8 rows; TABLE: glyph index -> unicode entries (UTF-16 units)
A_ROWS = [0b00100100, 0b01000010, 0b11100111, 0b10000001,
          0b10000001, 0b10100101, 0b10011001, 0b00000000]
GLYPHS = {65: A_ROWS, 200: [0b01111110] * 8, 201: [0b11000110] * 8}
TABLE = {65: [0x41],                       # 'A'
         200: [0xE9],                      # 'é' — BMP, endianness path
         201: [0xD834, 0xDD20]}            # U+1D120 — surrogate pair


def make_psf1():
    out = bytearray(b"\x36\x04") + bytes([0x02, 8])   # mode 2: unicode table
    for i in range(256):
        out += bytes(GLYPHS.get(i, [0] * 8))
    for i in range(256):
        for cp in TABLE.get(i, []):
            out += struct.pack("<H", cp)
        out += struct.pack("<H", 0xFFFF)   # glyph terminator
    return bytes(out)


def main():
    with tempfile.TemporaryDirectory() as tmp:
        src, dst = os.path.join(tmp, "in.psf"), os.path.join(tmp, "out.psf")
        open(src, "wb").write(make_psf1())
        sys.argv = ["scale-psf.py", src, dst, "3"]
        scale.main()

        font = Font.load(dst)
        assert (font.width, font.height) == (24, 24)
        assert font.cmap[0x41] == 65, "ASCII mapping lost"
        assert font.cmap[0xE9] == 200, "BMP accent mapping lost"
        assert font.cmap[0x1D120] == 201, "surrogate pair not joined"
        # every scaled pixel must equal its source pixel: 3x nearest neighbour
        g = font.glyphs[65]
        for y in range(24):
            for x in range(24):
                want = (A_ROWS[y // 3] >> (7 - x // 3)) & 1
                got = (g[y * font.rowbytes + x // 8] >> (7 - x % 8)) & 1
                assert got == want, ("pixel", x, y)
    print("scale-psf round-trip OK")


main()
