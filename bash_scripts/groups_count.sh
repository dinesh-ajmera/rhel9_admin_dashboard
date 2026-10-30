#!/usr/bin/env bash
# groups_count.sh - print how many regular groups exist (GID 1000..59999).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

awk -F: -v min="$MIN_ID" -v max="$MAX_ID" '$3 >= min && $3 < max { n++ } END { print n + 0 }' "$GROUP_FILE"
