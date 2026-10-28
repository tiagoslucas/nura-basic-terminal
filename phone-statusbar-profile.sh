# `clear` homes the prompt to console row 0, which is hidden behind the
# fbcon status bar (top 2 rows). Drop the prompt 2 rows instead.
clear() {
    /bin/busybox clear
    printf "\n\n"
}
