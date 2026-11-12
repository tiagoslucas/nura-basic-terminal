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

USER_HOME=$(set -- /home/*; echo "${1:-/root}")
USER_NAME=$(stat -c %U "$USER_HOME")

# sway replaces what cage did (it has layer-shell, so wvkbd works);
# seatd-launch gives sway a seat outside a logind session; grim captures
apk add sway wvkbd seatd-launch grim 2>/dev/null || true

backup /usr/local/bin/app "$SRC/graphical/app"
backup /usr/local/bin/app-inner "$SRC/graphical/app-inner"
backup /usr/local/bin/phone-screenshot "$SRC/graphical/phone-screenshot"
backup /usr/local/bin/swaybar-user "$SRC/graphical/swaybar-user"
install -m 755 "$SRC/graphical/app" "$SRC/graphical/app-inner" \
    "$SRC/graphical/phone-screenshot" "$SRC/graphical/swaybar-user" \
    /usr/local/bin/
backup /etc/app-sway.conf "$SRC/graphical/app-sway.conf"
install -m 644 -o root -g root "$SRC/graphical/app-sway.conf" /etc/
backup /etc/hkdm/config.d/phone-screenshot.toml "$SRC/graphical/phone-screenshot.toml"
install -m 644 -o root -g root "$SRC/graphical/phone-screenshot.toml" \
    /etc/hkdm/config.d/

# app must run as root for the VT/seat setup; let the phone user launch
# it without a password. Template like the polkit rule in
# install-telephony.sh (generated to a temp file first so the backup
# helper compares against the real thing).
sed "s/@USER@/$USER_NAME/" "$SRC/graphical/49-app-doas.conf.in" \
    > /tmp/49-app-doas.conf
backup /etc/doas.d/49-app-doas.conf /tmp/49-app-doas.conf
install -m 600 -o root -g root /tmp/49-app-doas.conf /etc/doas.d/
# and a plain `app` (no doas typing) for login shells
backup /etc/profile.d/app-alias.sh "$SRC/graphical/app-alias.sh"
install -m 644 -o root -g root "$SRC/graphical/app-alias.sh" /etc/profile.d/

systemctl restart hkdm

echo "Try it from the console: app firefox"
echo "INSTALL DONE"
