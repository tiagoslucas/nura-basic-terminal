#!/bin/sh
# Install the adaptive backlight (follows the ambient light sensor).
# Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install-brightness.sh
set -e
SRC=/tmp/basic-terminal

install -m 755 "$SRC/phone-brightness" /usr/local/bin/
install -m 644 "$SRC/phone-brightness.service" /etc/systemd/system/
# tunables — never overwrite an already-tuned config
if [ ! -f /etc/phone-brightness.conf ]; then
    install -m 644 "$SRC/phone-brightness.conf" /etc/phone-brightness.conf
fi

systemctl daemon-reload
systemctl enable --now phone-brightness
sleep 2
systemctl is-active phone-brightness
echo "BRIGHTNESS INSTALL DONE"
