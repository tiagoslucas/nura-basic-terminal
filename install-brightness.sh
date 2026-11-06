#!/bin/sh
# Install the adaptive backlight (follows the ambient light sensor).
# Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install-brightness.sh
set -e
SRC=/tmp/basic-terminal
. "$SRC/backup-helper.sh"

backup /usr/local/bin/phone-brightness "$SRC/brightness/phone-brightness"
install -m 755 "$SRC/brightness/phone-brightness" /usr/local/bin/
backup /etc/systemd/system/phone-brightness.service "$SRC/brightness/phone-brightness.service"
install -m 644 "$SRC/brightness/phone-brightness.service" /etc/systemd/system/
# tunables — never overwrite an already-tuned config
if [ ! -f /etc/phone-brightness.conf ]; then
    install -m 644 "$SRC/brightness/phone-brightness.conf" /etc/phone-brightness.conf
fi

systemctl daemon-reload
systemctl enable --now phone-brightness
sleep 2
systemctl is-active phone-brightness
echo "BRIGHTNESS INSTALL DONE"
