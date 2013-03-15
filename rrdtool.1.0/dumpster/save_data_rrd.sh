#!/bin/bash
# rrdtool author by zhangkai @ 2012-12-07	
# v1.0

source /var/www/rrdtool/scripts/config_develop.sh
hostConf=host_config.list

####################################################################################
function get_data_save_rrd
{ #该函数功能是获取各种监控数据保存到rrd文件里,step为匹配几分钟更新一次。
step=$1
for ip in `awk '{print $2}' $conf_dir/$hostConf`
do #进入主机列表循环，获取每台ip
	
   #echo "enter get_data_save_rrd  function:"`date +%Y%m%d\ %T`

   case $step in 
	"5") # 进入5分钟获取数据然分支
	   for element in $elements
	   do  #进入监控项循环
	       echo $element
           UPDATE_STR=;
           case $element in   
                "upload")
                 ## 生成系统负载项字符串
			function sub
			{ 
			#echo "enter $element sub function:"`date +%Y%m%d\ %T`          
                        for j in 1 2 3
                        do 
                                VALUE_TEMP=`snmpwalk -v 1 $ip -c crhkey .1.3.6.1.4.1.2021.10.1.5.$j|awk -F: '{print $4}'|sed 's/[ ]\{1,\}//g'`
                                UPDATE_STR=$UPDATE_STR":"$VALUE_TEMP
                        done
			}
                        ;;
                "traffic")
                ## 网络接口项字符串
			function sub
			{ # 遍历服务器每个网络接口
 			  # echo "enter $element sub function:"`date +%Y%m%d\ %T`    
                        for interface in ` snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |awk '{print $4}' | grep -v lo | grep -v sit0|grep -v tun`
                        do
                            interface_index=`snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |grep $interface |cut -d '=' -f 1 |cut -d '.' -f 2`
                            for inout in ifInOctets ifOutOctets
                            do
                                curr_eth_value=`snmpwalk -v2c $ip  -c crhkey IF-MIB::${inout}.${interface_index} |cut -d ':' -f 4|tr -d ' '`
                                UPDATE_STR=$UPDATE_STR":"$curr_eth_value
                            done
                        done
			} 
                        ;;
                "io")
                ## 磁盘项字符串
			function sub
			{ # 遍历服务器每块磁盘
			  #echo "enter $element sub function:"`date +%Y%m%d\ %T`    
                        for diskname in `snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::diskIODevice |grep sd |awk '{print $4}'|cut -c 1-3|uniq`
                        do
                            diskname_index=`snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::diskIODevice |grep $diskname |cut -d '=' -f 1|cut -d '.' -f 2`
                            for iorw in diskIOReads diskIOWrites diskIONRead diskIONWritten
                            do  
                                iorw_value=`snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::${iorw}.${diskname_index} |cut -d ':' -f 4|tr -d ' '`
                                UPDATE_STR=$UPDATE_STR":"$iorw_value
                            done
                        done
			}
                        ;;
                "memory")
                ## 内存项字符串
			function sub
			{ # 遍历服务器内存选项
			  #echo "enter $element sub function:"`date +%Y%m%d\ %T`    
                        for memory in  memTotalReal   memAvailReal   memBuffer  memCached  memTotalSwap   memAvailSwap
                        do
                                mem_value=`snmpwalk -v2c $ip -c crhkey $memory |cut -d ':' -f 4|tr -d ' '`
                                UPDATE_STR=$UPDATE_STR":"$mem_value
                        done
			}
                        ;;
                "partition")
                ## 磁盘空间项字符串
			function sub
			{ # 遍历服务器磁盘分区选项
			  #echo "enter $element sub function:"`date +%Y%m%d\ %T`    
                        partition_count=`snmpwalk -v2c ${ip} -c crhkey UCD-SNMP-MIB::dskPath | wc -l`
                        j=1
                        while (($j<=$partition_count))
                        do
                                dskPercent=`snmpwalk -v2c $ip -c crhkey UCD-SNMP-MIB::dskPercent.${j} |awk '{print $4}'`
                                UPDATE_STR=$UPDATE_STR":"$dskPercent
                                j=$(($j+1))
                        done
			}
                        ;;
                esac

		function rrd_update
		{	
			#echo "$ip $element ==================> "
			sub && $rrdtool updatev ${data_dir}/${element}/${ip}.${element}.rrd  N$UPDATE_STR 
		}

		rrd_update &
        done
	
	function update_html_head
	{ # 更新一级页面头部信息
	        uptime=`snmpwalk -v2c ${ip} -c ${snmp_key}  HOST-RESOURCES-MIB::hrSystemUptime | awk '{print $5 $6 $7}'|sed 's/,/  /g'`
	        sed -i  "s/<tr><td>运行时间.*/\<tr\>\<td\>运行时间：${uptime}\<\/td\>\<\/tr\>/g"  $html_dir/${ip}.html & 
	        sed -i  "s/<tr><td>最后更新.*/\<tr\>\<td\>最后更新：`date +%Y-%m-%d\ %T`\<\/td\>\<\/tr\>/g"  $html_dir/${ip}.html & 
	}
	update_html_head &		
	;;

	"1") # 进入1分钟获取数据然分支
	     for fast_element in $fast_elements
             do #进入监控项循环
	           UPDATE_STR=; 
	           case $fast_element in
	                "tcp")   
	                 ## 生成系统负载项字符串
	                        function sub
	                        {       echo "sub function:"`date +%Y%m%d\ %T`
	                        }
	                 ;;
		    esac	
	     done

	     function rrd_update
	     {	        echo "rrd_update function:"`date +%Y%m%d\ %T`
                        sub && echo "ok" 
			#$rrdtool updatev ${data_dir}/${element}/${ip}.${element}.rrd  N$UPDATE_STR
             }

	     rrd_update &
	;;
	esac
done
exit 
}

####################################################################################

get_data_save_rrd $1 
