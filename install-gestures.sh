#!/bin/sh
# Install touch gestures: drag = scroll the tty1 console through tmux
# scrollback, double tap = TAB. Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install-gestures.sh
set -e
SRC=/tmp/basic-terminal

# Every file this installer overwrites is first copied, timestamped, into
# the device home's backup folder, so a bad deploy can be rolled back by
# hand. Override with BACKUP_DIR=... when the home isn't the usual one.
BACKUP_DIR=${BACKUP_DIR:-$(set -- /home/*; echo "${1:-/root}")/backup}

backup() {
    [ -e "$1" ] || return 0
    mkdir -p "$BACKUP_DIR"
    cp -a "$1" "$BACKUP_DIR/$(basename "$1").$(date +%Y%m%d-%H%M%S)"
    chown "$(stat -c %U "$(dirname "$BACKUP_DIR")")" "$BACKUP_DIR" 2>/dev/null || true
}

apk add tmux 2>/dev/null || true

backup /usr/local/bin/phone-gestures
install -m 755 "$SRC/phone-gestures" /usr/local/bin/
backup /etc/systemd/system/phone-gestures.service
install -m 644 "$SRC/phone-gestures.service" /etc/systemd/system/
# tty1 logins get wrapped in tmux (session "phone"); other shells untouched
backup /etc/profile.d/phone-gestures.sh
install -m 644 "$SRC/phone-gestures-profile.sh" /etc/profile.d/phone-gestures.sh

# tmux config for the console session (no status line, deep history);
# only installed when the user has none — never clobber an existing one
for home in /root /home/*; do
    [ -d "$home" ] || continue
    if [ ! -f "$home/.tmux.conf" ]; then
        install -m 644 "$SRC/phone-tmux.conf" "$home/.tmux.conf"
        chown "$(stat -c %U "$home")" "$home/.tmux.conf" 2>/dev/null || true
    fi
done

systemctl daemon-reload
systemctl enable --now phone-gestures
sleep 2
systemctl is-active phone-gestures
echo "GESTURES INSTALL DONE (takes effect at the next tty1 login)"
