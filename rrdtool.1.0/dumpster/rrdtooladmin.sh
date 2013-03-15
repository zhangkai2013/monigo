#!/bin/bash
# 启动，停止控制脚本
# zhangkai@cairenhui.com 20121024

if [ $# -lt 1 ] ;then
	echo  "Usage: $0 [ start|stop|restart|list ]"
	exit
fi


source config.sh
###############################################
function start_rrdtool
{

        #if [ `ps -ef |grep -v grep |grep $IPADD/disk/diskrrd.sh |wc -l` -lt 1 ];then
        #        $host_dir/$IPADD/disk/diskrrd.sh &
	#        echo "start $IPADD  diskrrd.sh  ........ ok!"; sleep 1
        #fi
        if [ `ps -ef |grep -v grep |grep $IPADD/disk/diskrrdimg.sh |wc -l` -lt 1 ];then
                $host_dir/$IPADD/disk/diskrrdimg.sh &
                echo "start $IPADD diskrrdimg.sh ........ ok!"
        fi	

}

function stop_rrdtool
{
        if [ `ps -ef |grep -v grep |grep $IPADD/disk/diskrrdimg.sh |wc -l` -eq 1 ];then
	        kill -9  `ps -ef |grep -v grep |grep $IPADD/disk/diskrrdimg.sh  |awk '{print $2}'`
	        echo "stop  $IPADD  diskrrdimg.sh  processing ......ok"
	fi
        if [ `ps -ef |grep -v grep |grep $IPADD/disk/diskrrd.sh |wc -l` -lt 1 ];then
                kill -9  `ps -ef |grep -v grep |grep $IPADD/disk/diskrrd.sh  |awk '{print $2}'`
                echo "stop  $IPADD  diskrrd.sh  processing ......ok"
        fi
}

function list_rrdtool_img
{
	ps -ef |grep $IPADD/disk/diskrrdimg.sh | grep -v grep 
}

function list_rrdtool_rrd
{
        ps -ef |grep $IPADD/disk/diskrrd.sh | grep -v grep |grep -v diskrrdimg  
}


######################################################
LINES=`awk 'END{print NR}' $conf_dir/host_config.list`
i=1
case $1  in 
	start)
             while (($i<=$LINES))
             do
             IPADD=`sed -n "$i"p  $conf_dir/host_config.list | awk '{print $2}'`
             start_rrdtool        
             i=$(($i+1))
             done
	;;
	stop)
             while (($i<=$LINES))
             do
             IPADD=`sed -n "$i"p  $conf_dir/host_config.list | awk '{print $2}'`
             stop_rrdtool        
             i=$(($i+1))
             done
	;;
	restart)
             while (($i<=$LINES))
             do
             IPADD=`sed -n "$i"p  $conf_dir/host_config.list | awk '{print $2}'`
             stop_rrdtool        
             start_rrdtool   
             i=$(($i+1))
             done
	;;
	list)
             while (($i<=$LINES))
             do
             IPADD=`sed -n "$i"p  $conf_dir/host_config.list | awk '{print $2}'`
	     list_rrdtool_img
             i=$(($i+1))
             done	    	
	     sleep 1;i=1;echo  
             while (($i<=$LINES))
             do
             IPADD=`sed -n "$i"p  $conf_dir/host_config.list | awk '{print $2}'`
             list_rrdtool_rrd
             i=$(($i+1))
             done
	;;
	*)
	echo "Usage: $0 [ start|stop|restart|list ]"
esac
