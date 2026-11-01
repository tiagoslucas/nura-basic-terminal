# Wrap the tty1 login shell in tmux so the touchscreen gesture daemon
# (phone-gestures) can scroll the console through tmux copy mode —
# fbcon itself has no scrollback. Other logins (ssh, other VTs) are
# unaffected: the guard only fires on tty1 and outside tmux.
if [ "$(tty 2>/dev/null)" = "/dev/tty1" ] && [ -z "$TMUX" ] && \
   command -v tmux >/dev/null 2>&1; then
    exec tmux new-session -A -s phone
fi
