#!/bin/sh
# Install the notification LED: fast blink while a call rings, steady
# while a call is active, slow blink for a missed call and double-blink
# for an unread SMS (both until `notify-clear`). Watches ModemManager
# itself, so no other component is required.
# Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install-notify.sh
set -e
SRC=/tmp/basic-terminal
. "$SRC/backup-helper.sh"

USER_HOME=$(set -- /home/*; echo "${1:-/root}")
USER_NAME=$(stat -c %U "$USER_HOME")
USER_ID=$(id -u "$USER_NAME")

# The daemon runs unprivileged: make the LED's brightness file
# user-writable (the rule re-applies this after reboots)
mkdir -p /etc/udev/rules.d  # not present on a fresh postmarketOS install
backup /etc/udev/rules.d/70-notify-led.rules "$SRC/notify/70-notify-led.rules"
install -m 644 "$SRC/notify/70-notify-led.rules" /etc/udev/rules.d/
udevadm control --reload
chmod 666 /sys/class/leds/white:indicator/brightness

BIN="$USER_HOME/.local/bin"
mkdir -p "$BIN" "$USER_HOME/.config/systemd/user"
for f in notify-led notify-clear; do  # notify/
    backup "$BIN/$f" "$SRC/notify/$f"
    install -m 755 -o "$USER_NAME" -g "$USER_NAME" "$SRC/notify/$f" "$BIN/"
done

USVC="XDG_RUNTIME_DIR=/run/user/$USER_ID systemctl --user"
backup "$USER_HOME/.config/systemd/user/notify-led.service" \
    "$SRC/notify/notify-led.service"
install -m 644 -o "$USER_NAME" -g "$USER_NAME" "$SRC/notify/notify-led.service" \
    "$USER_HOME/.config/systemd/user/"

doas -u "$USER_NAME" env $USVC daemon-reload
doas -u "$USER_NAME" env $USVC enable --now notify-led.service
doas -u "$USER_NAME" env $USVC restart notify-led.service
sleep 2
doas -u "$USER_NAME" env $USVC is-active notify-led.service
echo "NOTIFY LED INSTALL DONE"
