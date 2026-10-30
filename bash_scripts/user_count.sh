#!/usr/bin/env bash
# user_count.sh - print how many regular users exist (UID 1000..59999).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# For every matching line add 1 to n; at the end print n ("+ 0" prints 0 instead of nothing).
awk -F: -v min="$MIN_ID" -v max="$MAX_ID" '$3 >= min && $3 < max { n++ } END { print n + 0 }' "$PASSWD_FILE"
