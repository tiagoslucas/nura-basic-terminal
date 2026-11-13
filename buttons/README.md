# buttons

Hardware-button handling for the bare console: the power and volume keys,
plus the console font ladder. Installed by `install-buttons.sh`.

## What the buttons do

**Power button** (`phone-screen-toggle`):

- **single click** — toggle the screen. Off = backlight 0 +
  `setterm --blank force` (the logged-in session on tty1 is untouched);
  on = `setterm --blank poke` + restore the saved brightness, then
  `SIGUSR1` nudges so the status bar repaints and buffyboard redraws the
  keyboard.
- **double click** (releases < 450 ms apart) — toggle the onscreen
  keyboard. On the console that's buffyboard (stopping it lets the console
  grow back to full height, starting it shrinks the terminal rows to the
  space above the keyboard); inside a graphical session it's wvkbd.
- **9 s hold** — power the device off.
- **vol-up held + power click** — screenshot the graphical session (grim,
  saved to the device user's `~/Pictures`).

The `ttyescape` combo (vol-down held + power taps) is preserved: the
script bails out if `/tmp/ttyescape.tmp` exists, and `phone-font` ignores
volume presses within 2 s of a power press — in either direction, so
neither combo bumps the font.

**Volume buttons** (`phone-font`): step the console font through the stock
Terminus sizes (16/20/24/28/32 px) plus a generated 48 px one. The current
step lives in `/run/phone-buttons/font-index` (volatile — resets to the
biggest after a reboot, which is usually what you want on a phone).
`phone-font` stands down while a call is ringing or active, so the
telephony volume buttons own the keys then — each component binds the keys
in its own hkdm config, and hkdm runs every matching binding.

## What the installer does

Installs the font + `phone-screen-toggle` + `phone-font`, drops
`phone-buttons.toml` into `/etc/hkdm/config.d/`, sets the boot font via
`FONT=` in `/etc/vconsole.conf` (and `/etc/conf.d/ttyescape.conf` so the
escape VT matches), restarts hkdm.

## Customizing

Constants at the top of the scripts:

- `phone-screen-toggle`: `BL=` (backlight sysfs dir), `DOUBLECLICK_CS`,
  `HOLD_CS` (power-off hold)
- `phone-font`: the `FONTS`/`HEIGHTS` ladders

Note: the keyboard toggle needs a buffyboard that resizes the console
around the keyboard; upstream ≥ 3.6.0 does this via KDFONTOP, which is
broken on some kernels (ENOSPC for fonts > 32 px) — see
`../buffyboard/README.md` for the patch this device runs instead.
