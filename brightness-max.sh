#!/usr/bin/env bash
set -euo pipefail

if ! command -v ddcutil >/dev/null 2>&1; then
  echo "ddcutil is not installed or not in PATH" >&2
  exit 1
fi

ddcutil setvcp 10 100
