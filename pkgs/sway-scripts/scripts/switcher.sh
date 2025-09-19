#! /bin/sh
# Parse command line arguments for sink descriptions to ignore
IGNORE_DESCRIPTIONS=()
EXACT_MATCH=0
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
        --exact)
            EXACT_MATCH=1
            shift
            ;;
        --debug)
            DEBUG=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--ignore 'description'] [--ignore='description'] [--exact] [--debug]"
            echo "  --ignore: Ignore sinks with this description"
            echo "  --exact:  Use exact matching instead of substring matching"
            echo "  --debug:  Show debug information"
            echo "Example: $0 --ignore 'Monitor' --ignore='Echo-Cancel'"
            echo "Example: $0 --exact --ignore 'Built-in Audio Analog Stereo'"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

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

# If we have ignore patterns, filter the list
if [ ${#IGNORE_DESCRIPTIONS[@]} -gt 0 ]; then
    if [ $DEBUG -eq 1 ]; then
        echo "Filtering sink list..." >&2
    fi
    
    # Filter the sink list based on descriptions in the wpctl output itself
    filtered_list=""
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            # Extract the description part (everything after the ID and status indicators)
            # wpctl format is typically: "    * 60. USB Audio Pro                         [vol: 1.00]"
            # Remove leading spaces, optional *, spaces, number, dot, spaces, then remove trailing [vol...] part
            description=$(echo "$line" | sed -e 's/^[[:space:]]*\*\?[[:space:]]*[0-9]\+\.[[:space:]]*//' -e 's/[[:space:]]*\[.*$//')
            
            if [ $DEBUG -eq 1 ]; then
                echo "Checking line: $line" >&2
                echo "Extracted description: '$description'" >&2
            fi
            
            # Check if this sink should be ignored
            should_ignore=0
            for ignore_desc in "${IGNORE_DESCRIPTIONS[@]}"; do
                if [ $EXACT_MATCH -eq 1 ]; then
                    # Exact match (case-sensitive)
                    if [ "$description" = "$ignore_desc" ]; then
                        should_ignore=1
                        if [ $DEBUG -eq 1 ]; then
                            echo "  -> Ignoring (exact match '$ignore_desc')" >&2
                        fi
                        break
                    fi
                else
                    # Substring match (case-insensitive)
                    if echo "$description" | grep -qi "$ignore_desc"; then
                        should_ignore=1
                        if [ $DEBUG -eq 1 ]; then
                            echo "  -> Ignoring (contains '$ignore_desc')" >&2
                        fi
                        break
                    fi
                fi
            done
            
            if [ $should_ignore -eq 0 ]; then
                if [ $DEBUG -eq 1 ]; then
                    echo "  -> Keeping" >&2
                fi
                if [ -n "$filtered_list" ]; then
                    filtered_list="$filtered_list
$line"
                else
                    filtered_list="$line"
                fi
            fi
        fi
    done <<< "$sink_list"
    
    sink_list="$filtered_list"
fi

if [ $DEBUG -eq 1 ]; then
    echo "Final sink list:" >&2
    echo "$sink_list" >&2
fi

# Check if we have any sinks left
if [ -z "$sink_list" ]; then
    echo "No sinks available after filtering" >&2
    exit 1
fi

CONTENT="$sink_list"
let "WIDTH = $(wc -L <<< "$CONTENT")"
OPTION_SELECTED=$(echo "$CONTENT" \
  | rofi -dmenu -auto-select -matching fuzzy -i "${ROFI_OPTIONAL_ARGS[@]}"  \
  | sed -e 's/[^0-9]*\([0-9]*\).*/\1/g')

if ! [[ -z "$OPTION_SELECTED" ]]; then
    wpctl set-default "$OPTION_SELECTED"
fi
