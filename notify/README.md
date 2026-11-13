# notify

The notification LED: blink patterns for calls and unread messages,
steady while charging. Installed by `install-notify.sh`.

## How it works

`notify-led` is a user service that watches ModemManager itself (no
dependency on the telephony component) and blinks the white indicator
LED:

- fast blink while a call rings, steady while a call is active
- slow blink after a **missed call** (an incoming call that ended
  unanswered — detected even when `call-watcher` deletes the call object
  first, via the CallDeleted signal)
- double blink for a **received SMS**

…until `notify-clear` dismisses them — alone it clears both,
`notify-clear sms` / `notify-clear missed` just one, so an unread SMS can
be marked seen without dropping the missed-call indication. The flags are
files in `~/.local/state/notify-led/`, so they survive restarts and
reboots.

daisy's LED is a single white diode (one channel of its aw2013 driver),
so the patterns are brightness-only; the daemon writes
`/sys/class/leds/white:indicator/brightness` directly, made user-writable
by a udev rule. If both a missed call and an SMS are pending, the missed
call wins. A charging battery also shows a steady light, at the lowest
priority — checked against `current_now`, because the pmi8994 fuel
gauge's status word claims Charging while the battery is discharging;
the current's sign is the truth.

## What the installer does

Installs `notify-led` + `notify-clear` + the user unit, and the udev rule
making the LED user-writable.

## Customizing

Constants at the top of `notify-led`: `LED` (sysfs brightness path) and
`PATTERNS` (the blink timings) — and the udev rule's
`KERNEL=="white:indicator"` match if your LED is named differently.
