#!/bin/sh
# Install phone-buttons: power = screen toggle, volume = font size.
# Run as root on the postmarketOS device:
#   doas sh /tmp/pb-install.sh
set -e
SRC=/tmp/phone-buttons

install -m 644 "$SRC/ter-148n.psf.gz" /usr/share/consolefonts/
install -m 755 "$SRC/phone-screen-toggle" "$SRC/phone-font" /usr/local/bin/
install -m 644 -o root -g root "$SRC/phone-buttons.toml" /etc/hkdm/config.d/

# Boot default font = the tripled 48px one
if grep -q '^FONT=' /etc/vconsole.conf; then
    sed -i 's|^FONT=.*|FONT=/usr/share/consolefonts/ter-148n.psf.gz|' /etc/vconsole.conf
else
    echo 'FONT=/usr/share/consolefonts/ter-148n.psf.gz' >> /etc/vconsole.conf
fi

# Keep ttyescape's tty2 console consistent with the big font
mkdir -p /etc/conf.d
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
