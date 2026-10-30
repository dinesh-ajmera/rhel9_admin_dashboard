#!/usr/bin/env bash
# lib.sh - small helpers shared by all the other scripts.
# Each script loads it with:   source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Which files to read. Tests point these at fake files so nothing real is touched.
PASSWD_FILE=${PASSWD_FILE:-/etc/passwd}
GROUP_FILE=${GROUP_FILE:-/etc/group}

# "Regular" accounts are the ones people create: UID/GID 1000..59999.
# Below 1000 = system accounts (root, sshd, ...). 65534 = nobody.
MIN_ID=1000
MAX_ID=60000

# Print an error message on stderr and stop the script with exit code 1.
die() {
  echo "error: $*" >&2
  exit 1
}

require_root() {
  [[ $EUID -eq 0 ]] || die "this action needs root. Run the dashboard with sudo."
}

# A valid Linux name: starts with a lowercase letter or _, then a-z 0-9 _ -, max 32 chars.
check_name() {
  [[ $1 =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || die "invalid name: '$1' (use a-z, 0-9, _ or -; max 32 chars)"
}

check_password() {
  ((${#1} >= 12)) || die "password must be at least 12 characters"
}

# Stop unless $1 is an existing REGULAR user (never root or a system account).
require_regular_user() {
  local uid
  uid=$(id -u -- "$1" 2> /dev/null) || die "user '$1' does not exist"
  ((uid >= MIN_ID && uid < MAX_ID)) || die "'$1' is a system account and is protected"
}

# Stop unless $1 is an existing REGULAR group.
require_regular_group() {
  local gid
  gid=$(getent group "$1" | cut -d: -f3)
  [[ -n $gid ]] || die "group '$1' does not exist"
  ((gid >= MIN_ID && gid < MAX_ID)) || die "'$1' is a system group and is protected"
}
