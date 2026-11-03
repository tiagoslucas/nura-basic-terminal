#!/bin/sh
# Install the fbcon status bar (battery top-right, cellular top-left).
# Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install-statusbar.sh
set -e
SRC=/tmp/basic-terminal
. "$SRC/backup-helper.sh"

backup /usr/local/bin/phone-statusbar "$SRC/phone-statusbar"
install -m 755 "$SRC/phone-statusbar" /usr/local/bin/
backup /usr/local/bin/phone-font "$SRC/phone-font"
install -m 755 "$SRC/phone-font" /usr/local/bin/  # now also records font-px
backup /etc/systemd/system/phone-statusbar.service "$SRC/phone-statusbar.service"
install -m 644 "$SRC/phone-statusbar.service" /etc/systemd/system/
backup /etc/profile.d/phone-statusbar.sh "$SRC/phone-statusbar-profile.sh"
install -m 644 "$SRC/phone-statusbar-profile.sh" /etc/profile.d/phone-statusbar.sh
# tunables (battery timing) — never overwrite an already-tuned config
if [ ! -f /etc/phone-statusbar.conf ]; then
    install -m 644 "$SRC/phone-statusbar.conf" /etc/phone-statusbar.conf
fi
# regenerated font: unicode table endianness fix (accents were broken)
backup /usr/share/consolefonts/ter-148n.psf.gz "$SRC/ter-148n.psf.gz"
install -m 644 "$SRC/ter-148n.psf.gz" /usr/share/consolefonts/
setfont -C /dev/tty1 /usr/share/consolefonts/ter-148n.psf.gz

# Pad the login prompt below the status bar (2 blank lines in /etc/issue)
if [ ! -f /etc/issue.pre-statusbar ]; then
    cp /etc/issue /etc/issue.pre-statusbar
    printf "\n\n" >> /etc/issue
fi

systemctl daemon-reload
systemctl enable --now phone-statusbar
sleep 2
systemctl is-active phone-statusbar
echo "STATUSBAR INSTALL DONE"
