#!/bin/bash
#
# Codex Ralph Loop - Wrapper
#

set -e

SOURCE_PATH="${BASH_SOURCE[0]}"
if command -v realpath >/dev/null 2>&1; then
    SOURCE_PATH="$(realpath "$SOURCE_PATH")"
elif command -v readlink >/dev/null 2>&1; then
    SOURCE_PATH="$(readlink -f "$SOURCE_PATH" 2>/dev/null || echo "$SOURCE_PATH")"
else
    # Portable symlink resolution fallback (Python is common on dev machines)
    SOURCE_PATH="$(python -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$SOURCE_PATH" 2>/dev/null || echo "$SOURCE_PATH")"
fi

SCRIPT_DIR="$(cd "$(dirname "$SOURCE_PATH")" && pwd)"
CORE_PATH="$SCRIPT_DIR/ralph-loop-core.sh"

export PROVIDER="codex"

if [[ ! -f "$CORE_PATH" ]]; then
    echo "Error: ralph-loop-core.sh not found in $SCRIPT_DIR" >&2
    exit 1
fi

# shellcheck source=ralph-loop-core.sh
source "$CORE_PATH"

main "$@"
