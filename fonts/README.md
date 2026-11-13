# fonts

- `ter-116n.psf.gz` — pristine Terminus 16px console font (Terminus 4.49,
  from the distro's `font-terminus` package)
- `ter-148n.psf.gz` — 24×48 derivative, generated from the above by
  `scale-psf.py`
- `scale-psf.py` / `test-scale-psf.py` — our own code (repo MIT license)

## License

Terminus 4.49 is distributed under the SIL Open Font License 1.1, and so is
the scaled derivative — the repository's top-level MIT license does not
cover the two `.psf.gz` files. Under the OFL, modified versions must not
use the reserved font name: `ter-148n` is a generated derivative, not stock
Terminus — keep presenting it that way.
