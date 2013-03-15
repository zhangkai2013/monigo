#!/bin/bash
# 初始化文件，负责初次向所有服务器发送初始化文件
source config.sh
#######################

function reset_diskrrd
{

reset_part=$1

if [[ $reset_part == "img" ]];then

        if [ `ps -ef |grep -v grep |grep $host_dir/$IPADD/disk/diskrrd.sh |wc -l` -gt 1 ];then
		kill -9  `ps -ef |grep -v grep |grep $host_dir/$IPADD/disk/diskrrdimg.sh  |awk '{print $2}'`
		echo "killed  $host_dir/$IPADD  diskrrdimg.sh ....... ok"
        fi
        if [ -e $host_dir/$IPADD/disk/diskrrdimg.sh ];then
                rm -rf  $host_dir/$IPADD/disk/diskrrdimg.sh
                echo "rm  $host_dir/$IPADD  diskrrdimg.sh........ok"
        fi
        if [ ! -e $host_dir/$IPADD/disk/diskrrdimg.sh ];then
                sed -e "s/demoip/$IPADD/g"  diskrrdimg.sh   > $host_dir/$IPADD/disk/diskrrdimg.sh
                chmod a+x $host_dir/$IPADD/disk/diskrrdimg.sh
                echo "sed  diskrrdimg.sh  to  $host_dir/$IPADD ........ok" 
        fi

fi

if [[ $reset_part == "rrd"  ]];then

        if [ `ps -ef |grep -v grep |grep $host_dir/$IPADD/disk/diskrrd.sh |wc -l` -gt 1 ];then
                kill -9  `ps -ef |grep -v grep |grep $host_dir/$IPADD/disk/diskrrdi.sh  |awk '{print $2}'`
                echo "killed  $host_dir/$IPADD  diskrrd.sh ....... ok"
        fi
        if [ -e $host_dir/$IPADD/disk/diskrrd.sh ];then
                rm -rf  $host_dir/$IPADD/disk/diskrrd.sh
                echo "rm  $host_dir/$IPADD  diskrrd.sh........ok"
        fi
        if [ ! -e $host_dir/$IPADD/disk/diskrrd.sh ];then
                sed -e "s/demoip/$IPADD/g"  diskrrd.sh   > $host_dir/$IPADD/disk/diskrrd.sh
                chmod a+x $host_dir/$IPADD/disk/diskrrd.sh
                echo "sed  diskrrd.sh  to  $host_dir/$IPADD ........ok" 
        fi
fi

}


function trans_set
{
LINES=`awk 'END{print NR}' $conf_dir/host_config.list`


i=1

while (($i<=$LINES))
do 
        PASSWD=`sed -n "$i"p $conf_dir/host_config.list | awk '{print $1}'`
        IPADD=`sed -n "$i"p  $conf_dir/host_config.list | awk '{print $2}'`

	#./expect_ssh.sh  $host_dir/$IPADD  root $PASSWD		
	#./expect_scp.sh  partition.sh  $host_dir/$IPADD  $PASSWD
		

	if [ ! -e $host_dir/$IPADD ];then
		mkdir -p  $host_dir/$IPADD/disk
		echo "mkdir $host_dir/$IPADD/disk .....ok"
	fi

	reset_diskrrd img
	#reset_diskrrd rrd

        i=$(($i+1))
done

}

trans_set

#########

