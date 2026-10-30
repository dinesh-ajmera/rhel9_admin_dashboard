#!/usr/bin/env bash
# user_add.sh - create a user.
#   printf '%s\n' "$PASSWORD" | ./user_add.sh USERNAME ["Full Name"]
#
# The password is read from STDIN, not from an argument, so it never shows up in
# `ps`, the shell history or the dashboard's logs.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

username=${1:-}
comment=${2:-}

check_name "$username"
[[ $comment =~ ^[^:[:cntrl:]]{0,100}$ ]] || die "full name: max 100 characters, no ':' or control characters"
IFS= read -r password || die "no password received on stdin"
check_password "$password"
require_root

if id -- "$username" > /dev/null 2>&1; then
  die "user '$username' already exists"
fi

useradd -m -c "$comment" "$username"

# chpasswd reads "user:password" from stdin and hashes it for us.
# printf is a shell builtin, so the password is not visible in the process list.
if ! printf '%s:%s\n' "$username" "$password" | chpasswd; then
  userdel -r "$username" || true # undo the half-created user
  die "could not set the password; the user was removed again"
fi

echo "created user $username"
