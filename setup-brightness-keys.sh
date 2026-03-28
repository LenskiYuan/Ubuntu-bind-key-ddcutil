#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/bin"
SOURCE_UP_SCRIPT="$SCRIPT_DIR/brightness-up.sh"
SOURCE_DOWN_SCRIPT="$SCRIPT_DIR/brightness-down.sh"

# Paths
UP_SCRIPT="$HOME/bin/brightness-up.sh"
DOWN_SCRIPT="$HOME/bin/brightness-down.sh"

# GNOME custom keybinding base path
BASE_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

mkdir -p "$INSTALL_DIR"
cp "$SOURCE_UP_SCRIPT" "$UP_SCRIPT"
cp "$SOURCE_DOWN_SCRIPT" "$DOWN_SCRIPT"
chmod +x "$UP_SCRIPT" "$DOWN_SCRIPT"

# Existing bindings
existing=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)

# Convert to array (remove brackets)
existing=${existing#\[}
existing=${existing%\]}

find_binding_path() {
    local binding_name="$1"
    local path

    for path in $(printf '%s\n' "$existing" | grep -o "'[^']*'" | tr -d "'"); do
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

    for path in $(printf '%s\n' "$existing" | grep -o "custom[0-9]*/"); do
        index="${path#custom}"
        index="${index%/}"
        if [ "$index" -gt "$max_index" ]; then
            max_index="$index"
        fi
    done

    printf '%s\n' $((max_index + 1))
}

UP_PATH="$(find_binding_path "Brightness Up" || true)"
DOWN_PATH="$(find_binding_path "Brightness Down" || true)"

next_index="$(next_custom_index)"

if [ -z "$UP_PATH" ]; then
    UP_PATH="$BASE_PATH/custom${next_index}/"
    next_index=$((next_index + 1))
fi

if [ -z "$DOWN_PATH" ]; then
    DOWN_PATH="$BASE_PATH/custom${next_index}/"
fi

new_list_items=""
if [ -n "$existing" ]; then
    new_list_items="$existing"
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

echo "Brightness shortcuts configured."
