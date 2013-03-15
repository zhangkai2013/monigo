#!/bin/bash
# 该脚本批量生产图片
# zhangkai 20121026
source /var/www/rrdtool/scripts/config.sh


function graph_png
{
_start=`date -d "$(date +%Y%m%d\ %T)" +%s`

#通过snmp 获取各个监控数据存入rrd文件
lines=`awk 'END{print NR}' $conf_dir/host_config.list`  ; i=1
while (($i<=$lines))
do
        ip=`sed -n "$i"p  $conf_dir/host_config.list | awk '{print $2}'`

        for element in $elements
        do

                ## 系统负载upload 画图
                if [[ $element == upload ]];then
			DEF_STR=;LABLE_STR=;k=0
                        for j in 1 5 15
                        do 
		        DEF_STR_TEMP=DEF:value$j=${data_dir}/${element}/${ip}.${element}.rrd:upload$j:AVERAGE
		        DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                        LABLE_STR=$LABLE_STR" AREA:value$j#${upload_colors[$k]}:${j}分钟  GPRINT:value$j:LAST:%${upload_space[$k]}  COMMENT:\n" 
			k=$(($k+1))
                        done

			#画1天图
        		$rrdtool graph  ${img_dir}/${element}/${ip}.day1.png --start now-1d $_rrdtool_graph_format -t "${ip}  系统负载x100"  $DEF_STR  COMMENT:" \n"  COMMENT:"---------系统负载----------"  COMMENT:"\n" $LABLE_STR COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"  -v "默认单位："  &
			#画多天图
			for day in 7 31 365 
			do			
        		$rrdtool graph  ${img_dir}/${element}/${ip}.day${day}.png  --start now-${day}d  $_rrdtool_short_format  -t "${ip}  系统负载x100 (${day}天)" $DEF_STR  COMMENT:" \n"  COMMENT:"---------系统负载----------"  COMMENT:"\n" $LABLE_STR COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"  -v "默认单位：" &
			done
                fi


                ## 接口流量画图
                if [[ $element == traffic ]];then
                        for interface in ` snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |awk '{print $4}' | grep -v lo | grep -v sit0|grep -v tun`
                        do
                                DEF_STR=;LABLE_STR=;VDEF_STR=;CDEF_STR=;k=0
                                for inout in  in out
                                do 
                                DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:${interface}${inout}:AVERAGE
                                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                CDEF_STR_TEMP="CDEF:value${k}bits=value${k},8,*"
                                CDEF_STR=$CDEF_STR" "$CDEF_STR_TEMP
                                LABLE_STR="$LABLE_STR  ${line_area[$k]}:value${k}bits#${traffic_colors[$k]}:${lable_in_out[$k]}  GPRINT:value${k}bits:MAX:%${traffic_space[$k]}%Sbps GPRINT:value${k}bits:AVERAGE:%${traffic_space[$k]}%Sbps GPRINT:value${k}bits:LAST:%${traffic_space[$k]}%Sbps\l"
                                k=$(($k+1))
                                done


                                # 画24小时图 
                                $rrdtool graph  ${img_dir}/${element}/${ip}.${interface}.day1.png --start now-1d  $_rrdtool_graph_format -t "${ip} ${interface}  接口流量" $DEF_STR $VDEF_STR $CDEF_STR COMMENT:" \n" COMMENT:"---------------------------接口流量---------------------------"  COMMENT:"\n"  COMMENT:"            " COMMENT:"Maximum       "    COMMENT:"Average       " COMMENT:"last       \l"  $LABLE_STR COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"   -v "默认单位：bit/s"    &
                                # 画7,31,365天图
                                for days in 7 31 365
                                do
                                $rrdtool graph  ${img_dir}/${element}/${ip}.${interface}.day${days}.png  --start now-${days}d  $_rrdtool_short_format  -t "${ip} ${interface}  接口流量 (${days}天)"  $DEF_STR $VDEF_STR $CDEF_STR   COMMENT:" \n" COMMENT:"---------------------------------接口流量----------------------------------"  COMMENT:"\n"  COMMENT:"            "    COMMENT:"Maximum       "    COMMENT:"Average        " COMMENT:"last       \l"  $LABLE_STR COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"  -v "默认单位：bit/s"  &
                                done

                        done
                fi


                ## 磁盘io 画图
                if [[ $element == io ]];then
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
                                        LABLE_STR="$LABLE_STR  ${line_area[$k]}:value${k}#${default_colors[$k]}:${lable_IO_RWS[$k]} GPRINT:value$k:MAX:%${iorws_space[$k]} GPRINT:value$k:AVERAGE:%${iorws_space[$k]} GPRINT:value$k:LAST:%${iorws_space[$k]}\l"
                                        k=$(($k+1))
                                done

                                # 画图
                                $rrdtool graph  ${img_dir}/${element}/${ip}.${diskname}.rsws.day1.png --start now-1d  $_rrdtool_graph_format  -t "${ip} ${diskname}  磁盘读写次数" $DEF_STR  COMMENT:" \n" COMMENT:"--------------------磁盘每秒读写次数---(单位：次/秒)--------------------"  COMMENT:"\n"  COMMENT:"              " COMMENT:"Maximum   " COMMENT:"Average   " COMMENT:"last   \l"  $LABLE_STR COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"   -v "默认单位：次/second" &

				for day in 7 31 365
				do
                                $rrdtool graph  ${img_dir}/${element}/${ip}.${diskname}.rsws.day${day}.png --start now-${day}d  $_rrdtool_short_format  -t "${ip} ${diskname}  磁盘读写次数 (${day}天)" $DEF_STR  COMMENT:" \n" COMMENT:"--------------------磁盘每秒读写次数---(单位：次/秒)--------------------"  COMMENT:"\n"  COMMENT:"              " COMMENT:"Maximum   " COMMENT:"Average   " COMMENT:"last   \l"  $LABLE_STR COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n" -v "默认单位：次/second" &
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

                                # 画图
                                $rrdtool graph  ${img_dir}/${element}/${ip}.${diskname}.rnwn.day1.png --start now-1d   $_rrdtool_graph_format -t "${ip} ${diskname}  磁盘读写量"  $DEF_STR $CDEF_STR COMMENT:" \n" COMMENT:"----------------------------磁盘每秒读写数据量----------------------------"  COMMENT:"\n" COMMENT:"                     " COMMENT:"Maximum       " COMMENT:"Average        " COMMENT:"last       \l"  $LABLE_STR COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"   -v "默认单位：bits/s"   &
				for day in 7 31 365
				do
                                $rrdtool graph  ${img_dir}/${element}/${ip}.${diskname}.rnwn.day${day}.png --start now-${day}d   $_rrdtool_short_format -t "${ip} ${diskname}  磁盘读写量 (${day}天)"  $DEF_STR $CDEF_STR COMMENT:" \n" COMMENT:"----------------------------磁盘每秒读写数据量----------------------------"  COMMENT:"\n" COMMENT:"                     " COMMENT:"Maximum       " COMMENT:"Average        " COMMENT:"last       \l"  $LABLE_STR COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"   -v "默认单位：bits/s"   &
				done
                        done

                fi


                ## 系统memory 画图
                if [[ $element == memory ]];then
                        # 遍历memory项

			##	
			## Memory::memTotal/memAvail
			##	

                        DEF_STR=;LABLE_STR=;k=0
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
                                $rrdtool graph  ${img_dir}/${element}/${ip}.memTotalAvail.day1.png  --start now-1d $_rrdtool_graph_format -t "${ip} ${diskname} $_rrdtool_memory_title   Total/Avail"  $DEF_STR  $CDEF_STR  COMMENT:"\n" $_rrdtool_memory_comment  COMMENT:"\n"  COMMENT:"             "  COMMENT:"Current-memory   \l" $LABLE_STR  COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n" -v "默认单位：bits" & 
				for day in 7 31 365
				do
                                $rrdtool graph  ${img_dir}/${element}/${ip}.memTotalAvail.day${day}.png  --start now-${day}d $_rrdtool_short_format -t "${ip} $_rrdtool_memory_title   Total/Avail  (${day}天)" $DEF_STR   $CDEF_STR  COMMENT:"\n" $_rrdtool_memory_comment  COMMENT:"\n"  COMMENT:"              " COMMENT:"Current-swap   \l" $LABLE_STR  COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"  -v "默认单位：bits"  & 
				done


			##
			## Memeor::Cached/Buffer
		        ##
		
                        DEF_STR=;LABLE_STR=;k=0
                        for memory in   Cached  Buffer 
                        do
                                DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:mem${memory}:AVERAGE
                                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                LABLE_STR="$LABLE_STR  ${mem_area[$k]}:value${k}#${memory_colors[$k]}:${memory} GPRINT:value$k:MAX:%${memory_space[$k]}%Sb GPRINT:value$k:AVERAGE:%${memory_space[$k]}%Sb GPRINT:value$k:LAST:%${memory_space[$k]}%Sb\l"
                                k=$(($k+1))
                       done

                                # 画图
                                $rrdtool graph  ${img_dir}/${element}/${ip}.BufferCached.day1.png  --start now-1d $_rrdtool_graph_format -t "${ip}  $_rrdtool_memory_title   Buffers/Cached"  $DEF_STR  COMMENT:"\n" $_rrdtool_memory_comment  COMMENT:"\n"  COMMENT:"             " COMMENT:"Maximum    " COMMENT:"Average      " COMMENT:"last   \l" $LABLE_STR  COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"  -v "默认单位：bits" & 
				for day in 7 31 365
				do
                                $rrdtool graph  ${img_dir}/${element}/${ip}.BufferCached.day${day}.png  --start now-${day}d $_rrdtool_short_format -t "${ip} $_rrdtool_memory_title    Buffers/Cached  (${day}天)" $DEF_STR   $CDEF_STR  COMMENT:"\n" $_rrdtool_memory_comment  COMMENT:"\n"  COMMENT:"              " COMMENT:"Current-swap   \l" $LABLE_STR  COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"  -v "默认单位：bits"  & 
				done
			
			##
			## Memory::TotalSwap/AvailSwap  
			##
	
                        DEF_STR=;LABLE_STR=;k=0
                        for memory in   TotalSwap   AvailSwap 
                        do
                                DEF_STR_TEMP=DEF:value$k=${data_dir}/${element}/${ip}.${element}.rrd:mem${memory}:AVERAGE
                                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                CDEF_STR_TEMP="CDEF:swap${k}KB=value${k},1000,*"
                                CDEF_STR=$CDEF_STR" "$CDEF_STR_TEMP
                                LABLE_STR="$LABLE_STR  ${mem_area[$k]}:swap${k}KB#${memory_colors[$k]}:${memory} GPRINT:swap${k}KB:LAST:%${memory_space[$k]}%Sb\l"
                                k=$(($k+1))
                       done

                                # 画图
                                $rrdtool graph  ${img_dir}/${element}/${ip}.Swap.day1.png  --start now-1d $_rrdtool_graph_format -t "${ip} $_rrdtool_memory_title   TotalSwap/AvailSwap"  $DEF_STR   $CDEF_STR  COMMENT:"\n" $_rrdtool_memory_comment  COMMENT:"\n"  COMMENT:"              " COMMENT:"Current-swap   \l" $LABLE_STR  COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"  -v "默认单位：bits"  & 
				for day in 7 31 365
				do
                                $rrdtool graph  ${img_dir}/${element}/${ip}.Swap.day${day}.png  --start now-${day}d $_rrdtool_short_format -t "${ip} $_rrdtool_memory_title   TotalSwap/AvailSwap  (${day}天)" $DEF_STR   $CDEF_STR  COMMENT:"\n" $_rrdtool_memory_comment  COMMENT:"\n"  COMMENT:"              " COMMENT:"Current-swap   \l" $LABLE_STR  COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"  -v "默认单位：bits"  & 
				done

                fi



                ## 系统磁盘分区画图
                if [[ $element == partition ]];then
                        DEF_STR=;LABLE_STR=;j=1;k=0
                        partition_count=`snmpwalk -v2c ${ip} -c crhkey UCD-SNMP-MIB::dskPath | wc -l`
                        while (($j<=$partition_count))
                        do
                                partition_name=`snmpwalk -v2c ${ip} -c crhkey UCD-SNMP-MIB::dskPath.${j} | awk '{print $4}'`
                                DEF_STR_TEMP=DEF:value$j=${data_dir}/${element}/${ip}.${element}.rrd:partition${j}:LAST
                                DEF_STR=$DEF_STR" "$DEF_STR_TEMP
                                LABLE_STR=$LABLE_STR" LINE3:value$j#${default_colors[$k]}:${partition_name} GPRINT:value$j:LAST:%${partition_space[$k]} COMMENT:%\n"
                               j=$(($j+1))
                               k=$(($k+1))
                        done

			#画图
                        $rrdtool graph  ${img_dir}/${element}/${ip}.day1.png  --start now-1d  $_rrdtool_graph_format -t "${ip} $_rrdtool_partition_title"   $DEF_STR  COMMENT:" \n"  $_rrdtool_partition_comment  COMMENT:"\n"   COMMENT:"              " COMMENT:"Current   \l"   $LABLE_STR COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"   -v "默认单位：百分比"  &
			#
			for day in 7 31 365 
			do
                        $rrdtool graph  ${img_dir}/${element}/${ip}.day${day}.png  --start now-${day}d  $_rrdtool_short_format -t "${ip} $_rrdtool_partition_title  (${day}天)" $DEF_STR  COMMENT:" \n"  $_rrdtool_partition_comment  COMMENT:"\n"   COMMENT:"              " COMMENT:"Current   \l"   $LABLE_STR COMMENT:"最后更新 \:$(date '+%Y-%m-%d %H\:%M')\n"   -v "默认单位：百分比"  &
			done

                fi




        done
        i=$(($i+1))
done
_end=`date -d "$(date +%Y%m%d\ %T)" +%s`
echo "处理完毕！耗时" $(($_end-$_start)) "秒"
}

graph_png
