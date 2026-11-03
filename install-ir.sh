#!/bin/sh
# Install the IR blaster tools (phone-ir + irsend + example remotes file).
# Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install-ir.sh
# Needs a C compiler and the kernel UAPI headers (apk add build-base linux-headers).
set -e
SRC=/tmp/basic-terminal

cc -O2 -o /usr/local/bin/irsend "$SRC/irsend.c"
chmod 755 /usr/local/bin/irsend
install -m 755 "$SRC/phone-ir" /usr/local/bin/
mkdir -p /etc/phone-ir
# codes — never overwrite an already-edited remotes file
if [ ! -f /etc/phone-ir/remotes.conf ]; then
    install -m 644 "$SRC/phone-ir-remotes.conf" /etc/phone-ir/remotes.conf
fi
echo "IR INSTALL DONE"
