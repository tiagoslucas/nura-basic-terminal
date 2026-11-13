# ir

Send IR commands with the phone's IR LED: NEC / Samsung / Sony / RC5 /
raw timings, or named codes from a config file. Installed by
`install-ir.sh`.

## How it works

On this phone (Xiaomi daisy) the IR LED hangs off SPI6's MOSI line
(GPIO 20) — Xiaomi's Android kernel drives it through a `peel_ir` SPI
driver that mainline lacks, and the postmarketOS device tree has no node
for it. `phone-ir` frees the pins by unbinding the `spi_qup` controller
(`7af6000.spi`), runs `irsend` — a small real-time C program that
bit-bangs the carrier (default 38 kHz, 33 % duty; measures within 0.1 %
of the request, `irsend -v` prints it) from a list of mark/space
microseconds — and always rebinds the controller afterwards. The LED
supply (regulator l8) is already on because the SD slot shares it.

The phone can **send only**: no receive path was found (the MISO line
never moves), so codes have to come from elsewhere, e.g. the Flipper-IRDB.

```sh
doas phone-ir test                    # 5 s of bursts: aim a phone camera at the top edge
doas phone-ir nec 0x04 0x08 [N]       # NEC address/command, N repeat codes
doas phone-ir raw 9000 4500 560 ...   # raw mark/space timings, µs
doas phone-ir -f 36000 raw ...        # other carrier frequency
doas phone-ir send NAME [N]           # a named code from /etc/phone-ir/remotes.conf
phone-ir list
```

Built-in encoders: NEC, NEC with 16-bit address, Samsung32, Sony SIRC
(12-bit, 40 kHz), Philips RC5 (36 kHz, toggle bit flips on every press).
Anything else goes in as `raw`.

## What the installer does

Compiles `irsend` into `/usr/local/bin` (into a temp file first, so a
failed `cc` can't leave a truncated binary), installs `phone-ir`, and
drops an example `/etc/phone-ir/remotes.conf` (only when none exists, so
your own codes are never overwritten).

## Customizing

IR codes live in `/etc/phone-ir/remotes.conf` (template:
`phone-ir-remotes.conf` here): `NAME = nec 0x04 0x08`, `samsung`, `sirc`,
`rc5`, `necext`, `raw CARRIER DUTY MARK SPACE ...` or `ref OTHER_NAME`.
A name on several lines sends all of them in turn, 150 ms apart
(`GAP_S` in `phone-ir`). The format is documented in the template.
