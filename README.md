# Ubuntu Brightness Shortcuts with ddcutil

This repo contains small shell scripts to control external monitor brightness on Ubuntu with `ddcutil`, plus a setup script to register GNOME keyboard shortcuts.

# Why Ubuntu doesn’t do this automatically

	Because:
		DDC/CI is not standardized well across monitors
		Can cause crashes or hangs on some hardware
		So Linux leaves it manual

## Files

- `brightness-up.sh`: increase monitor brightness
- `brightness-down.sh`: decrease monitor brightness
- `brightness-max.sh`: set monitor brightness to 100%
- `brightness-53.sh`: set monitor brightness to 53%
- `setup-brightness-keys.sh`: copy the scripts to `~/bin` and register GNOME custom shortcuts

## Requirements

- Ubuntu with GNOME
- `ddcutil` installed
- A monitor that supports DDC/CI

Install `ddcutil` with:

```bash
sudo apt update
sudo apt install ddcutil
```

## Usage

From this repo directory, run:

```bash
./setup-brightness-keys.sh
```

The setup script will:

- create `~/bin` if needed
- copy `brightness-up.sh` and `brightness-down.sh` into `~/bin`
- register GNOME custom shortcuts for brightness control
- reuse existing `Brightness Up` and `Brightness Down` entries instead of creating duplicates

Default shortcut bindings:

- `Ctrl` + `Alt` + `Page Up`: brightness up
- `Ctrl` + `Alt` + `Page Down`: brightness down
- `Ctrl` + `Alt` + `End`: brightness to 100%
- `Ctrl` + `Alt` + `Home`: brightness to 53%

## Notes

- The brightness scripts use VCP code `10`, which is the standard brightness control in `ddcutil`.
- The scripts accept an optional step size. Example:

```bash
~/bin/brightness-up.sh 5
~/bin/brightness-down.sh 5
```
