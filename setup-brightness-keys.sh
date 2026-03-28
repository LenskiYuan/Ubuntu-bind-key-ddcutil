#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/bin"
SOURCE_UP_SCRIPT="$SCRIPT_DIR/brightness-up.sh"
SOURCE_DOWN_SCRIPT="$SCRIPT_DIR/brightness-down.sh"
SOURCE_MAX_SCRIPT="$SCRIPT_DIR/brightness-max.sh"
SOURCE_53_SCRIPT="$SCRIPT_DIR/brightness-53.sh"

# Paths
UP_SCRIPT="$HOME/bin/brightness-up.sh"
DOWN_SCRIPT="$HOME/bin/brightness-down.sh"
MAX_SCRIPT="$HOME/bin/brightness-max.sh"
FIFTY_THREE_SCRIPT="$HOME/bin/brightness-53.sh"

# GNOME custom keybinding base path
BASE_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

mkdir -p "$INSTALL_DIR"
cp "$SOURCE_UP_SCRIPT" "$UP_SCRIPT"
cp "$SOURCE_DOWN_SCRIPT" "$DOWN_SCRIPT"
cp "$SOURCE_MAX_SCRIPT" "$MAX_SCRIPT"
cp "$SOURCE_53_SCRIPT" "$FIFTY_THREE_SCRIPT"
chmod +x "$UP_SCRIPT" "$DOWN_SCRIPT" "$MAX_SCRIPT" "$FIFTY_THREE_SCRIPT"

# Existing bindings.
# Some GNOME versions prefix empty or typed arrays with `@as`, so parse out
# only the quoted binding paths instead of trying to trim the raw GVariant.
existing=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
existing_paths=$(printf '%s\n' "$existing" | grep -o "'[^']*'" | tr -d "'" || true)

find_binding_path() {
    local binding_name="$1"
    local path
    local current_name

    for path in $existing_paths; do
        current_name=$(gsettings get "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path" name 2>/dev/null || true)
        if [ "$current_name" = "'$binding_name'" ]; then
            printf '%s\n' "$path"
            return 0
        fi
    done

    return 1
}

next_custom_index() {
    local max_index=-1
    local path
    local index

    for path in $existing_paths; do
        case "$path" in
            */custom[0-9]*/)
                index="${path##*/custom}"
                ;;
            *)
                continue
                ;;
        esac
        index="${index%/}"
        if [ "$index" -gt "$max_index" ]; then
            max_index="$index"
        fi
    done

    printf '%s\n' $((max_index + 1))
}

UP_PATH="$(find_binding_path "Brightness Up" || true)"
DOWN_PATH="$(find_binding_path "Brightness Down" || true)"
MAX_PATH="$(find_binding_path "Brightness Max" || true)"
FIFTY_THREE_PATH="$(find_binding_path "Brightness 53" || true)"

next_index="$(next_custom_index)"

if [ -z "$UP_PATH" ]; then
    UP_PATH="$BASE_PATH/custom${next_index}/"
    next_index=$((next_index + 1))
fi

if [ -z "$DOWN_PATH" ]; then
    DOWN_PATH="$BASE_PATH/custom${next_index}/"
    next_index=$((next_index + 1))
fi

if [ -z "$MAX_PATH" ]; then
    MAX_PATH="$BASE_PATH/custom${next_index}/"
    next_index=$((next_index + 1))
fi

if [ -z "$FIFTY_THREE_PATH" ]; then
    FIFTY_THREE_PATH="$BASE_PATH/custom${next_index}/"
fi

new_list_items=""
if [ -n "$existing_paths" ]; then
    while IFS= read -r path; do
        [ -n "$path" ] || continue
        if [ -z "$new_list_items" ]; then
            new_list_items="'$path'"
        else
            new_list_items="$new_list_items, '$path'"
        fi
    done <<EOF
$existing_paths
EOF
fi

append_path_if_missing() {
    local path="$1"
    if printf '%s\n' "$new_list_items" | grep -Fq "'$path'"; then
        return
    fi

    if [ -z "$new_list_items" ]; then
        new_list_items="'$path'"
    else
        new_list_items="$new_list_items, '$path'"
    fi
}

append_path_if_missing "$UP_PATH"
append_path_if_missing "$DOWN_PATH"
append_path_if_missing "$MAX_PATH"
append_path_if_missing "$FIFTY_THREE_PATH"

new_list="[$new_list_items]"

# Apply
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_list"

# --- Brightness UP ---
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$UP_PATH name "Brightness Up"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$UP_PATH command "$UP_SCRIPT"
#gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$UP_PATH binding "<Ctrl><Alt>Up"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$UP_PATH binding "<Ctrl><Alt>Page_Up"

# --- Brightness DOWN ---
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$DOWN_PATH name "Brightness Down"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$DOWN_PATH command "$DOWN_SCRIPT"
#gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$DOWN_PATH binding "<Ctrl><Alt>Down"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$DOWN_PATH binding "<Ctrl><Alt>Page_Down"

# --- Brightness MAX ---
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$MAX_PATH name "Brightness Max"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$MAX_PATH command "$MAX_SCRIPT"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$MAX_PATH binding "<Ctrl><Alt>End"

# --- Brightness 53 ---
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$FIFTY_THREE_PATH name "Brightness 53"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$FIFTY_THREE_PATH command "$FIFTY_THREE_SCRIPT"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$FIFTY_THREE_PATH binding "<Ctrl><Alt>Home"

echo "Brightness shortcuts configured."
