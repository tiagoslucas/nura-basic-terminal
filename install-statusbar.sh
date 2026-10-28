#!/bin/sh
# Install the fbcon status bar (battery top-right, cellular top-left).
# Run as root on the postmarketOS device:
#   doas sh /tmp/phone-buttons/install-statusbar.sh
set -e
SRC=/tmp/phone-buttons

install -m 755 "$SRC/phone-statusbar" /usr/local/bin/
install -m 755 "$SRC/phone-font" /usr/local/bin/  # now also records font-px
install -m 644 "$SRC/phone-statusbar.service" /etc/systemd/system/
install -m 644 "$SRC/phone-statusbar-profile.sh" /etc/profile.d/phone-statusbar.sh
# regenerated font: unicode table endianness fix (accents were broken)
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
