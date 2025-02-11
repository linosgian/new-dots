#!/bin/bash

SOUND_FILE="@sound_file@"

case "$1" in
    up)
        # Unmute first then play sound
        pactl set-sink-mute @DEFAULT_SINK@ 0
        paplay $SOUND_FILE
        pactl set-sink-volume @DEFAULT_SINK@ +5%
        ;;
    down)
        pactl set-sink-mute @DEFAULT_SINK@ 0
        paplay $SOUND_FILE
        pactl set-sink-volume @DEFAULT_SINK@ -5%
        ;;
    mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
    *)
        echo "Usage: $0 {up|down|mute}"
        exit 2
esac

exit 0
