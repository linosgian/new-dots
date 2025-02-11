#!/usr/bin/env bash

case "$1" in
    lock)
        swaylock
        ;;
    logout)
        i3-msg exit
        ;;
    suspend)
        swaylock && systemctl suspend
        ;;
    hibernate)
        swaylock && systemctl hibernate
        ;;
    reboot)
        systemctl reboot
        ;;
    shutdown)
        systemctl poweroff
        ;;
    *)
        echo "Usage: $0 {lock|logout|suspend|hibernate|reboot|shutdown}"
        exit 2
esac

exit 0
