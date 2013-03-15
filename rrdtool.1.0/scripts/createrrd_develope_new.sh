#!/bin/bash
source /var/www/rrdtool/scripts/config_develop.sh
hostConf="host_config.list.test"

####################################################################################
function init_crate_rrd
{
## 从配置文件列表中读取主机列表，初始化生成每台机器各个监控项的 rrd文件
## 注意：如果已经存在老的rrd文件，则会生成新的rrd文件覆盖老的rrd,老的rrd文件数据会丢失
initrrd=$1

for ip in `awk -F:: '{print $2}' $conf_dir/$hostConf`
do #进入主机列表循环，获取每台ip
	
		
        function set_step
        {	## 根据每次获取数据的间隔时间，设置RRA文件的样式
		case $step in
                        "60")
                                RRA_D="0.5:1:1440"
                                RRA_W="0.5:60:168"
                                RRA_M="0.5:360:124"
                                RRA_Y="0.5:720:1448"
                          ;;
                         "300")
                                RRA_D="0.5:1:288"
                                RRA_W="0.5:6:336"
                                RRA_M="0.5:24:372"
                                RRA_Y="0.5:144:730"
                          ;;
                   esac
        }
	

	function add_create_rrd_string
	{	## 完整的字符串执行创建rrd文件
		case $initrrd in 
                        "init")
                          #$rrdtool create ${data_dir}/${element}/${ip}.${element}.rrd --step $step  $DS_STR RRA:AVERAGE:$RRA_D RRA:AVERAGE:$RRA_W RRA:AVERAGE:$RRA_M RRA:AVERAGE:$RRA_Y RRA:MIN:$RRA_D RRA:MIN:$RRA_W RRA:MIN:$RRA_M RRA:MIN:$RRA_Y RRA:MAX:$RRA_D RRA:MAX:$RRA_W RRA:MAX:$RRA_M RRA:MAX:$RRA_Y RRA:LAST:$RRA_D RRA:LAST:$RRA_W RRA:LAST:$RRA_M RRA:LAST:$RRA_Y
                         echo "${ip}:${element}.rrd:     $initrrd ok"
                         ;;

                         "repair")
                           if [ ! -e ${data_dir}/${element}/${ip}.${element}.rrd ];then
                           $rrdtool create ${data_dir}/${element}/${ip}.${element}.rrd --step $step  $DS_STR RRA:AVERAGE:$RRA_D RRA:AVERAGE:$RRA_W RRA:AVERAGE:$RRA_M RRA:AVERAGE:$RRA_Y RRA:MIN:$RRA_D RRA:MIN:$RRA_W RRA:MIN:$RRA_M RRA:MIN:$RRA_Y RRA:MAX:$RRA_D RRA:MAX:$RRA_W RRA:MAX:$RRA_M RRA:MAX:$RRA_Y RRA:LAST:$RRA_D RRA:LAST:$RRA_W RRA:LAST:$RRA_M RRA:LAST:$RRA_Y
                            echo "${ip}:${element}.rrd:     $initrrd ok"
                            fi
                            ;;
		esac
	}


        function do_create_rrd
        {	## 进入最终入口执行
		#echo $1
                set_step
                sub
                add_create_rrd_string
        }

	
	for element in ` grep -w $ip $conf_dir/$hostConf | awk -F:: '{print $3}'| sed 's/:/\ /g'`
	do
	   function sub { DS_STR=; }; step=300
	   #echo "$ip:normal element ======>"$element
	   case $element in 
		"partition") 
		## 生成磁盘分区项的字符串	
			function sub
			{
			partition_count=`snmpwalk -v2c ${ip} -c crhkey UCD-SNMP-MIB::dskPath | wc -l`
                        j=1
                        while (($j<=$partition_count))
                        do
                               DS_STR_TEMP=DS:partition$j:GAUGE:600:0:100
                               DS_STR=$DS_STR" "$DS_STR_TEMP
                               j=$(($j+1))
		        done
			}
			;;
		"traffic")
		## 生成网口流量项字符串
			function sub
			{
			for interface in `snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |awk '{print $4}'|grep -v lo|grep -v sit0|grep -v tun`
                        do
				for inout in in out
	                        do
        	                        DS_STR_TEMP=DS:${interface}${inout}:COUNTER:600:0:U
                	                DS_STR=$DS_STR" "$DS_STR_TEMP
                        	done
			done
			}
			;;
		"io")
                ## 生成系统io读写项字符串
			function sub
			{
			for diskname in `snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::diskIODevice |grep sd |awk '{print $4}'|cut -c 1-3|uniq`
			do
	                        for iorw in  reads writes readNumbers writeNumbers
        	                do
                                DS_STR_TEMP=DS:${diskname}${iorw}:COUNTER:600:0:U
                                DS_STR=$DS_STR" "$DS_STR_TEMP
                	        done
			done
			}
			;;
		"upload")
                ## 生成系统负载项字符串
			function sub
			{
			for minute in 1 5 15
			do 
                                DS_STR_TEMP=DS:upload$minute:GAUGE:600:0:U
                                DS_STR=$DS_STR" "$DS_STR_TEMP
                        done
			}
			;;
		"memory")
                ## 生成系统内存项字符串
			function sub
			{
                        for memory in  memTotalReal   memAvailReal   memBuffer  memCached  memTotalSwap   memAvailSwap
                        do
                                DS_STR_TEMP=DS:$memory:GAUGE:600:0:U
                                DS_STR=$DS_STR" "$DS_STR_TEMP
                        done
			}
			;;
                "tcp")
                ## 生成系统tcp连接状态字符串
                        function sub
                        {
                        for tcp in  LISTEN SYN_RECV ESTABLISHED TIME_WAIT CLOSE_WAIT FIN_WAIT1 FIN_WAIT2 CLOSING
                        do
                                DS_STR_TEMP=DS:$tcp:GAUGE:600:0:U
                                DS_STR=$DS_STR" "$DS_STR_TEMP
                        done
                        #step=60
                        }
                        ;;
		"cpu")
		## 生成cpu使用率字符串
			function sub
			{
			for cpu in User System Wait
			do
				DS_STR_TEMP=DS:$cpu:COUNTER:600:0:U
                                DS_STR=$DS_STR" "$DS_STR_TEMP
			done
			}
			;;
	   esac


	   ## Go doing create rrd ...........      
	   do_create_rrd  "do======>normal $element" &
	done
		



        for element in `grep -w $ip $conf_dir/$hostConf | awk -F:: '{print $4}'| sed 's/:/\ /g'`
        do
           function sub { DS_STR=; }; step=60
	   #echo "$ip:fast element ======>"$element
           case $element in                
		"tcp")
                ## 生成系统tcp连接状态字符串
                        function sub
                        {
                        for tcp in  LISTEN SYN_RECV ESTABLISHED TIME_WAIT CLOSE_WAIT FIN_WAIT1 FIN_WAIT2 CLOSING
                        do
                                DS_STR_TEMP=DS:$tcp:GAUGE:600:0:U
                                DS_STR=$DS_STR" "$DS_STR_TEMP
                        done
                        }
                        ;;
                "traffic")
                ## 生成网口流量项字符串
                        function sub
                        {
                        for interface in `snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |awk '{print $4}'|grep -v lo|grep -v sit0|grep -v tun`
                        do
                                for inout in in out
                                do
                                        DS_STR_TEMP=DS:${interface}${inout}:COUNTER:600:0:U
                                        DS_STR=$DS_STR" "$DS_STR_TEMP
                                done
                        done
                        }
                        ;;
                "io")
                ## 生成系统io读写项字符串
                        function sub
                        {
                        for diskname in `snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::diskIODevice |grep sd |awk '{print $4}'|cut -c 1-3|uniq`
                        do
                                for iorw in  reads writes readNumbers writeNumbers
                                do
                                DS_STR_TEMP=DS:${diskname}${iorw}:COUNTER:600:0:U
                                DS_STR=$DS_STR" "$DS_STR_TEMP
                                done
                        done
                        }
                        ;;
                "upload")
                ## 生成系统负载项字符串
                        function sub
                        {
                        for minute in 1 5 15
                        do 
                                DS_STR_TEMP=DS:upload$minute:GAUGE:600:0:U
                                DS_STR=$DS_STR" "$DS_STR_TEMP
                        done
                        }
                        ;;
                "cpu")
                ## 生成cpu使用率字符串
                        function sub
                        {
                        for cpu in User System Wait
                        do
                                DS_STR_TEMP=DS:$cpu:COUNTER:600:0:U
                                DS_STR=$DS_STR" "$DS_STR_TEMP
                        done
                        }
                        ;;
           esac

	   ## Go doing create rrd ...........      
           do_create_rrd  "fast===================================> $element" &
	done


done
}





#####################################################################

case $1 in
	"init")
         echo  "你真的想重新初始化所有数据文件吗？ [Yy/Nn]"
	       read YN
	       if [[ $YN == Y ]]||[[ $YN == y ]];then
			    init_crate_rrd init
	       fi
	 ;;
	"repair")init_crate_rrd repair ;;
	*) echo  "Usage: $0 [ init | repair ]" ;;
esac

#####################################################################
