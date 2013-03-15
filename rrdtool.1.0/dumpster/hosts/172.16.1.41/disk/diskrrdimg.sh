#!/bin/bash
#
#
#
source config.sh

hostIP="172.16.1.41"
workdir="$host_dir/$hostIP/disk"
rrdtool="/usr/local/rrdtool/bin/rrdtool"
rrdfile="disk.rrd"
snmpstr="snmpwalk -v 1 $hostIP -c crhkey .1.3.6.1.4.1.2021.62"
partition_count=`$snmpstr |grep 62.101 | wc -l`
colors=(103667  F1AF00 F9F400  5BBD2B 205AA7 FF9912 3A2885)
number_space=(13.0lf 13.0lf 9.0lf 6.0lf 6.0lf 6.0lf 6.0lf)
cd $workdir


function  graph_picture
{


	######## get_partition_lable
        i=1
        while (($i<=$partition_count))
        do
                DEF_STR_TEMP=DEF:value$i=${workdir}/${rrdfile}:partition$i:AVERAGE
                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
	
		LABLE=`$snmpstr | grep 62.101|awk -F\" '{print $2}' |  sed -n ${i}p | awk '{print $1}'`
		LABLE_STR=$LABLE_STR" AREA:value$i#${colors[$i]}:"$LABLE" GPRINT:value$i:LAST:%${number_space[$i]}  COMMENT:%\n" 
                i=$(($i+1))
		#echo $LABLE_STR
        done

	######### graph some day picture
	while ((1<2))
	do
		for i in  1  7  31 365
		do 

	$rrdtool graph  day${i}.png  --step 300   --start now-${i}d   -w 800 -h 200 -Y -b 1000  --x-grid MINUTE:10:HOUR:1:HOUR:1:0:'%H'  --lower-limit 0 --upper-limit 100   -t "$hostIP磁盘空间使用情况" -v "默认单位：百分比%"  $DEF_STR  COMMENT:" \n"  COMMENT:"---------磁盘分区已经使用比例----------"  COMMENT:"\n" $LABLE_STR COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"   -c BACK#CAE5E8
	      # -c CANVAS#FFFBD1

		done
		sleep 300
	done
}

graph_picture

