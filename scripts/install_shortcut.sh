#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
COMMAND_NAME="${1:-cumt-login}"
TARGET_PATH="$INSTALL_DIR/$COMMAND_NAME"
SOURCE_PATH="$PROJECT_ROOT/scripts/run_login.sh"

mkdir -p "$INSTALL_DIR"
chmod +x "$SOURCE_PATH"
ln -sfn "$SOURCE_PATH" "$TARGET_PATH"

printf 'Installed shortcut: %s -> %s\n' "$TARGET_PATH" "$SOURCE_PATH"

case ":$PATH:" in
  *":$INSTALL_DIR:"*)
    printf 'Command is ready. You can run: %s\n' "$COMMAND_NAME"
    ;;
  *)
    printf 'Shortcut installed, but %s is not in PATH.\n' "$INSTALL_DIR"
    printf 'Add this line to your shell config if needed:\n'
    printf 'export PATH="%s:$PATH"\n' "$INSTALL_DIR"
    printf 'Then reopen the terminal and run: %s\n' "$COMMAND_NAME"
    ;;
esac

