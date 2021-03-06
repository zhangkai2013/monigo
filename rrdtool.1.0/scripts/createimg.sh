#!/bin/bash
# 该脚本批量生产图片
# zhangkai 20121026
source /var/www/rrdtool/scripts/config.sh
hostConf="host_config.list.test"


function Graph_day_week_month_year_Png
{
## 该函数的功能是将传递进的参数进行拼凑，再画天、周、月、年图。
## var 为传递进来的天数，class 为各个项目

var=$1;class=$2

## 图表标题字符串
title_io_rws="${ip} ${diskname} 磁盘读写次数 ($var)"
title_io_rwn="${ip} ${diskname} 磁盘读写量 ($var)"
title_tcp="${ip} TCP 连接状态 ($var)"
title_cpu="${ip} CPU-Usage ($var)"
title_upload="${ip} 系统负载x100 ($var)"
title_traffic="${ip} 接口流量 ${interface} ($var)"
title_partition="${ip} 磁盘分区 ($var)"
title_swap_total="${ip} 系统内存 Swap[Total/Avail] ($var)"
title_memo_total="${ip} 系统内存 Memory[Total/Avail] ($var)"
title_cache_buffer="${ip} 系统内存 Cached/Buffers ($var)"
TITLE=$(eval echo  \$title_$class)

## 默认单位类型
unit_io_rws="默认单位：次/秒"
unit_io_rwn="默认单位：bits"
unit_tcp="默认单位：状态连接数"
unit_cpu="默认单位：%"
unit_upload="默认单位：     "
unit_traffic="默认单位：bit/s"
unit_partition="默认单位：%" 
unit_swap_total="默认单位：bits"
unit_memo_total="默认单位：bits"
unit_cache_buffer="默认单位：bits"
UNIT=$(eval echo \$unit_$class)

## 图标x轴横栏标题
comment_io_rws="COMMENT:磁盘读写次数-------Maximum---------Average----------Current"
comment_io_rwn="COMMENT:磁盘读写量---------------Maximum---------Average----------Current"
comment_tcp="COMMENT:TCP状态----------Maximum---------Average----------Current"
comment_cpu="COMMENT:CPU-Usage---------Maximum----------Average----------Current"
comment_upload="COMMENT:系统负载----------Current"
comment_traffic="COMMENT:接口流量-------Maximum----------Average---------Current"
comment_partition="COMMENT:磁盘分区----------Current"
comment_swap_total="COMMENT:Swap统计--------------Current-swap"
comment_memo_total="COMMENT:Memory统计----------Current-memory"
comment_cache_buffer="COMMENT:CacheBuffers统计------Maximum-------------Average--------------Current"
COMMENT=$(eval echo  \$comment_$class)

## 定义图片名称
png_io_rws="${ip}.${diskname}.rws.${var}.png"
png_io_rwn="${ip}.${diskname}.rwn.${var}.png"
png_tcp="${ip}.${var}.png"
png_cpu="${ip}.${var}.png"
png_upload="${ip}.${var}.png"
png_traffic="${ip}.${interface}.${var}.png"
png_partition="${ip}.${var}.png"
png_swap_total="${ip}.Swap.${var}.png"
png_memo_total="${ip}.memTotalAvail.${var}.png"
png_cache_buffer="${ip}.BufferCached.${var}.png"
PNG_NAME=$(eval echo  \$png_$class)


#trap   DEBUG

case $var in
	"day") 
$rrdtool graph ${img_dir}/${element}/${PNG_NAME} --start now-1d $_rrdtool_format --x-grid MINUTE:30:HOUR:1:HOUR:1:0:%H -t "$TITLE" $DEF_STR $CDEF_STR COMMENT:" \n" $COMMENT COMMENT:"\n" COMMENT:" \n" $LABLE_STR COMMENT:" \n" COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n" -v $UNIT &
;;
	"week")
