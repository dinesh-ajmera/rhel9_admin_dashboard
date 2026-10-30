#!/usr/bin/env bash
# change_group_details.sh - change a regular group.
#   ./change_group_details.sh GROUP rename     NEWNAME
#   ./change_group_details.sh GROUP add-user   USERNAME
#   ./change_group_details.sh GROUP remove-user USERNAME
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

group=${1:-}
action=${2:-}
value=${3:-}

check_name "$group"
require_regular_group "$group"

case $action in
  rename)
    check_name "$value"
    if getent group "$value" > /dev/null; then die "group '$value' already exists"; fi
    require_root
    groupmod -n "$value" "$group"
    ;;
  add-user)
    check_name "$value"
    require_regular_user "$value"
    require_root
    gpasswd -a "$value" "$group" > /dev/null
    ;;
  remove-user)
    check_name "$value"
    require_regular_user "$value"
    require_root
    gpasswd -d "$value" "$group" > /dev/null
    ;;
  *)
    die "unknown action '$action' (use: rename, add-user, remove-user)"
    ;;
esac

echo "updated group $group ($action $value)"
