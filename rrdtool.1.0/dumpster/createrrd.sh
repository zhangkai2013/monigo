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




function get_data_save_rrd
{
#通过snmp 获取各个监控数据存入rrd文件

lines=`awk 'END{print NR}' $conf_dir/host_config.list`  ; i=1
while (($i<=$lines))
do
        ip=`sed -n "$i"p  $conf_dir/host_config.list | awk '{print $2}'`

        for element in $elements
        do
		
		UPDATE_STR=""	
                ## 生成系统负载项字符串
                if [[ $element == upload ]];then
			for j in 1 2 3
			do 
				VALUE_TEMP=`snmpwalk -v 1 $ip -c crhkey .1.3.6.1.4.1.2021.10.1.5.$j|awk -F: '{print $4}'|sed 's/[ ]\{1,\}//g'`
				UPDATE_STR=$UPDATE_STR":"$VALUE_TEMP
                        done
                fi


                ## 网络接口项字符串
                if [[ $element == traffic ]];then

                        # 遍历单台服务器网络接口
                        for interface in ` snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |awk '{print $4}' | grep -v lo | grep -v sit0|grep -v tun`
                        do
                            interface_index=`snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |grep $interface |cut -d '=' -f 1 |cut -d '.' -f 2`
                            for inout in ifInOctets ifOutOctets
                            do
                                curr_eth_value=`snmpwalk -v2c $ip  -c crhkey IF-MIB::${inout}.${interface_index} |cut -d ':' -f 4|tr -d ' '`
                                UPDATE_STR=$UPDATE_STR":"$curr_eth_value
                            done
                        done
                fi


                ## 磁盘项字符串
                if [[ $element == io ]];then
                
                        # 遍历单台服务器网络接口
                        for diskname in `snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::diskIODevice |grep sd |awk '{print $4}'|cut -c 1-3|uniq`
                        do
                           diskname_index=`snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::diskIODevice |grep $diskname |cut -d '=' -f 1|cut -d '.' -f 2`
                            for iorw in diskIOReads diskIOWrites diskIONRead diskIONWritten
                            do  
                                iorw_value=`snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::${iorw}.${diskname_index} |cut -d ':' -f 4|tr -d ' '`
                                UPDATE_STR=$UPDATE_STR":"$iorw_value
                            done
                        done
                fi




                ## 内存项字符串
                if [[ $element == memory ]];then
                
                        # 遍历单台服务器内存选项
                        for memory in  memTotalReal   memAvailReal   memBuffer  memCached  memTotalSwap   memAvailSwap
                        do
                                mem_value=`snmpwalk -v2c $ip -c crhkey $memory |cut -d ':' -f 4|tr -d ' '`
                                UPDATE_STR=$UPDATE_STR":"$mem_value
                        done
                fi

			
                ## 磁盘空间项字符串
                if [[ $element == partition ]];then

                        # 遍历单台服务器磁盘分区选项
                        partition_count=`snmpwalk -v2c ${ip} -c crhkey UCD-SNMP-MIB::dskPath | wc -l`
                        j=1
                        while (($j<=$partition_count))
                        do
                                dskPercent=`snmpwalk -v2c $ip -c crhkey UCD-SNMP-MIB::dskPercent.${j} |awk '{print $4}'`
                                UPDATE_STR=$UPDATE_STR":"$dskPercent
                                j=$(($j+1))
                        done
                fi



        $rrdtool updatev ${data_dir}/${element}/${ip}.${element}.rrd  N$UPDATE_STR &
	done


        #更新一级页面头部信息
        #uptime=`snmpwalk -v2c ${ip} -c ${snmp_key}  HOST-RESOURCES-MIB::hrSystemUptime | awk '{print $5 $6 $7}'|sed 's/,/  /g'`
        #sed -i  "s/<tr><td>运行时间.*/\<tr\>\<td\>运行时间：${uptime}\<\/td\>\<\/tr\>/g"  $html_dir/${ip}.html 
        #sed -i  "s/<tr><td>最后更新.*/\<tr\>\<td\>最后更新：`date +%Y-%m-%d\ %T`\<\/td\>\<\/tr\>/g"  $html_dir/${ip}.html 
                
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