$rrdtool graph ${img_dir}/${element}/${PNG_NAME} --start now-7d $_rrdtool_format --x-grid HOUR:3:HOUR:24:HOUR:24:0:%a  -t "$TITLE" $DEF_STR $CDEF_STR COMMENT:" \n" $COMMENT COMMENT:"\n" COMMENT:" \n" $LABLE_STR COMMENT:" \n" COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"  -v $UNIT &
;;
	"month")
$rrdtool graph ${img_dir}/${element}/${PNG_NAME} --start now-31d $_rrdtool_format --x-grid DAY:1:DAY:1:DAY:1:0:%d  -t "$TITLE" $DEF_STR $CDEF_STR  COMMENT:" \n" $COMMENT COMMENT:"\n" COMMENT:" \n"  $LABLE_STR COMMENT:" \n" COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"  -v $UNIT  &
;;
	"year")
$rrdtool graph ${img_dir}/${element}/${PNG_NAME} --start now-365d $_rrdtool_format --x-grid MONTH:1:MONTH:1:MONTH:1:0:%b -t "$TITLE" $DEF_STR $CDEF_STR COMMENT:" \n" $COMMENT COMMENT:"\n" COMMENT:" \n" $LABLE_STR COMMENT:" \n" COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"  -v $UNIT &
;;
	*) exit 0 ;;
esac

}



