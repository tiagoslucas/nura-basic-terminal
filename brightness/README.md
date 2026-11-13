# brightness

Adaptive backlight: the screen follows the ambient light sensor — dim in
the dark, bright in the sun. Installed by `install-brightness.sh`.

## How it works

`phone-brightness` is a daemon that reads the ambient light sensor (any
IIO device with `in_illuminance_input`; an LTR-F216A on this phone)
every `POLL_EVERY` seconds while the screen is on, and sets the backlight
on a logarithmic lux→brightness curve — perception is logarithmic, so
equal light ratios give equal brightness ratios. `MIN_BRIGHTNESS` in a
dark room, `MAX_BRIGHTNESS` at `LUX_MAX` ambient light. Readings are
smoothed with an exponential moving average and a 12% deadband so the
backlight doesn't hunt around a threshold.

While the screen is off (backlight 0) it blocks on its wake pipe — the
backlight's single writer, `phone-screen-toggle`, SIGUSR1s it when the
screen comes back, and it re-samples then. Manual
`echo N > .../brightness` changes are adopted as the baseline but
overridden at the next adjustment; stop the service to hold a level.

## What the installer does

Installs `phone-brightness` + its systemd unit (enabled at boot) and
`/etc/phone-brightness.conf` (when none exists).
`phone-screen-toggle` pokes it awake on screen-on.

## Customizing

Tunables live in `/etc/phone-brightness.conf` (template:
`phone-brightness.conf` here): `MIN_BRIGHTNESS` (dark-room level),
`MAX_BRIGHTNESS`, `LUX_MAX` (ambient light that maps to the max), and
`POLL_EVERY` (sample interval while lit — raising it saves battery at the
cost of reacting slower when you move between rooms).
