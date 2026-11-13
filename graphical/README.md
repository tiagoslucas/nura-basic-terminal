# graphical

Run any Wayland app fullscreen: a sway kiosk at 3× scale with the `wvkbd`
on-screen keyboard and the status bar kept on top. Installed by
`install-graphical.sh`.

## How it works

`app firefox` (or any Wayland app) runs a sway kiosk on VT3 — `openvt`
gives sway the VT, `seatd-launch` gives it a seat outside a logind
session, and the app itself runs as the device user against the
root-owned wayland socket. The launcher runs as root (it pauses console
services and switches VTs); the doas rule installed with it lets the
device user type just `app`, no password. The output is scaled 3×
(1080×2280 physical → 360×760 logical), so buttons and page content are
finger-sized. The console stack (buffyboard, status bar, gestures) is
paused while the session runs and restored when the app exits — sway
exits with it, like cage did.

The on-screen keyboard is `wvkbd`, started hidden: buffyboard renders on
fbcon, which a Wayland compositor doesn't display, so it can't come
along — but the power double-click toggles wvkbd inside the session
(wvkbd's signals are one-way, so visibility is tracked in
`/run/phone-buttons/wvkbd-shown`), and it's colored to match
buffyboard's default breezy-light theme so the two keyboards look the
same. Screenshots are `grim`, fired by the vol-up + power combo (or
`phone-screenshot` directly), saved to `~/Pictures/screenshot-<timestamp>.png`.

The status bar comes along too: sway's own bar runs across the top (32
logical px, like the fbcon one; the window title bar is off —
`default_border none`), fed by `phone-statusbar --text` as its
`status_command`. The line is padded to fill the bar width, so the
cellular half sits at the left edge and battery/clock at the right,
clear of the notch — swaybar right-aligns an unpadded line. Sway spawns
its bar as root, and root's swaybar can't work here — with the user
session bus present its tray code segfaults, without a bus it exits —
so `swaybar_command` points at `swaybar-user`, which opens the
root-owned sway sockets, drops to the device user and runs the real
swaybar from there. A ring still shows immediately: call-watcher
SIGUSR1s the `--text` instance directly.

## What the installer does

Installs `app`, `app-inner`, `swaybar-user` and `phone-screenshot` into
`/usr/local/bin`, `/etc/app-sway.conf`, and the `phone-screenshot.toml`
hkdm binding; also the doas rule (`49-app-doas.conf`, from a `@USER@`
template like the polkit one) that lets the device user run `app` as
root without a password, plus the `/etc/profile.d/app-alias.sh` alias so
a plain `app` works in login shells; `apk add`s sway / wvkbd /
seatd-launch / grim and restarts hkdm.

Needs the buttons and statusbar components (`phone-screen-toggle`
carries the session-aware patches, the bar's `status_command` is
`phone-statusbar --text`).

## Files

- `app` — the launcher (`app <wayland app>`, run via the doas rule as
  root)
- `app-inner` — run by sway at startup: wayland socket perms, wvkbd,
  the app itself
- `app-sway.conf` — kiosk sway config, 3× scale, status bar (installed
  to `/etc/`)
- `swaybar-user` — the `swaybar_command` wrapper that drops sway's bar
  to the device user
- `phone-screenshot` — grim capture; `phone-screenshot.toml` — hkdm
  binding for the vol-up + power combo
- `49-app-doas.conf.in` — doas-rule template, `@USER@` filled in by the
  installer
- `app-alias.sh` — profile.d alias `app` → `doas app`
