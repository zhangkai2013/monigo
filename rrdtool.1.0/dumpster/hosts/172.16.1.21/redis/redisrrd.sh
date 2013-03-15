#!/bin/bash
# 该脚本所属自动化运维的一部分
# 自动匹配分区以及使用情况并记录入据

hostip="172.16.1.21"
workdir="/var/www/rrdtool/$hostip/redis"
rrdtool="/usr/local/rrdtool/bin/rrdtool"
rrdfile="redisinfo.rrd"
snmpstr="snmpwalk -v 1 $hostip -c crhkey .1.3.6.1.4.1.2021.63"
element_count=`$snmpstr |grep 63.101 | wc -l`


function create_rrd
{
#初始化创建rrd文件,初始只做一次，做完退出。

if [ ! -e $workdir/$rrdfile ];then
	i=1
	while (($i<=$element_count))
	do	
		DS_NAME=`$snmpstr |grep 63.101 | awk -F\" '{print $2}' | sed -n ${i}p | awk -F: '{print $1}'`
                DS_STR_TEMP=DS:$DS_NAME:GAUGE:600:0:U 
		DS_STR=$DS_STR" "$DS_STR_TEMP
		i=$(($i+1))
	done
	#$rrdtool create ${workdir}/${rrdfile} --step 120  $DS_STR  RRA:AVERAGE:0.5:1:360 RRA:AVERAGE:0.5:15:336  RRA:AVERAGE:0.5:60:372   RRA:AVERAGE:0.5:360:730
	$rrdtool create ${workdir}/${rrdfile} --step 120  $DS_STR  RRA:AVERAGE:0.5:1:360  RRA:AVERAGE:0.5:15:336  RRA:AVERAGE:0.5:60:372  
	#$rrdtool create ${workdir}/${rrdfile} --step 300  $DS_STR  RRA:AVERAGE:0.5:1:600  RRA:AVERAGE:0.5:4:600  RRA:AVERAGE:0.5:24:600   RRA:AVERAGE:0.5:288:730

fi

}


function get_save_rrd
{

#通过snmp 获取数据存入rrd文件,该方法循环执行，间隔时间内循环执行，不退出。

if [ -e $workdir/$rrdfile ];then

   while [ 1 ];do

        i=1
        while (($i<=$element_count))
        do
                VALUE_TEMP=`$snmpstr |grep 63.101 | awk -F\" '{print $2}' | sed -n ${i}p | awk -F: '{print $2}'| sed 's/\\r//g'`
                #VALUE_TEMP=`$snmpstr |grep 63.101 | awk -F\" '{print $2}' | sed -n ${i}p | awk -F: '{print $2}'`
                UPDATE_STR=$UPDATE_STR":"$VALUE_TEMP
                i=$(($i+1))
        done
  	$rrdtool updatev ${workdir}/${rrdfile}  N${UPDATE_STR}	
	UPDATE_STR=""
	#sleep 300
	sleep 120
  done
fi

}

create_rrd
get_save_rrd
