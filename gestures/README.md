# gestures

Touchscreen gestures for the bare console: scrollback and TAB injection.
Installed by `install-gestures.sh`.

## How it works

fbcon has no scrollback, so tty1 logins are wrapped in tmux (a
`/etc/profile.d` hook execs `tmux new-session -A -s phone`; ssh and other
VTs are untouched) and a root daemon (`phone-gestures`) reads the
touchscreen's evdev device directly.

- **Vertical drags** in the terminal area — everything above the on-screen
  keyboard while it's shown, the whole screen when it's not — scroll the
  tmux session through copy mode, "natural" direction (content follows the
  finger): drag down = older, drag up = newer, quick flick down = 20-line
  jump, and reaching the live bottom leaves copy mode.
- **Double tap** in the terminal area injects a TAB through a one-key
  uinput keyboard, the same mechanism buffyboard uses to type — but only
  while the tmux session is running. An injected TAB goes to whatever
  owns tty1, and at a login prompt that is agetty, which rejects the
  entire login name on any control character (`invalid character 0x9 in
  login name`) and exits; gating TAB on `tmux has-session` keeps it off
  the login prompt, the same way the scroll gestures already no-op
  without a session.

The daemon coexists with buffyboard: libinput doesn't grab the device, so
both read the same events.

**Touchscreen gotcha:** the Goodix driver advertises an ABS range of
0–4095 in its `EVIOCGABS` info but reports coordinates that are **already
screen pixels** (0–2279), so touch positions must be used as-is, never
rescaled against the advertised maximum. Rescaling shrank every touch by
~0.56 and put taps on the on-screen keyboard (y ≥ 1520) inside the
terminal zone at y ≈ 850–1270: typing two letters quickly read as a
double tap and fired a TAB, which made console logins impossible. To
re-verify after a driver change, compare a touch's reported y against the
buffyboard key it activates — the keyboard's five rows start at y = 1520
and are 152 px tall.

## What the installer does

Installs `phone-gestures` + its systemd unit (enabled at boot) and the
`/etc/profile.d` hook that wraps tty1 logins in tmux, and drops a
`~/.tmux.conf` (status line off, 5000 lines of history) where none
exists. Takes effect at the next tty1 login.

## Testing

`synthtouch.c` builds a synthetic protocol-B touchscreen via uinput for
testing the whole chain without touching the real screen (drag:
`synthtouch x0 y0 x1 y1 [ms]`, double tap: `synthtouch dtap x y`,
run under `doas`). Coordinates are screen pixels, like the real Goodix
reports: the device advertises a 0–4095 ABS range to match the hardware,
but values are passed through unscaled.

## Customizing

Constants at the top of `phone-gestures`: `SCREEN_W/H`, `KEYBOARD_TOP`
(px), the drag→line and tap sensitivities, and `UID`/`TMUX`/`SESSION` for
the tmux socket. `UID` (uid 10000, the postmarketOS default) is the one
place in this repo that hardcodes a uid — everything else resolves the
device user at run time.
