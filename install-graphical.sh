#!/bin/sh
# Install graphical apps: `app` runs any Wayland app fullscreen on the
# phone (sway kiosk, 3x scale, wvkbd keyboard). Power double-click
# toggles the keyboard inside a session, vol-up + power takes a
# screenshot. Depends on the buttons component (phone-screen-toggle and
# phone-font carry the session-aware patches).
# Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install-graphical.sh
set -e
SRC=/tmp/basic-terminal
. "$SRC/backup-helper.sh"

# sway replaces what cage did (it has layer-shell, so wvkbd works);
# seatd-launch gives sway a seat outside a logind session; grim captures
apk add sway wvkbd seatd-launch grim 2>/dev/null || true

backup /usr/local/bin/app "$SRC/graphical/app"
backup /usr/local/bin/app-inner "$SRC/graphical/app-inner"
backup /usr/local/bin/phone-screenshot "$SRC/graphical/phone-screenshot"
install -m 755 "$SRC/graphical/app" "$SRC/graphical/app-inner" \
    "$SRC/graphical/phone-screenshot" /usr/local/bin/
backup /etc/app-sway.conf "$SRC/graphical/app-sway.conf"
install -m 644 -o root -g root "$SRC/graphical/app-sway.conf" /etc/
backup /etc/hkdm/config.d/phone-screenshot.toml "$SRC/graphical/phone-screenshot.toml"
install -m 644 -o root -g root "$SRC/graphical/phone-screenshot.toml" \
    /etc/hkdm/config.d/

systemctl restart hkdm

echo "Try it from the console: sudo app firefox"
echo "INSTALL DONE"
