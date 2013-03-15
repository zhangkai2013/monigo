#!/bin/bash


#172.16.1.40:/var/www/rrdtool/conf/host_config.list.test.tmp

sed -i /172.16.1.41/d /var/www/rrdtool/conf/host_config.list.test.tmp

cat /var/www/rrdtool/conf/host_config.list.test.tmp

echo $1 $# $@

function demo3
{


source /var/www/rrdtool/scripts/config.sh
hostConf="host_config.list.test"

#$script_dir/tcp.sh  $ip $LISTEN $SYN_RECV $ESTABLISHED $TIME_WAIT $CLOSE_WAIT $FIN_WAIT1 $FIN_WAIT2 $CLOSING
$script_dir/tcp.sh   172.16.1.1 7 2 3 0 5 0 7 0
$script_dir/tcp.sh   172.16.1.2 7 2 3 0 5 0 7 0
$script_dir/tcp.sh   172.16.1.4 7 2 3 0 5 0 7 0
$script_dir/tcp.sh   172.16.1.5 7 2 3 0 5 0 7 0
}


function demo2
{
step=$1
for ip in `awk -F:: '{print $2}' $conf_dir/$hostConf`
do
	for step5 in ` grep -w $ip $conf_dir/$hostConf | awk -F:: '{print $3}'| sed 's/:/\ /g'`
	do
		echo "normal step ========>$step5"
	done
	

        for step1 in ` grep -w $ip $conf_dir/$hostConf | awk -F:: '{print $4}'| sed 's/:/\ /g'`
        do
                echo "fast step ========> $step1"
        done
        echo ;echo; echo 
done
}




function demo1
{
step=60;
case $step in 
	60)  A=60;echo $A ;;
	*) step=300 ;B=70;echo $step-$B ;;
esac
A=1
case $A in 
	1)echo "A=1"
	;;
	2)echo "A=2"
	;;
esac
}

function evaltcp
{
TIME_WAIT=0
FIN_WAIT1=0
FIN_WAIT2=0
ESTABLISHED=0
SYN_RECV=0
CLOSING=0
LAST_ACK=0
LISTEN=0
for i in  `cat temp.txt | awk '{print $4} '`
do
	eval ` echo $i | sed 's/["]//g; s/:/=/g'  `
done; 
echo $TIME_WAIT $FIN_WAIT1 $FIN_WAIT2 $ESTABLISHED $SYN_RECV $CLOSING $LAST_ACK $LISTEN
}

#. ./1.sh &
#. ./2.sh &
#. ./4.sh & 
#. ./5.sh &


function sub1
{
echo sub1-`date +%T`
snmpwalk -v2c 172.16.1.1 -c crhkey .1.3.6.1.4.1.2021.71
}

function sub2
{
echo sub2-`date +%T`
snmpwalk -v2c 172.16.1.2 -c crhkey .1.3.6.1.4.1.2021.71
}


function sub3
{
echo sub3-`date +%T`
snmpwalk -v2c 172.16.1.4 -c crhkey .1.3.6.1.4.1.2021.71
}


#sub1&
#sub2&
#sub3&


#snmpwalk -v2c 172.16.1.1 -c crhkey .1.3.6.1.4.1.2021.63.101

function debugtest
{
trap 'echo "before execute line:$LINENO, a=$a,b=$b,c=$c"' DEBUG
a=1
if [ "$a" -eq 1 ]
then
   b=2
else
   b=1
fi
c=3
echo "end"
}
#debugtest


function father
{
#嵌套function 
function son
{
	echo "this is son"
}
echo "this is father"
son
}
#father




function demo
{
var=$1
title_upload="系统负载"
TEXT=$(eval echo \$title_$var)
echo $TEXT
}
#demo upload



#if (( 0 )) ;then
#echo yes
#fi

function matchProcess
{
a=3;b=4
echo $[a+b]
}

#_rrdtool_memory_comment=' -v "默认单位：M"  COMMENT:"\n" COMMENT:"---------------------------------内存统计----------------------------------"  COMMENT:"\n"  COMMENT:"             " COMMENT:"Maximum   " COMMENT:"Average   " COMMENT:"last   \l" '

#echo $_rrdtool_memory_comment



#if [ ! `grep eth0 ./demo.html` ];then
#	echo yes	
#fi

function demo
{

let R=800/8/20
echo $R:bytes/s

interfaces=`cat /proc/net/dev  |grep -v sit0 |grep -v lo  |grep -v Inter |grep -v face | awk -F: '{print $1}'`
#interfaces="eth0 eth1 bond0"
echo $interfaces
for interface in $interfaces
do
	echo $interface
done

}


function testA
{
DAY="day1_png day7_png"
day1_png="/var/www/rrdtool/disk/disk-day.png"
day7_png="/var/www/rrdtool/disk/disk-week.png"
day31_png="/var/www/rrdtool/disk/disk-month.png"
day365_png="/var/www/rrdtool/disk/disk-year.png"
for i in  1  7  31 365
do
}eval "echo \${day${i}_png}"
done

TYPES="A B"
A="ha"
B="ka"
day1="hello"
echo $day1

for type in $TYPES
do 
     for tmp in ${!type}
     do 
	echo $tmp
     done
done

#for type in $TYPES
#do
#        eval "for tmp in \${${type}};do echo \$tmp;done"
#done

colors=(root 5BBD2B 205AA7 FF9912 AA00CC)
#echo ${#colors[@]}            
#echo ${colors[2]}       
#echo ${colors[@]}
for i in 1 2 3 4
do
		echo ${colors[$i]}
done 
echo "a b"|awk '{print $1,$2}'|read i1 i2
#echo "a b" | eval $(awk  '{print "i1=$1 i2=$3"}')
#eval $(echo "aa:bb" | awk -F ":" '{print "i1="$1";i2="$2}')
#echo $i1  $i2




var="A B C"
for v in $var
do
	echo $v
done
}
