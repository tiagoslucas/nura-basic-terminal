#!/usr/bin/python3
"""Scale a PSF1 console font by an integer factor, output PSF2.

PSF1: magic 0x36 0x04, mode byte (bit0=512 glyphs, bit1=unicode table,
bit2=sequences), charsize byte (=height for 8-wide fonts). Glyph rows are
1 byte each, MSB = leftmost pixel. Unicode table (kbd/Terminus convention):
LE u16 per entry, 0xFFFF terminates each glyph's entries, 0xFFFE separates
sequence members.

PSF2: 32-byte header, variable width glyphs, unicode values UTF-8 encoded,
0xFF terminates a glyph's entries, 0xFE separates sequence members.
"""
import gzip
import struct
import sys


def parse_psf1(data):
    assert data[0] == 0x36 and data[1] == 0x04, "not a PSF1 file"
    mode, charsize = data[2], data[3]
    nglyphs = 512 if mode & 0x01 else 256
    glyphs = []
    off = 4
    for _ in range(nglyphs):
        glyphs.append(data[off:off + charsize])
        off += charsize
    table = []
    if mode & 0x02:  # unicode table present
        for _ in range(nglyphs):
            entries = []
            while True:
                (v,) = struct.unpack("<H", data[off:off + 2])
                off += 2
                if v == 0xFFFF:
                    break
                entries.append(v)
            table.append(entries)
    return glyphs, table


def scale_glyph(rows, factor):
    """8-wide rows of 1 byte -> (8*factor)-wide rows of `factor` bytes."""
    out = []
    for row in rows:
        bits = [(row >> (7 - x)) & 1 for x in range(8)]
        big = []
        for b in bits:
            big.extend([b] * factor)
        scaled_row = []
        for i in range(0, len(big), 8):
            byte = 0
            for b in big[i:i + 8]:
                byte = (byte << 1) | b
            scaled_row.append(byte)
        # each source row becomes `factor` output rows
        out.extend(bytes(scaled_row) for _ in range(factor))
    return out


def entries_to_psf2(entries):
    """Unicode values -> PSF2 bytes, joining UTF-16 surrogate pairs."""
    out = bytearray()
    pending_high = None
    for v in entries:
        if v == 0xFFFE:
            out += b"\xfe"  # sequence separator
            pending_high = None
        elif 0xD800 <= v <= 0xDBFF:
            pending_high = v
        elif 0xDC00 <= v <= 0xDFFF:
            if pending_high is not None:  # unpaired lows are dropped
                cp = 0x10000 + ((pending_high - 0xD800) << 10) + (v - 0xDC00)
                out += chr(cp).encode("utf-8")
            pending_high = None
        else:
            out += chr(v).encode("utf-8")
            pending_high = None
    return bytes(out)


def write_psf2(scaled_glyphs, table, width, height):
    nglyphs = len(scaled_glyphs)
    rowsize = (width + 7) // 8
    charsize = rowsize * height
    out = bytearray()
    out += bytes([0x72, 0xB5, 0x4A, 0x86])
    out += struct.pack("<IIIIII", 0, 32, 1, nglyphs, charsize, height, width)[:0] \
        if False else struct.pack("<IIIIIII", 0, 32, 1, nglyphs, charsize, height, width)
    for g in scaled_glyphs:
        assert sum(len(r) for r in g) == charsize
        out += b"".join(g)
    for entries in table:
        out += entries_to_psf2(entries)
        out += b"\xff"
    return bytes(out)


def main():
    src, dst, factor = sys.argv[1], sys.argv[2], int(sys.argv[3])
    data = gzip.open(src).read() if src.endswith(".gz") else open(src, "rb").read()
    glyphs, table = parse_psf1(data)
    height = len(glyphs[0])  # charsize = rows for 8-wide PSF1
    scaled = [scale_glyph(g, factor) for g in glyphs]
    psf2 = write_psf2(scaled, table, 8 * factor, height * factor)
    if dst.endswith(".gz"):
        gzip.open(dst, "wb").write(psf2)
    else:
        open(dst, "wb").write(psf2)
    print(f"{src}: 8x{height}, {len(glyphs)} glyphs -> {dst}: "
          f"{8*factor}x{height*factor}, {len(psf2)} bytes")


if __name__ == "__main__":
    main()
