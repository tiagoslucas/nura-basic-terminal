#!/bin/sh
# Install touch gestures: drag = scroll the tty1 console through tmux
# scrollback, double tap = TAB. Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install-gestures.sh
set -e
SRC=/tmp/basic-terminal

# backup <installed> <incoming>: keep a timestamped copy of a file this
# installer is about to overwrite, in the device home's backup folder, so a
# bad deploy can be rolled back by hand. These scripts get reinstalled often,
# so a copy is only worth keeping when the file actually changes -- an
# identical reinstall backs up nothing -- and only the BACKUP_KEEP newest
# copies of each file are kept, so the folder can't grow without bound.
BACKUP_DIR=${BACKUP_DIR:-$(set -- /home/*; echo "${1:-/root}")/backup}
BACKUP_KEEP=${BACKUP_KEEP:-2}

backup() {
    [ -e "$1" ] || return 0
    # unchanged: nothing worth keeping. An `if` rather than `cmp ... && return`
    # because under `set -e` a differing cmp would abort the whole installer.
    if cmp -s "$1" "$2"; then return 0; fi
    base=$(basename "$1")
    mkdir -p "$BACKUP_DIR"
    cp -a "$1" "$BACKUP_DIR/$base.$(date +%Y%m%d-%H%M%S)"
    chown "$(stat -c %U "$(dirname "$BACKUP_DIR")")" "$BACKUP_DIR" 2>/dev/null || true
    # drop the oldest copies beyond BACKUP_KEEP. Sort by the timestamp in the
    # name, not mtime: cp -a preserves the original's mtime, so a reinstall of
    # an older build would otherwise look like the newest backup.
    n=$(ls -1 "$BACKUP_DIR/$base".* 2>/dev/null | wc -l)
    [ "$n" -gt "$BACKUP_KEEP" ] || return 0
    ls -1 "$BACKUP_DIR/$base".* 2>/dev/null | sort | head -n "$((n - BACKUP_KEEP))" \
        | while read -r old; do rm -f "$old"; done
}

apk add tmux 2>/dev/null || true

backup /usr/local/bin/phone-gestures "$SRC/phone-gestures"
install -m 755 "$SRC/phone-gestures" /usr/local/bin/
backup /etc/systemd/system/phone-gestures.service "$SRC/phone-gestures.service"
install -m 644 "$SRC/phone-gestures.service" /etc/systemd/system/
# tty1 logins get wrapped in tmux (session "phone"); other shells untouched
backup /etc/profile.d/phone-gestures.sh "$SRC/phone-gestures-profile.sh"
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
