#! /bin/sh
# Parse command line arguments for sink descriptions to ignore or alias
IGNORE_DESCRIPTIONS=()
ALIAS_DESCRIPTIONS=()
ALIAS_LABELS=()
EXACT_MATCH=0
ONLY_KEPT=0
DEBUG=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --ignore)
            IGNORE_DESCRIPTIONS+=("$2")
            shift 2
            ;;
        --ignore=*)
            IGNORE_DESCRIPTIONS+=("${1#*=}")
            shift
            ;;
        --alias)
            ALIAS_DESCRIPTIONS+=("${2%%=*}")
            ALIAS_LABELS+=("${2#*=}")
            shift 2
            ;;
        --alias=*)
            ALIAS_DESCRIPTIONS+=("${1#--alias=}")
            ALIAS_LABELS+=("${1#*=}")
            shift
            ;;
        --only)
            ONLY_KEPT=1
            shift
            ;;
        --exact)
            EXACT_MATCH=1
            shift
            ;;
        --debug)
            DEBUG=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--ignore 'desc'] [--exact] [--alias 'real desc'='label'] [--only] [--debug]"
            echo "  --ignore: Ignore sinks with this description"
            echo "  --exact:  Use exact matching instead of substring matching"
            echo "  --alias:  Display a matching sink under a friendly 'label' instead of its real description"
            echo "  --only:   Hide every sink that is not matched by an --alias"
            echo "  --debug:  Show debug information"
            echo "Example: $0 --only --alias 'HyperX 7.1 Audio Analog Stereo'='headphones'"
            echo "Example: $0 --exact --ignore 'Built-in Audio Analog Stereo'"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Does a sink description match a given pattern (respecting --exact)?
matches() {
    local description="$1"
    local pattern="$2"
    if [ $EXACT_MATCH -eq 1 ]; then
        [ "$description" = "$pattern" ]
    else
        echo "$description" | grep -qi "$pattern"
    fi
}

# Return the alias label for a description, or empty if none matches
alias_for() {
    local description="$1"
    local i
    for i in "${!ALIAS_DESCRIPTIONS[@]}"; do
        if matches "$description" "${ALIAS_DESCRIPTIONS[$i]}"; then
            echo "${ALIAS_LABELS[$i]}"
            return 0
        fi
    done
    return 1
}

ROFI_OPTIONAL_ARGS=()
if ! [[ -z "$rofi_theme" ]]; then
    ROFI_OPTIONAL_ARGS+=( -theme "$rofi_theme" )
fi
if ! [[ -z "$rofi_window_anchor" ]]; then
    ROFI_OPTIONAL_ARGS+=( -theme-str '#window {anchor:'"$rofi_window_anchor"';}' )
fi

# `pactl list sinks` shows sink properties with a mix of english language and local language
# defined by LANG env var, so we unset the var to guarantee only the fallback language is used
unset LANG;

# Get the original sink list from wpctl
sink_list="$(wpctl status | sed -n '/^Audio/,/^\s*$/p' | sed -n '/Sinks:/,/│\s*$/p' | head -n -1 | tail -n +2 | tr -d '│')"

if [ $DEBUG -eq 1 ]; then
    echo "Original sink list:" >&2
    echo "$sink_list" >&2
    echo "Ignore patterns: ${IGNORE_DESCRIPTIONS[*]}" >&2
    echo "Exact match mode: $EXACT_MATCH" >&2
fi

# Iterate the sink list, building parallel arrays of sink IDs and display labels.
# The displayed label is the alias when one matches, otherwise the real description.
SINK_IDS=()
SINK_LABELS=()
while IFS= read -r line; do
    [ -n "$line" ] || continue

    # Extract the description (everything after the ID and status indicators) and the ID.
    # wpctl format is typically: "    * 60. USB Audio Pro                         [vol: 1.00]"
    description=$(echo "$line" | sed -e 's/^[[:space:]]*\*\?[[:space:]]*//' -e 's/[[:space:]]*\[.*$//')
    sink_id=$(echo "$description" | sed -e 's/^\([0-9][0-9]*\)\..*/\1/')
    description=$(echo "$description" | sed -e 's/^[0-9][0-9]*\.[[:space:]]*//')

    if [ $DEBUG -eq 1 ]; then
        echo "Checking line: $line" >&2
        echo "Extracted description: '$description' (id: $sink_id)" >&2
    fi

    # Check if this sink should be ignored
    ignored=0
    for ignore_desc in "${IGNORE_DESCRIPTIONS[@]}"; do
        if matches "$description" "$ignore_desc"; then
            ignored=1
            if [ $DEBUG -eq 1 ]; then
                echo "  -> Ignoring (match '$ignore_desc')" >&2
            fi
            break
        fi
    done
    [ $ignored -eq 0 ] || continue

    # Determine the display label (alias if one matches)
    label=""
    if [ ${#ALIAS_DESCRIPTIONS[@]} -gt 0 ] && label=$(alias_for "$description"); then
        if [ $DEBUG -eq 1 ]; then
            echo "  -> Aliasing to '$label'" >&2
        fi
    else
        # No alias; hide unless explicitly kept (--only not set, or it's a keep)
        if [ $ONLY_KEPT -eq 1 ]; then
            if [ $DEBUG -eq 1 ]; then
                echo "  -> Hiding (not aliased, --only set)" >&2
            fi
            continue
        fi
        label="$description"
    fi

    SINK_IDS+=("$sink_id")
    SINK_LABELS+=("$label")
done <<< "$sink_list"

if [ $DEBUG -eq 1 ]; then
    echo "Final sinks (${#SINK_IDS[@]}):" >&2
    for i in "${!SINK_IDS[@]}"; do
        echo "  ${SINK_IDS[$i]} -> ${SINK_LABELS[$i]}" >&2
    done
fi

# Check if we have any sinks left
if [ ${#SINK_IDS[@]} -eq 0 ]; then
    echo "No sinks available after filtering" >&2
    exit 1
fi

CONTENT="$(printf '%s\n' "${SINK_LABELS[@]}")"
SELECTION=$(echo "$CONTENT" | rofi -dmenu -auto-select -matching fuzzy -i "${ROFI_OPTIONAL_ARGS[@]}")

if ! [[ -z "$SELECTION" ]]; then
    # Map the selected label back to its sink ID
    for i in "${!SINK_LABELS[@]}"; do
        if [ "${SINK_LABELS[$i]}" = "$SELECTION" ]; then
            wpctl set-default "${SINK_IDS[$i]}"
            break
        fi
    done
fi
