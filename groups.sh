# declare a discnary
declare -A groups_disc


#for i in {echo "5..1"};
#do
#      users_disc[username]=$(cat < /etc/passwd | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $1}');
#      users_disc[id]=$(cat < /etc/passwd | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $3}');
#      echo -e "name : $users_disc[username]   \t id :  $users_disc[id]";
#done
#
#

#echo -e "name       \t passwd \t UID \t GID \t shell";

#total_groups=$(cat  -n /etc/group | awk -F" " '{print $1}')
total_groups=$(cat  -n /etc/group | awk -F" " '{print $1}' | tail -1 )


#while (test "$i" -lt "$total_groups"); do ((i++)); echo $i; done



i=1
echo "{"
while (test "$i" -le "$total_groups");
do
#	((i++))
	groups_disc[groupname]=$(cat < /etc/group | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $1}');
	groups_disc[passwd]=$(cat < /etc/group | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $2}');
	groups_disc[GID]=$(cat < /etc/group | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $3}');
	groups_disc[users]=$(cat < /etc/group | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $4}');
	((i++))


#       	echo -e "name : ${users_disc[username]} \t passwd :  ${users_disc[passwd]} \t UID : ${users_disc[UID]} \t GID : ${users_disc[GID]} \t shell : ${users_disc[shell]} ";
#
#	echo -e "${users_disc[username]}       \t ${users_disc[passwd]} \t ${users_disc[UID]} \t ${users_disc[GID]} \t ${users_disc[shell]} ";


#	echo -e "[name]='${users_disc[username]}' \t[passwd]='${users_disc[passwd]}' \t [UID]='${users_disc[UID]}' \t [GID]='${users_disc[GID]}' \t [shell]='${users_disc[shell]}' ";


echo  -e '\t"'${i}'"' : '[{"name":"'${groups_disc[groupname]}'",\n\t\t"passwd":"'${groups_disc[passwd]}'",\n\t\t"GID":"'${groups_disc[GID]}'",\n\t\t"users":"'${groups_disc[users]}'"\n\t\t}] ,';

done
echo   '"e"' : '{"name":"","passwd":"","GID":"","users":""}';
echo }
