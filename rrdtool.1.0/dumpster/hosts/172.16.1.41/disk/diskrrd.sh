#!/bin/bash
# 该脚本所属自动化运维的一部分
# 自动匹配分区以及使用情况并记录入据

source config.sh
hostip="172.16.1.41"
workdir="$host_dir/$hostip/disk"
rrdtool="/usr/local/rrdtool/bin/rrdtool"
rrdfile="disk.rrd"
snmpstr="snmpwalk -v 1 $hostip -c crhkey .1.3.6.1.4.1.2021.62"
partition_count=`$snmpstr |grep 62.101 | wc -l`


function create_rrd
{
#初始化创建rrd文件

if [ ! -e $workdir/$rrdfile ];then
	i=1
	while (($i<=$partition_count))
	do	
                DS_STR_TEMP=DS:partition$i:GAUGE:600:0:100 
		DS_STR=$DS_STR" "$DS_STR_TEMP
		i=$(($i+1))
	done
	$rrdtool create ${workdir}/${rrdfile} --step 300  $DS_STR  RRA:AVERAGE:0.5:1:288 RRA:AVERAGE:0.5:6:336  RRA:AVERAGE:0.5:24:372   RRA:AVERAGE:0.5:144:730

fi

}


function get_save_rrd
{

#通过snmp 获取数据存入rrd文件

if [ -e $workdir/$rrdfile ];then

   while [ 1 ];do

        i=1
        while (($i<=$partition_count))
        do
                VALUE_TEMP=`$snmpstr |grep 62.101 | awk -F\" '{print $2}' | sed -n ${i}p | awk '{print $3}'|awk -F"%" '{print $1}'`
                UPDATE_STR=$UPDATE_STR":"$VALUE_TEMP
                i=$(($i+1))
        done
  	$rrdtool updatev ${workdir}/${rrdfile}  N$UPDATE_STR	
	UPDATE_STR=""
	sleep 300
  done
fi

}

create_rrd
get_save_rrd
