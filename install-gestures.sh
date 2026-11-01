#!/bin/sh
# Install touch gestures: drag = scroll the tty1 console through tmux
# scrollback, double tap = TAB. Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install-gestures.sh
set -e
SRC=/tmp/basic-terminal

apk add tmux 2>/dev/null || true

install -m 755 "$SRC/phone-gestures" /usr/local/bin/
install -m 644 "$SRC/phone-gestures.service" /etc/systemd/system/
# tty1 logins get wrapped in tmux (session "phone"); other shells untouched
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