function graph_png
{
## 记录程序执行的起始时间
_start=`date -d "$(date +%Y%m%d\ %T)" +%s`

for ip in `awk -F:: '{print $2}' $conf_dir/$hostConf`
do
        for element in ` grep -w $ip $conf_dir/$hostConf | awk -F:: '{print $3}'| sed 's/:/\ /g'`
        do
		function sub { export DEF_STR=;LABLE_STR=;} ; sub
		case $element in 
		"upload")
	        ## 系统负载upload 画图
			function sub
			{
			DEF_STR=;LABLE_STR=;k=0
                        for j in 1 5 15
                        do 
		        DEF_STR_TEMP=DEF:value$j=${data_dir}/${element}/${ip}.${element}.rrd:upload$j:AVERAGE
		        DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                        LABLE_STR=$LABLE_STR" AREA:value$j#${upload_colors[$k]}:${j}分钟  GPRINT:value$j:LAST:%${upload_space[$k]}  COMMENT:\n" 
			k=$(($k+1))
                        done

			#画图
		        for days in day week month year
			do			
			Graph_day_week_month_year_Png  $days $element
			done
			}
			;;	
		"traffic")
                ## 接口流量画图
			function sub
			{
                        for interface in ` snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |awk '{print $4}' | grep -v lo | grep -v sit0|grep -v tun`
                        do
                                DEF_STR=;LABLE_STR=;CDEF_STR=;k=0
                                for inout in  in out
                                do 
                                DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:${interface}${inout}:AVERAGE
                                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                CDEF_STR_TEMP="CDEF:value${k}bits=value${k},8,*"
                                CDEF_STR=$CDEF_STR" "$CDEF_STR_TEMP
                                LABLE_STR="$LABLE_STR  ${line_area[$k]}:value${k}bits#${traffic_colors[$k]}:${lable_in_out[$k]}  GPRINT:value${k}bits:MAX:%${traffic_space[$k]}%Sbps GPRINT:value${k}bits:AVERAGE:%${traffic_space[$k]}%Sbps GPRINT:value${k}bits:LAST:%${traffic_space[$k]}%Sbps\l"
                                k=$(($k+1))
                                done

	                        #画图
        	                for days in day week month year
                	        do
                                Graph_day_week_month_year_Png  $days $element
	                        done
                        done
                	}
			;;
		"io")
                ## 磁盘io 画图
			function sub
			{
                        # 遍历每个磁盘的io
                        for diskname in `snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::diskIODevice |grep sd |awk '{print $4}'|cut -c 1-3|uniq`
                        do
                                ## 拼接磁盘io的读写次数
				## Disk-IO::reads/writes 
	  		        ##
                                DEF_STR=;LABLE_STR=;k=0
                                for iorw in  reads writes 
                                do
                                DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:${diskname}${iorw}:AVERAGE
                                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                LABLE_STR="$LABLE_STR  ${line_area[$k]}:value${k}#${default_colors[$k]}:${lable_IO_RWS[$k]} GPRINT:value$k:MAX:%${iorws_space[$k]}次/秒 GPRINT:value$k:AVERAGE:%${iorws_space[$k]}次/秒 GPRINT:value$k:LAST:%${iorws_space[$k]}次/秒\l"
                                k=$(($k+1))
                                done

                                #画图
                                for days in day week month year
                                do
                                Graph_day_week_month_year_Png  $days io_rws
                                done

                                ## 拼接磁盘io的读写字符数
				## Disk-IO::readNumbers/writeNumbers
				##
                                DEF_STR=;LABLE_STR=;CDEF_STR=;k=0
                                for iorw in  readNumbers writeNumbers
                                do
                                        DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:${diskname}${iorw}:AVERAGE
                                        DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                        CDEF_STR_TEMP="CDEF:value${k}bits=value${k},8,*"
                                        CDEF_STR=$CDEF_STR" "$CDEF_STR_TEMP
                                        LABLE_STR="$LABLE_STR  ${line_area[$k]}:value${k}bits#${default_colors[$k]}:${lable_IO_RWN[$k]}  GPRINT:value${k}bits:MAX:%${iorwn_space[$k]}%Sbps  GPRINT:value${k}bits:AVERAGE:%${iorwn_space[$k]}%Sbps  GPRINT:value${k}bits:LAST:%${iorwn_space[$k]}%Sbps\l"
                                        k=$(($k+1))
                                done
                                ## 画图
                                for days in day week month year
                                do
                                Graph_day_week_month_year_Png  $days io_rwn
                                done

                        done
			}
			;;
		"memory")
                ## 系统memory 画图
			function sub
			{
			##
			## Memory::memTotal/memAvail
			##	
                        DEF_STR=;LABLE_STR=;CDEF_STR=;k=0
                        for memory in  memTotal   memAvail 
                        do
                                DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:${memory}Real:AVERAGE
                                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                CDEF_STR_TEMP="CDEF:value${k}KB=value${k},1000,*"
                                CDEF_STR=$CDEF_STR" "$CDEF_STR_TEMP
                                LABLE_STR="$LABLE_STR  ${mem_area[$k]}:value${k}KB#${memory_colors[$k]}:${memory} GPRINT:value${k}KB:LAST:%${memory_space[$k]}%Sb\l"
                                k=$(($k+1))
                       done
                       # 画图
                       for days in day week month year
                       do
                       Graph_day_week_month_year_Png  $days memo_total
                       done


			##
			## Memeor::Cached/Buffer
		        ##
			DEF_STR=;LABLE_STR=;CDEF_STR=;k=0
                        for memory in   Cached  Buffer 
                        do
                                DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:mem${memory}:AVERAGE
                                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                LABLE_STR="$LABLE_STR  ${mem_area[$k]}:value${k}#${memory_colors[$k]}:${memory} GPRINT:value$k:MAX:%${memory_space[$k]}%Sb GPRINT:value$k:AVERAGE:%${memory_space[$k]}%Sb GPRINT:value$k:LAST:%${memory_space[$k]}%Sb\l"
                                k=$(($k+1))
                        done
                        ## 画图
                        for days in day week month year
                        do
                                Graph_day_week_month_year_Png  $days cache_buffer
                        done


			##
			## Memory::TotalSwap/AvailSwap  
			##
			DEF_STR=;LABLE_STR=;CDEF_STR=;k=0	
                        for memory in   TotalSwap   AvailSwap 
                        do
                                DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:mem${memory}:AVERAGE
                                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                CDEF_STR_TEMP="CDEF:swap${k}KB=value${k},1000,*"
                                CDEF_STR=$CDEF_STR" "$CDEF_STR_TEMP
                                LABLE_STR="$LABLE_STR  ${mem_area[$k]}:swap${k}KB#${memory_colors[$k]}:${memory} GPRINT:swap${k}KB:LAST:%${memory_space[$k]}%Sb\l"
                                k=$(($k+1))
                       done

                       ## 画图
                       for days in day week month year
                       do
                       Graph_day_week_month_year_Png  $days swap_total
                       done

		       }
		       ;;
		"partition")
                ## 系统磁盘分区画图
			function sub
			{
                        DEF_STR=;LABLE_STR=;CDEF_STR=;j=1;k=0
                        partition_count=`snmpwalk -v2c ${ip} -c crhkey UCD-SNMP-MIB::dskPath | wc -l`
                        while (($j<=$partition_count))
                        do
                        partition_name=`snmpwalk -v2c ${ip} -c crhkey UCD-SNMP-MIB::dskPath.${j} | awk '{print $4}'`
                        DEF_STR_TEMP=DEF:value$j=${data_dir}/${element}/${ip}.${element}.rrd:partition${j}:LAST
                        DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                        LABLE_STR=$LABLE_STR" LINE3:value$j#${default_colors[$k]}:${partition_name} GPRINT:value$j:LAST:%${partition_space[$k]}%% COMMENT:\n"
                        j=$(($j+1))
                        k=$(($k+1))
                        done

                        ## 画图
                        for days in day week month year
                        #for days in day
                        do
                                Graph_day_week_month_year_Png  $days $element
                        done
			}
			;;
                "cpu")
                ## 系统磁盘分区画图
                        function sub
                        {
                        DEF_STR=;LABLE_STR=;CDEF_STR=;k=0
			for cpu in System User Wait
			do
	                        DEF_STR_TEMP=DEF:value$cpu=${data_dir}/${element}/${ip}.${element}.rrd:$cpu:LAST
	                        DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                CDEF_STR_TEMP="CDEF:value${cpu}per=value${cpu},10,/"
                                CDEF_STR=$CDEF_STR" "$CDEF_STR_TEMP
                                LABLE_STR=$LABLE_STR" AREA:value${cpu}per#${cpu_colors[$k]}:${cpu} GPRINT:value${cpu}per:MAX:%${cpu_space[$k]}%% GPRINT:value${cpu}per:AVERAGE:%14.2lf%% GPRINT:value${cpu}per:LAST:%14.2lf%%\l"
                                #LABLE_STR=$LABLE_STR" AREA:value${cpu}#${cpu_colors[$k]}:${cpu} GPRINT:value${cpu}:MAX:%${cpu_space[$k]}%% GPRINT:value${cpu}:AVERAGE:%14.2lf%% GPRINT:value${cpu}:LAST:%14.2lf%%\l"
	                        k=$(($k+1))
                        done

                        ## 画图
                        for days in day week month year
                        #for days in day
                        do
                                Graph_day_week_month_year_Png  $days $element
                        done
                        }
                        ;;
		esac

		###  Go graphing .........
		sub &
        done

        for element in `grep -w $ip $conf_dir/$hostConf | awk -F:: '{print $4}'| sed 's/:/\ /g'`
        do
           #echo "$ip:fast element ======>"$element
           function sub { DEF_STR=;LABLE_STR=;}
                case $element in
		"tcp")
		## tcp 连接状态画图
			function sub
			{
			 DEF_STR=;LABLE_STR=;CDEF_STR=;k=0
			 for tcpi in  LISTEN SYN_RECV ESTABLISHED TIME_WAIT CLOSE_WAIT FIN_WAIT1 FIN_WAIT2 CLOSING
			 do
                         	DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:${tcpi}:AVERAGE	
				DEF_STR=$DEF_STR" "$DEF_STR_TEMP
      				LABLE_STR=$LABLE_STR" AREA:value${k}#${tcp_colors[$k]}:${tcpi} GPRINT:value$k:MAX:%${tcp_space[$k]} GPRINT:value$k:AVERAGE:%14.0lf GPRINT:value$k:LAST:%14.0lf\l"
				k=$(($k+1))
			 done

                         #画图
                         for days in day week month year
                         do
                                Graph_day_week_month_year_Png  $days $element
                         done
			}
			;;
                "traffic")
                ## 接口流量画图
                        function sub
                        {
                        for interface in ` snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |awk '{print $4}' | grep -v lo | grep -v sit0|grep -v tun`
                        do
                                DEF_STR=;LABLE_STR=;CDEF_STR=;k=0
                                for inout in  in out
                                do 
                                DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:${interface}${inout}:AVERAGE
                                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                CDEF_STR_TEMP="CDEF:value${k}bits=value${k},8,*"
                                CDEF_STR=$CDEF_STR" "$CDEF_STR_TEMP
                                LABLE_STR="$LABLE_STR  ${line_area[$k]}:value${k}bits#${traffic_colors[$k]}:${lable_in_out[$k]}  GPRINT:value${k}bits:MAX:%${traffic_space[$k]}%Sbps GPRINT:value${k}bits:AVERAGE:%${traffic_space[$k]}%Sbps GPRINT:value${k}bits:LAST:%${traffic_space[$k]}%Sbps\l"
                                k=$(($k+1))
                                done

                                #画图
                                for days in day week month year
                                do
                                Graph_day_week_month_year_Png  $days $element
                                done
                        done
                        }
	                ;;
                "io")
                ## 磁盘io 画图
                        function sub
                        {
                        # 遍历每个磁盘的io
                        for diskname in `snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::diskIODevice |grep sd |awk '{print $4}'|cut -c 1-3|uniq`
                        do
                                ## 拼接磁盘io的读写次数
                                ## Disk-IO::reads/writes 
                                ##
                                DEF_STR=;LABLE_STR=;k=0
                                for iorw in  reads writes 
                                do
                                DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:${diskname}${iorw}:AVERAGE
                                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                LABLE_STR="$LABLE_STR  ${line_area[$k]}:value${k}#${default_colors[$k]}:${lable_IO_RWS[$k]} GPRINT:value$k:MAX:%${iorws_space[$k]}次/秒 GPRINT:value$k:AVERAGE:%${iorws_space[$k]}次/秒 GPRINT:value$k:LAST:%${iorws_space[$k]}次/秒\l"
                                k=$(($k+1))
                                done

                                #画图
                                for days in day week month year
                                do
                                Graph_day_week_month_year_Png  $days io_rws
                                done

                                ## 拼接磁盘io的读写字符数
                                ## Disk-IO::readNumbers/writeNumbers
                                ##
                                DEF_STR=;LABLE_STR=;CDEF_STR=;k=0
                                for iorw in  readNumbers writeNumbers
                                do
                                        DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:${diskname}${iorw}:AVERAGE
                                        DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                        CDEF_STR_TEMP="CDEF:value${k}bits=value${k},8,*"
                                        CDEF_STR=$CDEF_STR" "$CDEF_STR_TEMP
                                        LABLE_STR="$LABLE_STR  ${line_area[$k]}:value${k}bits#${default_colors[$k]}:${lable_IO_RWN[$k]}  GPRINT:value${k}bits:MAX:%${iorwn_space[$k]}%Sbps  GPRINT:value${k}bits:AVERAGE:%${iorwn_space[$k]}%Sbps  GPRINT:value${k}bits:LAST:%${iorwn_space[$k]}%Sbps\l"
                                        k=$(($k+1))
                                done
                                ## 画图
                                for days in day week month year
                                do
                                Graph_day_week_month_year_Png  $days io_rwn
                                done
                        done
                        }
		        ;;
	  esac
		
          ###  Go graphing .........
          sub &

	done

done

_end=`date -d "$(date +%Y%m%d\ %T)" +%s`
echo "处理完毕！耗时" $(($_end-$_start)) "秒"
}

##---------------------------------------------
graph_png
##---------------------------------------------
