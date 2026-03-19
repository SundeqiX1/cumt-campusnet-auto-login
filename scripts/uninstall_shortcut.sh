#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
COMMAND_NAME="${1:-cumt-login}"
TARGET_PATH="$INSTALL_DIR/$COMMAND_NAME"

if [[ -L "$TARGET_PATH" || -f "$TARGET_PATH" ]]; then
  rm -f "$TARGET_PATH"
  printf 'Removed shortcut: %s\n' "$TARGET_PATH"
else
  printf 'Shortcut not found: %s\n' "$TARGET_PATH"
fi

