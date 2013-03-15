#!/bin/bash
#
source  /var/www/rrdtool/scripts/config.sh
#

hostConf=host_config.list
#hostConf=host_config.list.temp

#######################
function snmp_set_disk
{
## 开启远端机器 snmp的磁盘信息。

lines=`awk 'END{print NR}' $conf_dir/$hostConf`  ; i=1
while (($i<=$lines))
do
	passwd=`sed -n ${i}p  $conf_dir/$hostConf  | awk '{print $1}'`
        ip=`sed -n ${i}p  $conf_dir/$hostConf | awk '{print $2}'`

	flag="false"
	for partition in `snmpwalk -v2c ${ip} -c crhkey HOST-RESOURCES-MIB::hrStorageDescr | grep / | awk '{print $4}'`
	do
	        if (( ! `snmpwalk -v2c ${ip} -c crhkey UCD-SNMP-MIB::dskPath |grep  -w  $partition |wc -l` ));then
			sleep 2
                	./expect_ssh.sh  $ip  root $passwd $partition  
	                flag="true"
        	else
	                echo "host ${ip}  Nothing to do......"
	        fi
	done

        if [[ $flag == "true" ]];then
                sleep 2
                ./expect_ssh.sh  $ip  root $passwd snmprestart 
        fi

i=$(($i+1))
done
}



function transmit_file_to_host
{
## 向远端服务器传送文件

local file=$1
lines=`awk 'END{print NR}' $conf_dir/$hostConf`  ; i=1
while (($i<=$lines))
do
        passwd=`sed -n ${i}p  $conf_dir/$hostConf  | awk '{print $1}'`
        ip=`sed -n ${i}p  $conf_dir/$hostConf | awk '{print $2}'`
       ./expect_scp.sh $file $ip $passwd 
       ./expect_set.sh  $ip  root $passwd 
       ./expect_set.sh  $ip  root $passwd snmprestart
i=$(($i+1))
done
}



###################################################


###################################################
cat <<EOF
--------------------------------------------------
|         Welcome to rrdtool init tool           |
--------------------------------------------------
|               初始化参数设置		         |  
--------------------------------------------------
| T|t : transmit tcp.sh file 到远程主机。        |
| S|s : snmp设置，开启snmp获取磁盘使用量信息。   |
| E|e : 退出设置。                               |
--------------------------------------------------
EOF

read var
case $var in
        S|s)snmp_set_disk;;
        T|t)transmit_file_to_host  $tool_dir/tcp.sh  ;;
        E|e) exit 1 ;;
        *) echo "Please enter : [ S|s  E|e ]";;
esac

