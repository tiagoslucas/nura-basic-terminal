# fonts

- `ter-116n.psf.gz` — pristine Terminus 16px console font (Terminus 4.49,
  from the distro's `font-terminus` package)
- `ter-148n.psf.gz` — 24×48 derivative, generated from the above by
  `scale-psf.py`
- `scale-psf.py` / `test-scale-psf.py` — our own code (repo MIT license)

## Why and how

Terminus tops out at 32 px, so `ter-148n.psf.gz` is ter-116n scaled 3× to
24×48 — a console font that's readable on a 1080-wide phone screen.
Regenerate with:

```sh
python3 fonts/scale-psf.py /usr/share/consolefonts/ter-116n.psf.gz fonts/ter-148n.psf.gz 3
```

`python3 fonts/test-scale-psf.py` self-checks that pipeline: it scales a
tiny PSF1 font and loads the result with the status bar's own font
loader, asserting the unicode table and the scaled pixels.

Gotchas handled: PSF1 unicode tables are little-endian u16 with 0xFFFF
terminators / 0xFFFE sequence separators and contain UTF-16 surrogate
pairs; PSF2 wants UTF-8 values with 0xFF/0xFE markers.

## License

Terminus 4.49 is distributed under the SIL Open Font License 1.1, and so is
the scaled derivative — the repository's top-level MIT license does not
cover the two `.psf.gz` files. Under the OFL, modified versions must not
use the reserved font name: `ter-148n` is a generated derivative, not stock
Terminus — keep presenting it that way.
