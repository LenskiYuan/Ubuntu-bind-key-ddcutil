#!/usr/bin/env bash
set -euo pipefail

STEP="${1:-10}"

if ! command -v ddcutil >/dev/null 2>&1; then
  echo "ddcutil is not installed or not in PATH" >&2
  exit 1
fi

if ! [[ "$STEP" =~ ^[0-9]+$ ]] || [ "$STEP" -le 0 ]; then
  echo "Step must be a positive integer" >&2
  exit 1
fi

current_output="$(ddcutil getvcp 10)"

current_value="$(printf '%s\n' "$current_output" | sed -n 's/.*current value = *\([0-9][0-9]*\).*/\1/p')"
max_value="$(printf '%s\n' "$current_output" | sed -n 's/.*max value = *\([0-9][0-9]*\).*/\1/p')"

if [ -z "$current_value" ] || [ -z "$max_value" ]; then
  echo "Failed to parse brightness from ddcutil output:" >&2
  printf '%s\n' "$current_output" >&2
  exit 1
fi

new_value=$((current_value + STEP))
if [ "$new_value" -gt "$max_value" ]; then
  new_value="$max_value"
fi

ddcutil setvcp 10 "$new_value"
