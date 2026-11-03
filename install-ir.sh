#!/bin/sh
# Install the IR blaster tools (phone-ir + irsend + example remotes file).
# Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install-ir.sh
# Needs a C compiler and the kernel UAPI headers (apk add build-base linux-headers).
set -e
SRC=/tmp/basic-terminal
. "$SRC/backup-helper.sh"

# Compile to a temp file rather than straight over /usr/local/bin/irsend: a
# cc that fails halfway would otherwise leave a truncated binary installed,
# and the backup needs something to compare the installed one against.
TMPBIN=$(mktemp)
trap 'rm -f "$TMPBIN"' EXIT
cc -O2 -o "$TMPBIN" "$SRC/irsend.c"
backup /usr/local/bin/irsend "$TMPBIN"
install -m 755 "$TMPBIN" /usr/local/bin/irsend
backup /usr/local/bin/phone-ir "$SRC/phone-ir"
install -m 755 "$SRC/phone-ir" /usr/local/bin/
mkdir -p /etc/phone-ir
# codes — never overwrite an already-edited remotes file
if [ ! -f /etc/phone-ir/remotes.conf ]; then
    install -m 644 "$SRC/phone-ir-remotes.conf" /etc/phone-ir/remotes.conf
fi
echo "IR INSTALL DONE"
