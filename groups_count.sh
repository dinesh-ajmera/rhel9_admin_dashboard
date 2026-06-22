x=$(cat < /etc/group | awk -F: '{print $3}')
count=0;
for i in $x; 
do 
	if (test $i -ge 1000) ;
       	then
		((count++));	
	fi  
done 
echo $count
