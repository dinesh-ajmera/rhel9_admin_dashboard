#!/usr/bin/env bash
# groups.sh - print groups as a JSON list.
#   groups.sh       -> regular groups only (GID 1000..59999)
#   groups.sh all   -> every group
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

mode=${1:-regular}

# /etc/group lines look like:  name:x:GID:member1,member2
awk -F: -v mode="$mode" -v min="$MIN_ID" -v max="$MAX_ID" '
  function esc(s) { gsub(/[\\"]/, "\\\\&", s); gsub(/\t/, " ", s); return s }

  BEGIN { printf "["; sep = "\n" }
  mode == "all" || ($3 >= min && $3 < max) {
    # turn "a,b,c" into "a","b","c"
    n = split($4, m, ","); members = ""
    for (i = 1; i <= n; i++) members = members (i > 1 ? "," : "") "\"" esc(m[i]) "\""
    printf "%s  {\"name\":\"%s\",\"gid\":%d,\"members\":[%s]}", sep, esc($1), $3, members
    sep = ",\n"
  }
  END { print "\n]" }
' "$GROUP_FILE"
