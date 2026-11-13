# buffyboard patches

Patches against [buffyboard](https://gitlab.com/cherrypicker/buffybox) 3.6.0
(upstream by Johannes Marbach / cherrypicker), maintained for the Nura phone:

- `terminal-c-rewrite.patch` — apply first. Upstream computes the console
  shrink from KDFONTOP GET font metrics; that ioctl fails (ENOSPC) on this
  kernel, so upstream silently never shrinks and the keyboard is drawn over
  the console. This restores the pre-3.6 TIOCSWINSZ probe approach.
- `keyboard-wipe-fix.patch` — apply second. Re-asserts the shrink every
  500 ms so font changes / VT resizes can't leave the console grown over
  the keyboard area.

Apply with `patch -p1` inside the buffybox source tree. Together they
reproduce the built source on the phone.

## License

buffyboard is GPL-3.0-or-later, and these patches modify its source — they
are derivative works and are GPL-3.0-or-later. The repository's top-level
MIT license does not cover this directory.
