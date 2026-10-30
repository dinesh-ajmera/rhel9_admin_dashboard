#!/usr/bin/env bash
# group_add.sh - create a group.   ./group_add.sh GROUPNAME
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

name=${1:-}
check_name "$name"
require_root

if getent group "$name" > /dev/null; then
  die "group '$name' already exists"
fi

groupadd "$name"
echo "created group $name"
