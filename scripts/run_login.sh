#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"

mkdir -p "$LOG_DIR"
exec > >(/usr/bin/tee -a "$LOG_DIR/login.log") 2>&1

echo "===== $(date '+%Y-%m-%d %H:%M:%S') CUMT auto login start ====="
"$SCRIPT_DIR/cumt-campus-login.sh" "$@"
exit_code=$?
echo "exit code: $exit_code"
echo "===== $(date '+%Y-%m-%d %H:%M:%S') CUMT auto login end ====="
exit "$exit_code"

