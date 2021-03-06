#!/bin/bash
base_dir="/var/www/rrdtool"
conf_dir="$base_dir/conf"
host_dir="$base_dir/hosts"
html_dir="$base_dir/html"
data_dir="$base_dir/data"
img_dir="$base_dir/images"
script_dir="$base_dir/scripts"
tool_dir="$script_dir/tools"
rrdtool="/usr/local/rrdtool/bin/rrdtool"



snmp_key="crhkey"


colors=(103667  F1AF00 F9F400  5BBD2B 205AA7 FF9912 3A2885)
#tcp_colors=(103667 F1AF00 F9F400 EC870E 367517 945305 8E1E20 006241)
tcp_colors=(103667 F1AF00  367517  BFCAE6 205AA7 EC870E F9F400 006241)
default_colors=(BFCAE6 103667  F9F400  5BBD2B 205AA7 FF9912 3A2885)
upload_colors=(205AA7 7388C1 BFCAE6)
cpu_colors=(426EB4 BFCAE6 EC870E)
traffic_colors=(BFCAE6 103667)
memory_colors=(BFCAE6 83C75D)

default_space=(10.1lf 10.2lf)
tcp_space=(11.0lf 9.0lf 6.0lf 8.0lf 7.0lf 8.0lf 8.0lf 10.0lf)
number_space=(13.0lf 13.0lf 9.0lf 6.0lf 6.0lf 6.0lf 6.0lf)
upload_space=(13.0lf 13.0lf 12.0lf)
cpu_space=(13.2lf 15.2lf 15.2lf)
traffic_space=(10.2lf 10.2lf)
iorws_space=(10.2lf 10.2lf)
iorwn_space=(10.2lf 10.2lf)
memory_space=(16.2lf 16.2lf)
partition_space=(10.0lf 14.0lf 14.0lf 14.0lf 14.0lf)


line_area=(AREA LINE)
mem_area=(AREA AREA)

lable_in_out=("in_"  "out")
lable_IO_RWS=("reads_"  "writes")
lable_IO_RWN=("readnumbers_"  "writenumbers")

#elements is some system attribute , like  traffic、disk、upload、io 
#下面的两项参数可以去掉
elements="upload traffic memory io partition"
fast_elements="tcp"


_rrdtool_format="--step 300 -w 800 -h 200 -Y -b 1000 --lower-limit 0 --font TITLE:10:FZZHYJW.ttf -c BACK#CAE5E8 "

# 初始化创建监控项-目录
for e in $elements
do
	if [ ! -e $img_dir/$e ];then
		mkdir -p $img_dir/$e
	fi
        if [ ! -e $data_dir/$e ];then
                mkdir -p $data_dir/$e
        fi
done
