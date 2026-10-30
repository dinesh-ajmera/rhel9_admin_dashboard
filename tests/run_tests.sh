#!/usr/bin/env bash
#
# run_tests.sh - tests for the Bash scripts.
#
#   bash tests/run_tests.sh          read-only + validation tests (any user)
#   sudo bash tests/run_tests.sh     ALSO creates and deletes a throw-away user/group (needs root)
#
# No -e on purpose: we want to keep going after a failed check and count it.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

S=bash_scripts
FIX=$PWD/tests/fixtures
passed=0
failed=0

# check "description" EXPECTED_EXIT_CODE command...
check() {
  local name=$1 want=$2 got out
  shift 2
  out=$("$@" 2>&1)
  got=$?
  report "$name" "$((got == want))" "exit code $got, wanted $want: $out"
}

# check_out "description" "text that must appear" command...
check_out() {
  local name=$1 text=$2 out
  shift 2
  out=$("$@" 2>&1)
  [[ $out == *"$text"* ]]
  report "$name" "$((!$?))" "output was: $out"
}

report() {
  if (($2)); then
    passed=$((passed + 1))
    echo "  ok    $1"
  else
    failed=$((failed + 1))
    echo "  FAIL  $1  ($3)"
  fi
}

# Run a script against the fake passwd/group files in tests/fixtures.
fake() { PASSWD_FILE=$FIX/passwd GROUP_FILE=$FIX/group bash "$@"; }

echo "Reading scripts (fake files)"
check_out "user_count counts regular users only" "3" fake $S/user_count.sh
check_out "groups_count counts regular groups only" "4" fake $S/groups_count.sh
check "users.sh prints valid JSON" 0 bash -c "PASSWD_FILE=$FIX/passwd bash $S/users.sh | python3 -m json.tool"
check "groups.sh prints valid JSON" 0 bash -c "GROUP_FILE=$FIX/group bash $S/groups.sh | python3 -m json.tool"
check_out "users.sh hides system accounts" '"alice"' fake $S/users.sh
check "users.sh does not list root by default" 1 bash -c "PASSWD_FILE=$FIX/passwd bash $S/users.sh | grep -q '\"root\"'"
check "users.sh all lists root" 0 bash -c "PASSWD_FILE=$FIX/passwd bash $S/users.sh all | grep -q '\"root\"'"
check_out "quotes inside a comment are escaped" 'Bob \"The Builder\"' fake $S/users.sh
check_out "group members become a JSON list" '"members":["alice","bob","carol"]' fake $S/groups.sh
check_out "empty file gives an empty list" "[" bash -c ": > /tmp/_empty_$$; PASSWD_FILE=/tmp/_empty_$$ bash $S/users.sh; rm -f /tmp/_empty_$$"

echo "Input checks (must be rejected, nothing is changed)"
check "user_add rejects an unsafe name" 1 bash -c "printf '%s\n' 'Long-Enough-Pass1!' | bash $S/user_add.sh 'bad;name'"
check "user_add rejects an uppercase name" 1 bash -c "printf '%s\n' 'Long-Enough-Pass1!' | bash $S/user_add.sh Bob"
check_out "user_add rejects a short password" "at least 12" bash -c "printf '%s\n' short | bash $S/user_add.sh validname"
check_out "user_add needs a password on stdin" "no password" bash -c "bash $S/user_add.sh validname < /dev/null"
check "group_add rejects an unsafe name" 1 bash $S/group_add.sh 'bad name'
check_out "root cannot be modified" "protected" bash $S/change_user_details.sh root shell /bin/bash
check_out "unknown user is reported" "does not exist" bash $S/change_user_details.sh no_such_user_x shell /bin/bash
check_out "system group cannot be modified" "protected" bash $S/change_group_details.sh root rename x

if ((EUID != 0)); then
  echo "Skipping real create/modify/delete tests (run with sudo to include them)"
else
  echo "Real changes (throw-away user and group)"
  U=dashtest$$
  G=dashgrp$$
  G2=dashnew$$
  PW='Correct-Horse-9!'
  trap 'userdel -r "$U" > /dev/null 2>&1; groupdel "$G" > /dev/null 2>&1; groupdel "$G2" > /dev/null 2>&1' EXIT

  check_out "user_add creates a user" "created user" bash -c "printf '%s\n' '$PW' | bash $S/user_add.sh $U 'Test User'"
  check "the new user exists" 0 id "$U"
  check "the password hash was set" 0 bash -c "getent shadow $U | cut -d: -f2 | grep -q '^\\\$'"
  check_out "a duplicate user is refused" "already exists" bash -c "printf '%s\n' '$PW' | bash $S/user_add.sh $U"
  check_out "comment can be changed" "updated comment" bash $S/change_user_details.sh "$U" comment "Changed Name"
  check "comment really changed" 0 bash -c "getent passwd $U | grep -q 'Changed Name'"
  check_out "shell can be changed" "updated shell" bash $S/change_user_details.sh "$U" shell /bin/sh
  check "a shell outside /etc/shells is refused" 1 bash $S/change_user_details.sh "$U" shell /tmp/evil
  check "a home path with .. is refused" 1 bash $S/change_user_details.sh "$U" home /home/../etc
  check_out "user can be locked" "updated lock" bash $S/change_user_details.sh "$U" lock
  check "lock really applied" 0 bash -c "getent shadow $U | cut -d: -f2 | grep -q '^!'"
  check_out "user can be unlocked" "updated unlock" bash $S/change_user_details.sh "$U" unlock
  check "an unknown field is refused" 1 bash $S/change_user_details.sh "$U" uid 0

  check_out "group_add creates a group" "created group" bash $S/group_add.sh "$G"
  check_out "a duplicate group is refused" "already exists" bash $S/group_add.sh "$G"
  check_out "a user can be added to a group" "updated group" bash $S/change_group_details.sh "$G" add-user "$U"
  check "the membership is real" 0 bash -c "id -nG $U | tr ' ' '\n' | grep -qx $G"
  check_out "a user can be removed from a group" "updated group" bash $S/change_group_details.sh "$G" remove-user "$U"
  check_out "a group can be renamed" "updated group" bash $S/change_group_details.sh "$G" rename "$G2"
  check "the old group name is gone" 2 getent group "$G"  # getent exits 2 for "not found"
fi

echo
echo "passed: $passed   failed: $failed"
((failed == 0))
