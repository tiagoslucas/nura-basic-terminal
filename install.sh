#!/bin/sh
# Install phone-buttons: power = screen toggle, volume = font size.
# Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install.sh
set -e
SRC=/tmp/basic-terminal
. "$SRC/backup-helper.sh"

FONTPATH=/usr/share/consolefonts/ter-148n.psf.gz

backup /usr/share/consolefonts/ter-148n.psf.gz "$SRC/ter-148n.psf.gz"
install -m 644 "$SRC/ter-148n.psf.gz" /usr/share/consolefonts/
backup /usr/local/bin/phone-screen-toggle "$SRC/phone-screen-toggle"
backup /usr/local/bin/phone-font "$SRC/phone-font"
install -m 755 "$SRC/phone-screen-toggle" "$SRC/phone-font" /usr/local/bin/
backup /etc/hkdm/config.d/phone-buttons.toml "$SRC/phone-buttons.toml"
install -m 644 -o root -g root "$SRC/phone-buttons.toml" /etc/hkdm/config.d/

# Boot default font = the tripled 48px one. These two are edited in place, so
# back them up only when the edit would actually change the FONT= line.
grep -qx "FONT=$FONTPATH" /etc/vconsole.conf 2>/dev/null || backup /etc/vconsole.conf
if grep -q '^FONT=' /etc/vconsole.conf; then
    sed -i 's|^FONT=.*|FONT=/usr/share/consolefonts/ter-148n.psf.gz|' /etc/vconsole.conf
else
    echo 'FONT=/usr/share/consolefonts/ter-148n.psf.gz' >> /etc/vconsole.conf
fi

# Keep ttyescape's tty2 console consistent with the big font
mkdir -p /etc/conf.d
grep -qx "FONT=$FONTPATH" /etc/conf.d/ttyescape.conf 2>/dev/null || \
    backup /etc/conf.d/ttyescape.conf
if [ -f /etc/conf.d/ttyescape.conf ] && grep -q '^FONT=' /etc/conf.d/ttyescape.conf; then
    sed -i 's|^FONT=.*|FONT=/usr/share/consolefonts/ter-148n.psf.gz|' /etc/conf.d/ttyescape.conf
else
    echo 'FONT=/usr/share/consolefonts/ter-148n.psf.gz' >> /etc/conf.d/ttyescape.conf
fi

systemctl restart hkdm
# Apply the font right now (vconsole-setup covers every VT)
systemctl restart systemd-vconsole-setup 2>/dev/null || \
    setfont -C /dev/tty1 /usr/share/consolefonts/ter-148n.psf.gz

stty -F /dev/tty1 size
echo "INSTALL DONE"
