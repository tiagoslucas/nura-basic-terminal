# telephony

Voice calls and SMS through ModemManager's D-Bus API — no ofono, no GUI
dialer. Installed by `install-telephony.sh`.

## CLIs

```sh
call +15551234567       # dial
call                    # list: 0: incoming ringing-in /org/.../Call/8
call answer             # answer the ringing call
call hangup             # end all ongoing calls
sms-send +15551234567 "on my way"
echo "running late" | sms-send +15551234567
```

`call <number>` creates and starts an MM call object; `call answer [n]`
accepts, `call hangup [n]` ends. `sms-send <number> <text>` creates an
SMS, sends it and deletes the object; the modem here has no default SMSC
stored, so the message center comes from `/etc/phone-sms.conf` (see
Customizing).

## Incoming calls (`call-watcher`, `phone-volume`)

A user service watches MM's call signals: on a ring it plays
`~/.local/share/ring.wav` in a loop, lights the screen via
`phone-screen-toggle --do-toggle` (only when the screen-off flag exists,
so it never darkens an already-lit screen), and writes
`ringing <number>` to `/tmp/phone-call-state`; `phone-statusbar` reads
that file and shows a green `RING` (or `CALL`) on the left, poked awake
with SIGUSR1 on every transition so it appears the moment the phone
rings. Terminated call objects are deleted so the list stays clean.
While the call rings, `call-watcher` also arms the call audio routing
(see below), or the call would connect silent.

The volume buttons go through `phone-volume` while a call rings:
**volume-up answers, volume-down silences the ringer** (a flag file the
ring loop checks — the call itself keeps ringing, and volume-up still
answers it); during a call they step the earpiece volume (`RX1
Digital`, ±8 dB per press). Outside a call the buttons belong to the
buttons install again — telephony ships its **own** hkdm config
(`phone-telephony.toml`) for the volume keys, and `phone-font` stands
down while a call is up, so either component works without the other.

## Received SMS (`sms-handler`, a user service)

Every SMS the modem receives is written as JSON to a volatile copy under
`/tmp/sms/` (named uniquely by content, so the network redelivering the
same message after an outage collapses to one file) and handed to the
`COMMAND` configured in `/etc/phone-sms-handler.conf` — a shell line run
with `SMS_NUMBER`, `SMS_TEXT`, `SMS_TIMESTAMP` and `SMS_FILE` in its
environment, re-read before every scan so edits apply without a restart.
Forwarding to another phone is the documented example in that file
(`sms-send` with `$SMS_NUMBER`/`$SMS_TEXT`). Exit 0 means handled and the
SMS is deleted from modem storage; anything else leaves it in the modem
inbox, which doubles as the retry queue — a failing command delays a
message instead of losing it, and nothing is stored on the phone across
reboots.

## Call audio routing

The voice call itself never passes through Linux (q6voiced just opens
the hostless VoiceMMode1 PCM, and the DSP routes the audio), so a call
is only audible along paths connected when the session starts.
`call-watcher` therefore sets, while the call still rings: the mic
uplink route + gains (`ADC1`/`TX1` — stock levels are far too quiet),
and the earpiece downlink — the voice mixer plus the codec-internal
route from the UCM `EarpieceEnableSeq`, which nothing applies during a
call (PulseAudio's UCM verb would own the mixers, but it tears them down
when its sinks suspend). The earpiece codec route is released again when
the call ends. Known limitation: the **loudspeaker** (QUIN MI2S backend)
stays silent during calls even with its voice mixer enabled — the fix
for that lives in the DSP route setup, not userspace.

## What the installer does

Installs the polkit rule (voice access for the device user), adds its
own hkdm binding for the volume buttons, updates `phone-statusbar`
(RING/CALL indicator), puts `call`, `sms-send`, the `call-watcher` user
service + ring tone, and the `sms-handler` user service in the device
user's `~/.local`, and drops `/etc/phone-sms.conf` (SMSC) and
`/etc/phone-sms-handler.conf` (received-SMS command) only when none
exists. Enables and (re)starts everything it touched.

Voice control over MM needs a polkit rule (`49-modem-voice.rules.in`,
with the device user substituted by the installer) — messaging is
allowed by distro defaults, voice is not.

## Customizing

- `sms-send`: `SMSC` in `/etc/phone-sms.conf` (template:
  `phone-sms.conf` here, installed only when none exists) — the message
  center, operator/SIM-specific; find yours from the SIM's EF_SMSP record
  or the operator's docs (this modem sends nothing without it).
- `sms-handler`: `COMMAND` in `/etc/phone-sms-handler.conf` (template:
  `phone-sms-handler.conf` here) — what to do with each received SMS,
  with the forwarding example inside.
- `call-watcher`: `RING_WAV`, the ring `--volume=` (0–65536 linear), and
  the state/mute flag paths (shared with `phone-volume` and
  `phone-statusbar`).
