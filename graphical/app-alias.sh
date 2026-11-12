# `app` must run as root for the VT/seat setup; the doas rule installed
# with this component (49-app-doas.conf) lets it skip the password prompt
alias app='doas app'
