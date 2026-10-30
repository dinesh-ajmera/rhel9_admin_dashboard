#!/usr/bin/env bash
# change_user_details.sh - change one detail of a regular user.
#   ./change_user_details.sh USERNAME comment "New Full Name"
#   ./change_user_details.sh USERNAME shell   /bin/bash
#   ./change_user_details.sh USERNAME home    /home/newplace
#   ./change_user_details.sh USERNAME lock|unlock
#
# Uses the official `usermod` tool instead of editing /etc/passwd with sed.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

username=${1:-}
field=${2:-}
value=${3:-}

check_name "$username"
require_regular_user "$username"

case $field in
  comment)
    [[ $value =~ ^[^:[:cntrl:]]{0,100}$ ]] || die "full name: max 100 characters, no ':' or control characters"
    require_root
    usermod -c "$value" "$username"
    ;;
  shell)
    grep -qxF -- "$value" /etc/shells || die "'$value' is not listed in /etc/shells"
    require_root
    usermod -s "$value" "$username"
    ;;
  home)
    [[ $value =~ ^/[A-Za-z0-9._/-]+$ && $value != *..* ]] || die "home must be an absolute path like /home/name"
    require_root
    usermod -d "$value" "$username"
    ;;
  lock)
    require_root
    usermod -L "$username"
    ;;
  unlock)
    require_root
    usermod -U "$username"
    ;;
  *)
    die "unknown field '$field' (use: comment, shell, home, lock, unlock)"
    ;;
esac

echo "updated $field of $username"
