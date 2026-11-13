# statusbar

A status bar painted over the top of the framebuffer: cellular tech +
signal (left), battery + clock (right) — visible without logging in.
Installed by `install-statusbar.sh`.

## How it works

`phone-statusbar` is a Python daemon that paints only the top 96 px band
of `/dev/fb0` — the notch zone, useless for text anyway — once per minute,
just after the wall-clock minute flips, and immediately when the screen
turns on: `phone-screen-toggle` sends it `SIGUSR1`, which interrupts its
sleep. While the screen is dark the daemon blocks on its wake pipe (the
backlight's single writer is `phone-screen-toggle`, which pokes it on
wake), so it costs nothing. The terminal below is never redrawn; text
that scrolls under the bar is healed by the next repaint. The bar is a
**fixed** height with its own fixed 24×48 font, so it never moves when
you change the console font.

Values (battery from `/sys/class/power_supply/*/capacity|status`,
cellular from `mmcli -m any`, clock from `strftime`) are fetched only
once per repaint — so the clock lags at most one repaint behind.
Unread notifications (the same flags `notify-led` blinks for) appear
right of the signal strength — `SMS`, `MISS`, in green — but are hidden
while a call rings or is active, where RING/CALL already fills the bar.
The battery's Charging status is confirmed against `current_now` (some
fuel gauges' status word misreports), and a full battery is a plain
`100%`.

A failed modem query (ModemManager not up yet at boot) is not cached: it
retries at the next repaint, so the bar recovers within a minute instead
of showing NO NET for the whole `MODEM_EVERY` window.

`--text` mode is for graphical sessions: instead of painting the
framebuffer it prints the identical status line for sway's bar, with the
same battery discipline — one wake per minute and none while the screen
is dark; call-watcher pokes it with SIGUSR1 on every call transition,
since the systemd service it would signal is stopped while a session
runs. See `../graphical/README.md`.

## What the installer does

Installs `phone-statusbar` + its systemd unit (enabled at boot), the
`/etc/profile.d` `clear` shim, and pads `/etc/issue` with two blank lines
so the login prompt starts below the bar. Installs
`/etc/phone-statusbar.conf` (battery tunables) only when none exists.

## Customizing

Constants at the top of the script: `FB`, `SYSFB`, `BACKLIGHT`, `BATTERY`,
`BAR_FONT`, `BAR_H` (px), `EDGE_MARGIN`, `TEXT_MARGIN`, and the
`TECH_LABEL` map for access-technology names. Colors are RGB tuples near
the top. If your device has no notch, shrink `BAR_H` to
`2 × font_height` of whatever the smallest console font you use is.

Battery tunables live in `/etc/phone-statusbar.conf` (template:
`phone-statusbar.conf` here) — no code edits needed, and a restart
applies them (`doas systemctl restart phone-statusbar`):

- `MODEM_EVERY` (default 300 s) — how long the mmcli result is cached.
  Every fetch is a D-Bus round-trip that wakes ModemManager, so raising
  this is the single biggest saver: 300 s = 288 queries/day, 900 s = 96.

**Framebuffer gotcha:** read `stride` from
`/sys/class/graphics/fb0/stride` and trust it over `width * 4` — this
device reports 1080×2280 @ 32bpp but a stride of **4352**, not 4320
(32-byte row padding). If your bar comes out diagonal or smeared, this
is why. The pixel format assumed is BGRx little-endian, which matches
the common `FB_VISUAL_TRUECOLOR` + 32bpp case.
