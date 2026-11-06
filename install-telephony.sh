#!/bin/sh
# Install telephony: SMS sending, call control, and incoming-call
# handling (ring tone, screen wake, RING/CALL in the status bar,
# volume-up answers, volume-down silences the ringer).
# Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install-telephony.sh
set -e
SRC=/tmp/basic-terminal
. "$SRC/backup-helper.sh"

USER_HOME=$(set -- /home/*; echo "${1:-/root}")
USER_NAME=$(stat -c %U "$USER_HOME")
USER_ID=$(id -u "$USER_NAME")

# Let the phone user place/answer calls through ModemManager (messaging
# is allowed by distro defaults; voice is not). polkit picks up rules
# files on its own. NOTE: the rule names a specific user — edit it if
# your device user differs.
backup /etc/polkit-1/rules.d/49-modem-voice.rules "$SRC/telephony/49-modem-voice.rules"
install -m 644 "$SRC/telephony/49-modem-voice.rules" /etc/polkit-1/rules.d/

# Volume buttons: answer / silence-the-ringer while a call rings, call
# volume while active. Own hkdm config so the buttons install keeps its
# own bindings (hkdm runs every matching binding; phone-font stands down
# while a call is up). hkdm is restarted further down.
backup /etc/hkdm/config.d/phone-telephony.toml "$SRC/telephony/phone-telephony.toml"
install -m 644 "$SRC/telephony/phone-telephony.toml" /etc/hkdm/config.d/
backup /usr/local/bin/phone-volume "$SRC/telephony/phone-volume"
install -m 755 "$SRC/telephony/phone-volume" /usr/local/bin/

# Status bar with the RING/CALL indicator
backup /usr/local/bin/phone-statusbar "$SRC/statusbar/phone-statusbar"
install -m 755 "$SRC/statusbar/phone-statusbar" /usr/local/bin/

# Per-user tools + ring tone
BIN="$USER_HOME/.local/bin"
mkdir -p "$BIN" "$USER_HOME/.local/share" "$USER_HOME/.config/systemd/user"
for f in call sms-send call-watcher; do  # telephony/
    backup "$BIN/$f" "$SRC/telephony/$f"
    install -m 755 -o "$USER_NAME" -g "$USER_NAME" "$SRC/telephony/$f" "$BIN/"
done
# an earlier deploy installed the watcher as call-watcher.py
if [ -e "$BIN/call-watcher.py" ] && cmp -s "$BIN/call-watcher.py" "$SRC/telephony/call-watcher"; then
    rm -f "$BIN/call-watcher.py"
elif [ -e "$BIN/call-watcher.py" ]; then
    backup "$BIN/call-watcher.py"
    rm -f "$BIN/call-watcher.py"
fi
install -m 644 -o "$USER_NAME" -g "$USER_NAME" "$SRC/telephony/ring.wav" \
    "$USER_HOME/.local/share/ring.wav"

# User-level service: run enable/restart as the phone user
USVC="XDG_RUNTIME_DIR=/run/user/$USER_ID systemctl --user"
backup "$USER_HOME/.config/systemd/user/call-watcher.service" \
    "$SRC/telephony/call-watcher.service"
install -m 644 -o "$USER_NAME" -g "$USER_NAME" "$SRC/telephony/call-watcher.service" \
    "$USER_HOME/.config/systemd/user/"

systemctl restart hkdm
systemctl restart phone-statusbar
doas -u "$USER_NAME" env $USVC daemon-reload
doas -u "$USER_NAME" env $USVC enable --now call-watcher.service
doas -u "$USER_NAME" env $USVC restart call-watcher.service
sleep 2
doas -u "$USER_NAME" env $USVC is-active call-watcher.service
echo "TELEPHONY INSTALL DONE"
