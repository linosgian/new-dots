#!/bin/bash

# Get the active output (current display) dimensions
output=$(swaymsg -t get_outputs | jq '.[] | select(.focused == true)')

# Extract width and height
width=$(echo "$output" | jq '.rect.width')
height=$(echo "$output" | jq '.rect.height')

# Calculate scratchpad size (e.g., 50% of screen size)
scratchpad_width=$((width / 2))
scratchpad_height=$((height / 2))

# Bring scratchpad window, resize, and center it
swaymsg '[app_id="scratchpad"] scratchpad show'
swaymsg "[app_id=\"scratchpad\"] resize set $scratchpad_width $scratchpad_height"
swaymsg "[app_id=\"scratchpad\"] move position center"
