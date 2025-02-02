#!/usr/bin/env bash

# Define the screenshot directory
DIR=${HOME}/Pictures/Screenshots
mkdir -p "${DIR}"

# Generate the filename with a timestamp
FILENAME="screenshot-$(date +%F-%T).png"

# If --screen flag is provided, take a screenshot of a specific screen
if [ "$1" == "--screen" ]; then
    # Use slurp to select the screen and output geometry
    SCREEN_GEOMETRY=$(slurp -o)

    # If geometry is selected, take a screenshot of that screen
    if [ -n "$SCREEN_GEOMETRY" ]; then
        # Debugging: Print the selected geometry
        echo "Selected Screen Geometry: $SCREEN_GEOMETRY"

        grim -g "$SCREEN_GEOMETRY" "${DIR}/${FILENAME}" || exit 1
        notify-send "Screenshot taken!" "Screenshot of selected screen saved to ${DIR}/${FILENAME}"
    else
        notify-send "Error" "No screen selected"
        exit 1
    fi
else
    # If no flag is passed, use slurp for region selection
    region="$(slurp)"

    # Debugging: Print the region directly without modification
    echo "Region Geometry: $region"

    if [ -n "$region" ]; then
        grim -g "$region" "${DIR}/${FILENAME}" || exit 1
        notify-send "Screenshot taken!" "Region screenshot saved to ${DIR}/${FILENAME}"
    else
        notify-send "Error" "No region selected"
        exit 1
    fi
fi
