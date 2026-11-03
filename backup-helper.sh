# Shared backup helper for the installers in this directory. Sourced, not run:
#   . "$SRC/backup-helper.sh"
#
#   backup <installed> [incoming]
#
# Keeps a timestamped copy of <installed> in the device home's backup folder
# before it gets overwritten, so a bad deploy can be rolled back by hand.
#
# Given <incoming>, the copy is skipped when the two are identical: these
# scripts are reinstalled often and an unchanged reinstall isn't worth a file.
# Called with one argument the backup is unconditional, for files edited in
# place (/etc/vconsole.conf and friends) where the caller decides whether the
# edit changes anything.
#
# Only the BACKUP_KEEP newest copies of each file are kept, so the folder
# can't grow without bound. Override BACKUP_DIR / BACKUP_KEEP from the
# environment.
BACKUP_DIR=${BACKUP_DIR:-$(set -- /home/*; echo "${1:-/root}")/backup}
BACKUP_KEEP=${BACKUP_KEEP:-2}

backup() {
    [ -e "$1" ] || return 0
    # `if cmp` rather than `cmp ... && return 0`: the latter makes the AND-OR
    # list fail whenever the files differ, and under `set -e` that aborts the
    # installer in exactly the case that needs a backup.
    if [ -n "$2" ] && cmp -s "$1" "$2"; then return 0; fi
    _bk_base=$(basename "$1")
    mkdir -p "$BACKUP_DIR"
    # Timestamps are second-resolution, so two backups of one file in the same
    # second would land on the same name and the second would silently replace
    # the first. Suffix until the name is free; the suffixed name still sorts
    # after the bare one, which is what the pruning below relies on.
    _bk_dst="$BACKUP_DIR/$_bk_base.$(date +%Y%m%d-%H%M%S)"
    _bk_i=1
    while [ -e "$_bk_dst" ]; do
        _bk_dst="$BACKUP_DIR/$_bk_base.$(date +%Y%m%d-%H%M%S)-$_bk_i"
        _bk_i=$((_bk_i + 1))
    done
    cp -a "$1" "$_bk_dst"
    chown "$(stat -c %U "$(dirname "$BACKUP_DIR")")" "$BACKUP_DIR" 2>/dev/null || true
    # Drop the oldest copies beyond BACKUP_KEEP, sorting by the timestamp in
    # the name rather than mtime: cp -a preserves the original's mtime, so
    # reinstalling an older build would otherwise look like the newest backup.
    _bk_n=$(ls -1 "$BACKUP_DIR/$_bk_base".* 2>/dev/null | wc -l)
    [ "$_bk_n" -gt "$BACKUP_KEEP" ] || return 0
    ls -1 "$BACKUP_DIR/$_bk_base".* 2>/dev/null | sort \
        | head -n "$((_bk_n - BACKUP_KEEP))" \
        | while read -r _bk_old; do rm -f "$_bk_old"; done
}
