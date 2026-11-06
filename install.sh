#!/bin/sh
# Meta-installer: runs every component installer in order. Install one
# piece only by running its own install-<name>.sh instead.
# Run as root on the postmarketOS device:
#   doas sh /tmp/basic-terminal/install.sh
set -e
SRC=/tmp/basic-terminal

for i in buttons statusbar gestures brightness ir telephony; do
    echo "== install-$i =="
    sh "$SRC/install-$i.sh"
done
echo "ALL COMPONENTS INSTALLED"
