# declare a discnary
declare -A users_disc


#for i in {echo "5..1"};
#do
#      users_disc[username]=$(cat < /etc/passwd | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $1}');
#      users_disc[id]=$(cat < /etc/passwd | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $3}');
#      echo -e "name : $users_disc[username]   \t id :  $users_disc[id]";
#done
#
#

#echo -e "name       \t passwd \t UID \t GID \t shell";

total_users=$(cat  -n /etc/passwd | awk -F" " '{print $1}')


echo "{"
for i in $total_users;
do
	users_disc[username]=$(cat < /etc/passwd | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $1}');
	users_disc[passwd]=$(cat < /etc/passwd | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $2}');
	users_disc[UID]=$(cat < /etc/passwd | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $3}');
	users_disc[GID]=$(cat < /etc/passwd | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $4}');
	users_disc[shell]=$(cat < /etc/passwd | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $7}');
	users_disc[HD]=$(cat < /etc/passwd | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $6}');
	users_disc[comments]=$(cat < /etc/passwd | tail -$i | head -$(expr $i - $(expr $i - 1)) | awk -F: '{print $5}');


#       	echo -e "name : ${users_disc[username]} \t passwd :  ${users_disc[passwd]} \t UID : ${users_disc[UID]} \t GID : ${users_disc[GID]} \t shell : ${users_disc[shell]} ";
#
#	echo -e "${users_disc[username]}       \t ${users_disc[passwd]} \t ${users_disc[UID]} \t ${users_disc[GID]} \t ${users_disc[shell]} ";


#	echo -e "[name]='${users_disc[username]}' \t[passwd]='${users_disc[passwd]}' \t [UID]='${users_disc[UID]}' \t [GID]='${users_disc[GID]}' \t [shell]='${users_disc[shell]}' ";


echo  -e '\t"'${i}'"' : '[{"name":"'${users_disc[username]}'",\n\t\t"passwd":"'${users_disc[passwd]}'",\n\t\t"UID":"'${users_disc[UID]}'",\n\t\t"GID":"'${users_disc[GID]}'",\n\t\t"comments":"'${users_disc[comments]}'",\n\t\t"HD":"'${users_disc[HD]}'",\n\t\t"shell":"'${users_disc[shell]}'" \n\t\t}] ,';

done
echo   '"e"' : '{"name":"","passwd":"","UID":"","GID":"","comments":"","HD":"" ,"shell":""}';
echo }
