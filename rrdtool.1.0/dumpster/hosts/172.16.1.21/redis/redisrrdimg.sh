#!/bin/bash
#
#
#


hostIP="172.16.1.21"
workdir="/var/www/rrdtool/$hostIP/redis"
rrdtool="/usr/local/rrdtool/bin/rrdtool"
rrdfile="redisinfo.rrd"
snmpstr="snmpwalk -v 1 $hostIP -c crhkey .1.3.6.1.4.1.2021.63"
element_count=`$snmpstr |grep 63.101 | wc -l`
colors=(103667 205AA7 F1AF00 F9F400  5BBD2B  FF9912 3A2885)
number_space=(13.0lf 13.0lf 9.0lf 6.0lf 6.0lf 6.0lf 6.0lf)
cd $workdir

comment_str="redis客户端连接数"
title_str="redis 监控值"


function  graph_picture
{


	######## get_partition_lable
        i=1
        while (($i<=$element_count))
        do
                DS_NAME=`$snmpstr |grep 63.101 | awk -F\" '{print $2}' | sed -n ${i}p | awk -F: '{print $1}'`
                DEF_STR_TEMP=DEF:value$i=${workdir}/${rrdfile}:$DS_NAME:AVERAGE
                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
	
		LABLE=$DS_NAME
		LABLE_STR=$LABLE_STR" LINE1:value$i#${colors[$i]}:"$LABLE" GPRINT:value$i:LAST:%${number_space[$i]}   COMMENT:\n" 
                i=$(($i+1))
		#echo $LABLE_STR
        done

	######### graph some day picture
	while ((1<2))
	do
		for i in  1  7  31 365
		do 

	$rrdtool graph  day${i}.png  --step 120   --start now-${i}d   -w 900 -h 200 -Y -b 1000  --x-grid MINUTE:10:HOUR:1:HOUR:1:0:'%H'   --lower-limit 0  -t "${hostIP}${title_str}" -v "默认单位：个"  $DEF_STR  COMMENT:" \n"  COMMENT:"---------$comment_str----------"  COMMENT:"\n" $LABLE_STR COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"   -c BACK#CAE5E8
	      # -c CANVAS#FFFBD1

		done
		sleep 120
	done
}

graph_picture

