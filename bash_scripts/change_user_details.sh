old_detail=$1

modified_detail=$2


sed -i 's|'"$old_detail"'|'"$modified_detail"'|' /etc/passwd

