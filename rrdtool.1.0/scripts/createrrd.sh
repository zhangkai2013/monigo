#!/bin/bash
#
source /var/www/rrdtool/scripts/config.sh

if [ $# -lt 1 ] ;then
        echo  "Usage: $0 [ init | save ]"
        exit
fi

####################################################################################

function init_crate_rrd
{
## 从配置文件列表中读取主机列表，初始化生成每台机器各个监控项的 rrd文件
## 注意：如果已经存在老的rrd文件，则会生成新的rrd文件覆盖老的rrd,老的rrd文件数据会丢失
initrrd=$1
lines=`awk 'END{print NR}' $conf_dir/host_config.list`  ; i=1
while (($i<=$lines))
do 
        ip=`sed -n "$i"p  $conf_dir/host_config.list | awk '{print $2}'`

	for element in $elements
	do 

                DS_STR=
                ## 生成磁盘分区项的字符串
                if [[ $element == partition ]];then
                        partition_count=`snmpwalk -v2c ${ip} -c crhkey UCD-SNMP-MIB::dskPath | wc -l`
                        j=1
                        while (($j<=$partition_count))
                        do
                               DS_STR_TEMP=DS:partition$j:GAUGE:600:0:100
                               DS_STR=$DS_STR" "$DS_STR_TEMP
                               j=$(($j+1))
                        done
                fi


                ## 生成网口流量项字符串
                if [[ $element == traffic ]];then
                        for interface in `snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |awk '{print $4}'|grep -v lo|grep -v sit0|grep -v tun`
                        do
                                for inout in in out
                                do
                                        DS_STR_TEMP=DS:${interface}${inout}:COUNTER:600:0:U
                                        DS_STR=$DS_STR" "$DS_STR_TEMP
                                done
                                done
                fi


                ## 生成系统io读写项字符串
                if [[ $element == io ]];then
                        for diskname in `snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::diskIODevice |grep sd |awk '{print $4}'|cut -c 1-3|uniq`
                        do
                                for iorw in  reads writes readNumbers writeNumbers
                                do
                                DS_STR_TEMP=DS:${diskname}${iorw}:COUNTER:600:0:U
                                DS_STR=$DS_STR" "$DS_STR_TEMP
                                j=$(($j+1))
                                done
                        done
                fi


                ## 生成系统负载项字符串
                if [[ $element == upload ]];then
			for minute in 1 5 15
			do 
                                DS_STR_TEMP=DS:upload$minute:GAUGE:600:0:U
                                DS_STR=$DS_STR" "$DS_STR_TEMP
                                j=$(($j+1))
                        done
                fi



                ## 生成系统内存项字符串
                if [[ $element == memory ]];then
                        for memory in  memTotalReal   memAvailReal   memBuffer  memCached  memTotalSwap   memAvailSwap
                        do
                                DS_STR_TEMP=DS:$memory:GAUGE:600:0:U
                                DS_STR=$DS_STR" "$DS_STR_TEMP
                                j=$(($j+1))
                        done
                fi


		if [ ! -z $DS_STR_TEMP ];then
			if [[ $initrrd == yes  ]];then
				$rrdtool create ${data_dir}/${element}/${ip}.${element}.rrd --step 300  $DS_STR  RRA:AVERAGE:0.5:1:288 RRA:AVERAGE:0.5:6:336  RRA:AVERAGE:0.5:24:372   RRA:AVERAGE:0.5:144:730  RRA:MIN:0.5:1:288 RRA:MIN:0.5:6:336  RRA:MIN:0.5:24:372  RRA:MIN:0.5:144:730 RRA:MAX:0.5:1:288 RRA:MAX:0.5:6:336  RRA:MAX:0.5:24:372   RRA:MAX:0.5:144:730 RRA:LAST:0.5:1:288 RRA:LAST:0.5:6:336  RRA:LAST:0.5:24:372  RRA:LAST:0.5:144:730 
		        elif [[ $initrrd == no ]];then
				if [ ! -e ${data_dir}/${element}/${ip}.${element}.rrd ];then
					$rrdtool create ${data_dir}/${element}/${ip}.${element}.rrd --step 300  $DS_STR  RRA:AVERAGE:0.5:1:288 RRA:AVERAGE:0.5:6:336  RRA:AVERAGE:0.5:24:372   RRA:AVERAGE:0.5:144:730  RRA:MIN:0.5:1:288 RRA:MIN:0.5:6:336  RRA:MIN:0.5:24:372  RRA:MIN:0.5:144:730 RRA:MAX:0.5:1:288 RRA:MAX:0.5:6:336  RRA:MAX:0.5:24:372   RRA:MAX:0.5:144:730 RRA:LAST:0.5:1:288 RRA:LAST:0.5:6:336  RRA:LAST:0.5:24:372  RRA:LAST:0.5:144:730 
				fi
			fi
		fi
	done


        i=$(($i+1))
done
}





#####################################################################

case $1 in
	init)
        	echo "你真的想重新初始化所有数据文件吗？ [Yy/Nn"]
	        read YN
	        if [[ $YN == Y ]]||[[ $YN == y ]];then
	                init_crate_rrd yes
	        elif [[ $YN == N ]]||[[ $YN == n ]];then
	                init_crate_rrd no
	        fi
	;;
	save)
		get_data_save_rrd
	;;
	*)
        echo  "Usage: $0 [ init | save ]"
	;;
esac


