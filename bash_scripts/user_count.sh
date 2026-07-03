count=`cat < /etc/passwd | awk -F: '/bash$/{print $3}' | wc -l`
echo $count
