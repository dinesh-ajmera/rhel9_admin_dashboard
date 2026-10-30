#!/usr/bin/env bash
# users.sh - print users as a JSON list.
#   users.sh        -> regular users only (UID 1000..59999)
#   users.sh all    -> every account, including system ones
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

mode=${1:-regular}

# One pass over the file. awk splits every line on ":" into $1..$7:
#   name:x:UID:GID:comment:home:shell
awk -F: -v mode="$mode" -v min="$MIN_ID" -v max="$MAX_ID" '
  # Make a string safe inside JSON quotes: put \ before " and \, turn tabs into spaces.
  function esc(s) { gsub(/[\\"]/, "\\\\&", s); gsub(/\t/, " ", s); return s }

  BEGIN { printf "["; sep = "\n" }
  mode == "all" || ($3 >= min && $3 < max) {
    printf "%s  {\"name\":\"%s\",\"uid\":%d,\"gid\":%d,\"comment\":\"%s\",\"home\":\"%s\",\"shell\":\"%s\"}", \
           sep, esc($1), $3, $4, esc($5), esc($6), esc($7)
    sep = ",\n"
  }
  END { print "\n]" }
' "$PASSWD_FILE"
