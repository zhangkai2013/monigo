#!/bin/bash
#
source  /var/www/rrdtool/scripts/config.sh
hostConf="host_config.list.test"
######################


function init_all_host_htmls_dir
{
# 创建htmls目录
for ip in `awk -F:: '{print $2}' $conf_dir/$hostConf`
do		
	echo "pre create $ip"
	if [ ! -d $html_dir/${ip}.htmls ] ;then
		mkdir $html_dir/${ip}.htmls
        	echo "dir ${ip}.htmls created  ok..."
	fi
done
}



function add_host
{
is_add="false"
n=`awk '/主机/{print NR}' $html_dir/lf.html `
while (($i<=$lines))
        do 
        ip=`sed -n "$i"p $conf_dir/$hostConf | awk '{print $2}'`
	sed -i "/$ip.html/d" $html_dir/lf.html 
        sed  -i  "${n}a\ \ \ \ \ \ <dd><a href='$ip.html'>$ip</a></dd>"  $html_dir/lf.html
	echo "${ip} add ok..."; is_add="true"
	#sed "s/demo/$ip/g"  $html_dir/demo.html  > $html_dir/$ip.html	 		 
	i=$(($i+1))
	n=$(($n+1))
done
if [ $is_add != "true" ];then
	echo  "Nothing  host  add ......."
fi
}

#add_host




##-------------------------------------------- 一级页面 
function create_host_html
{
## 批量生成主机的一级页面

_start=`date -d "$(date +%Y%m%d\ %T)" +%s`
_htmls=0

for ip in `awk -F:: '{print $2}' $conf_dir/$hostConf`
do #进入主机列表循环，获取每台ip

>$html_dir/${ip}.html 
cat >> $html_dir/${ip}.html <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<style type='text/css'>
a img { padding: 0; border: none; }
table{width:882px;border:2px solid #ccc;border-width:2px;background:#CAE5E8;}
table td {width:50%;height:10px;text-align:left;font-size:12px;}
#ttl {height:60px;text-align:center;vertical-align:bottom;font-size:30px;}
#TL {width:882px;height:35px;background:#94AAD6;text-align:left;font-size:32px;}
</style>
</head>
<meta http-equiv="refresh" content="300" />
<body>
<center>
EOF
echo "
<table>
<tr><td id='ttl'>Svr-${ip}服务器监控资源</td></tr>
<tr><td>主机名：`snmpwalk -v2c ${ip} -c ${snmp_key}  SNMPv2-MIB::sysName  | awk '{print $4}'`</td><tr>
<tr><td>系统类型：`snmpwalk -v2c ${ip} -c ${snmp_key}  SNMPv2-MIB::sysDescr | awk '{print  $4,$6}'`</td></tr>
<tr><td>运行时间：`snmpwalk -v2c ${ip} -c ${snmp_key}  HOST-RESOURCES-MIB::hrSystemUptime | awk '{print $5 $6 $7}'|sed 's/,/  /g'`</td></tr>
<tr><td>最后更新：`date +%Y-%m-%d\ %T `</td></tr>
</table><p><p>" >> $html_dir/${ip}.html  

 
## 循环添加各个监控项到主机静态页面中
## 5分钟获取数据项
for element in ` grep -w $ip $conf_dir/$hostConf | awk -F:: '{print $3}'| sed 's/:/\ /g'`
do
     
     ## 系统负载
     if [[ $element == upload ]];then
     echo "<div id='TL'>System-Upload</div><p>" >> $html_dir/${ip}.html 
     echo "<a href='${ip}.htmls/${ip}.${element}.html'><img src='../images/$element/${ip}.day.png' alt='系统负载' /></a><p>">>$html_dir/${ip}.html 
     echo "$ip:${element}:ok"; _htmls=$(($_htmls+1))	
     fi
     
     
     ## 接口流量
     if [[ $element == traffic ]];then
     	     echo "<div id='TL'>System-Traffic</div><p>" >>  $html_dir/${ip}.html &
             for interface in `snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |awk '{print $4}' | grep -v lo | grep -v sit0|grep -v tun`
             do
             echo  "<a href='${ip}.htmls/${ip}.${interface}.html'><img src='../images/${element}/${ip}.${interface}.day.png'  alt='接口流量' /></a><p> " >>  $html_dir/${ip}.html &
     	     echo "$ip:${interface}:ok"; _htmls=$(($_htmls+1))
             done
     fi
     
     
     
     ## 磁盘io 画图
     if [[ $element == io ]];then
     	     echo "<div id='TL'>System-Disk-IO</div><p>"  >> $html_dir/${ip}.html  &         
             for diskname in `snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::diskIODevice |grep sd |awk '{print $4}'|cut -c 1-3|uniq`
             do
             	for iorw in  rws rwn
                     do
			   echo "<a href='${ip}.htmls/${ip}.${diskname}.${iorw}.html'><img src='../images/${element}/${ip}.${diskname}.${iorw}.day.png' alt='diskIO' /></a><p>" >> $html_dir/${ip}.html &
                           echo "$ip:${diskname}.${iorw}:ok"; _htmls=$(($_htmls+1))
                     done
             done
     fi
		
     
     
     
     ## memory
     if [[ $element == memory ]];then
	     echo "<div id='TL'>System-Memory</div><p>"  >>  $html_dir/${ip}.html 
             for memory in   memTotalAvail  BufferCached  Swap
             do
     	        echo "<a href='${ip}.htmls/${ip}.${memory}.html'><img src='../images/${element}/${ip}.${memory}.day.png' alt='memory' /></a><p>">> $html_dir/${ip}.html 
                echo "$ip:${memory}:ok"; _htmls=$(($_htmls+1))
             done
     fi
     
     
     ## disk partition
     if [[ $element == partition ]];then
             echo "<div id='TL'>System-Disk-Partiton</div><p>"  >>  $html_dir/${ip}.html 
             echo "<a href='${ip}.htmls/${ip}.${element}.html'><img src='../images/${element}/${ip}.day.png' alt='partition' /></a><p>">> $html_dir/${ip}.html 
             echo "$ip:${element}:ok"; _htmls=$(($_htmls+1))
     fi      
     ## cpu usage
     if [[ $element == cpu ]];then
             echo "<div id='TL'>System-CPU-Usage</div><p>"  >>  $html_dir/${ip}.html
             echo "<a href='${ip}.htmls/${ip}.${element}.html'><img src='../images/${element}/${ip}.day.png' alt='cpu-usage' /></a><p>">> $html_dir/${ip}.html
             echo "$ip:${element}:ok"; _htmls=$(($_htmls+1))
     fi
done


## 快速循环项，1分钟获取数据
for element in `grep -w $ip $conf_dir/$hostConf | awk -F:: '{print $4}'| sed 's/:/\ /g'`
do
          echo "<div id='TL'>System-TCP</div><p>"  >>  $html_dir/${ip}.html
          echo "<a href='${ip}.htmls/${ip}.${element}.html'><img src='../images/${element}/${ip}.day.png' alt='tcp' /></a><p>">> $html_dir/${ip}.html 
  	  echo "$ip:${element}:ok"; _htmls=$(($_htmls+1))

done



cat >> $html_dir/${ip}.html <<EOF
</body>
</html>
EOF
done
_end=`date -d "$(date +%Y%m%d\ %T)" +%s`
echo "处理完毕！共生成$_htmls个html页面，耗时" $(($_end-$_start)) "秒"
}




##-------------------------------------------- 详细页面 

function create_view_html
{
## 批量生成主机的详细页面

_start=`date -d "$(date +%Y%m%d\ %T)" +%s`
_htmls=0

function add_view_html_head
{
ele_head=$1
>$html_dir/${ip}.htmls/${ip}.${ele_head}.html
cat >> $html_dir/${ip}.htmls/${ip}.${ele_head}.html <<EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<style type='text/css'>
table{width:882px;border:2px solid #ccc;border-width:2px;background:#CAE5E8;}
table td {width:50%;height:10px;text-align:left;font-size:12px;}
#ttl {height:60px;text-align:center;vertical-align:bottom;font-size:30px;}
#TL {width:882px;height:35px;background:#94AAD6;text-align:left;font-size:32px;}
#abs_layer{position:fixed;right:20px;top:300px;width:50px;height:36px;}
</style>
</head>
<meta http-equiv="refresh" content="300" />
<body>
<div id="body_div">
<div>
<center>
EOF
echo "
<table>
<tr><td id='ttl'>Svr-${ip}服务器监控资源</td></tr>
<tr><td>主机名：`snmpwalk -v2c ${ip} -c ${snmp_key}  SNMPv2-MIB::sysName  | awk '{print $4}'`</td><tr>
<tr><td>系统类型：`snmpwalk -v2c ${ip} -c ${snmp_key}  SNMPv2-MIB::sysDescr | awk '{print  $4,$6}'`</td></tr>
<tr><td>运行时间：`snmpwalk -v2c ${ip} -c ${snmp_key}  HOST-RESOURCES-MIB::hrSystemUptime | awk '{print $5 $6 $7}'|sed 's/,/  /g'`</td></tr>
<tr><td>最后更新：`date +%Y-%m-%d\ %T `</td></tr>
</table><p><p>" >> $html_dir/${ip}.htmls/${ip}.${ele_head}.html
}

function add_view_html_foot
{
ele_foot=$1
cat >> $html_dir/${ip}.htmls/${ip}.${ele_foot}.html <<EOF	
  </div>
</div>
<div id="abs_layer">
<input type=button value="返回" style="width:50px;height:30px;font-size:16px;background:#CAE5E8;cursor:pointer;" onclick="javascript:history.back(1)" /></div>
</body>
</html>
EOF
}


for ip in `awk -F:: '{print $2}' $conf_dir/$hostConf`
do #进入主机列表循环，获取每台ip

     for element in ` grep -w $ip $conf_dir/$hostConf | awk -F:: '{print $3}'| sed 's/:/\ /g'`
     do
     	
	case $element in 
	"upload")
	## 系统负载
	     function sub
	     {	
	     if [[ ! -e $html_dir/${ip}.htmls/${ip}.${element}.html ]];then	
		     add_view_html_head ${element};sleep 1
		     echo "<div id='TL'>System-Upload</div><p>" >> $html_dir/${ip}.htmls/${ip}.${element}.html &
		     for days in day week month year
		     do
	     		echo "<img src='../../images/$element/${ip}.${days}.png' alt='系统负载' /><p>">>$html_dir/${ip}.htmls/${ip}.${element}.html &
		     done
	     	     add_view_html_foot ${element}	
		     echo "$ip:${element}.html create ok";_htmls=$(($_htmls+1))
	     fi		
	     }
	     ;;
    	"traffic") 
     	## 接口流量
	     function sub
	     {
	     for interface in `snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |awk '{print $4}' | grep -v lo | grep -v sit0|grep -v tun`
             do
	        if [[ ! -e $html_dir/${ip}.htmls/${ip}.${interface}.html ]];then		
		    add_view_html_head ${interface};sleep 1
		    echo "<div id='TL'>System-Traffic</div><p>" >>  $html_dir/${ip}.htmls/${ip}.${interface}.html &
	            for days in day week month year
		    do
        	       echo  "<img src='../../images/${element}/${ip}.${interface}.${days}.png'  alt='接口流量' /><p>" >>$html_dir/${ip}.htmls/${ip}.${interface}.html &
		    done
		    add_view_html_foot	${interface}
        	    echo "$ip:${interface}.html create ok";_htmls=$(($_htmls+1))
		fi
             done
	     }
	     ;; 
     	"io")
        ## 磁盘io 详细页面
	     function sub
	     {	
             for diskname in `snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::diskIODevice |grep sd |awk '{print $4}'|cut -c 1-3|uniq`
             do
                for iorw in  rws rwn
                do
			if [[ ! -e $html_dir/${ip}.htmls/${ip}.${diskname}.${iorw}.html ]];then
		           add_view_html_head "${diskname}.${iorw}";sleep 1
             		   echo "<div id='TL'>System-Disk-IO</div><p>"  >> $html_dir/${ip}.htmls/${ip}.${diskname}.${iorw}.html  &         
		           for days in day week month year
			   do
      echo "<img src='../../images/${element}/${ip}.${diskname}.${iorw}.${days}.png' alt='diskIO' /><p>">>$html_dir/${ip}.htmls/${ip}.${diskname}.${iorw}.html &
			   done
			   add_view_html_foot "${diskname}.${iorw}"
                           echo "$ip:${diskname}.${iorw}.html create ok";_htmls=$(($_htmls+1))
			fi
                done
             done
    	     } 
     	     ;;	
	"memory")
	## memory
	     function sub
	     {		
             for memory in   memTotalAvail  BufferCached  Swap
             do
                if [[ ! -e $html_dir/${ip}.htmls/${ip}.${memory}.html ]];then
		add_view_html_head ${memory};sleep 1
             	echo "<div id='TL'>System-Memory</div><p>"  >>  $html_dir/${ip}.htmls/${ip}.${memory}.html &
                for days in day week month year
		do
            echo "<img src='../../images/${element}/${ip}.${memory}.${days}.png' alt='memory' /><p>">> $html_dir/${ip}.htmls/${ip}.${memory}.html &
		done
	        add_view_html_foot ${memory}
                echo "$ip:${memory}.html create  ok";_htmls=$(($_htmls+1))
		fi 
             done
	     }
     	     ;;	
	"partition")
     	## disk partition
	      function  sub
	      {	
		if [[ ! -e $html_dir/${ip}.htmls/${ip}.${element}.html ]];then
		add_view_html_head ${element};sleep 1
                echo "<div id='TL'>System-Disk-Partiton</div><p>"  >>  $html_dir/${ip}.htmls/${ip}.${element}.html &
                for days in day week month year
    	        do
                echo "<img src='../../images/${element}/${ip}.${days}.png' alt='partition' /><p>">> $html_dir/${ip}.htmls/${ip}.${element}.html &
	        done
	        add_view_html_foot ${element}
                echo "$ip:${element}.html create ok";_htmls=$(($_htmls+1))
	        fi
	     }
	    ;;
        "cpu")
        ## cpu usage
              function  sub
              { 
                if [[ ! -e $html_dir/${ip}.htmls/${ip}.${element}.html ]];then
                add_view_html_head ${element};sleep 1
                echo "<div id='TL'>System-CPU-Usage</div><p>"  >>  $html_dir/${ip}.htmls/${ip}.${element}.html &
                for days in day week month year
                do
                echo "<img src='../../images/${element}/${ip}.${days}.png' alt='cpu-usage' /><p>">> $html_dir/${ip}.htmls/${ip}.${element}.html &
                done
                add_view_html_foot ${element}
                echo "$ip:${element}.html create ok";_htmls=$(($_htmls+1))
                fi
             }  
            ;;
	esac
	
	## Go doing .......
	sub &

     done


     for element in `grep -w $ip $conf_dir/$hostConf | awk -F:: '{print $4}'| sed 's/:/\ /g'`
     do
	case $element in 
	"tcp")
	## tcp 
		function sub
		{
		        if [[  -e $html_dir/${ip}.htmls/${ip}.${element}.html ]];then
		        add_view_html_head ${element};sleep 1
		        echo "<div id='TL'>System-TCP</div><p>"  >>  $html_dir/${ip}.htmls/${ip}.${element}.html &
		        for days in day week month year
		        do
			echo "<img src='../../images/${element}/${ip}.${days}.png' alt='tcp' /><p>">> $html_dir/${ip}.htmls/${ip}.${element}.html &
	                done
		        add_view_html_foot ${element}
		        echo "$ip:${element}.html create ok";_htmls=$(($_htmls+1))
			fi
		}
	;;
	esac

	## Go doing ......
	sub &	


     done



done
_end=`date -d "$(date +%Y%m%d\ %T)" +%s`
echo "处理完毕！共生成$_htmls个页面，耗时" $(($_end-$_start)) "秒"
}




###################################################
cat <<EOF
--------------------------------------------------
|           Welcome to html admin tool           |
--------------------------------------------------
| A|a :  批量生成主机的一级页面，包含各监控项。  |
| B|b :  初始化主机目录 X.X.X.X.htmls            | 
| C|c :  批量生成全部详细html页面                |
| E|e :  退出 tool                               |
--------------------------------------------------
请输入: [ A|a  B|b  C|c E|e ]
EOF

read var
case $var in
	A|a)create_host_html;;
	B|b)init_all_host_htmls_dir;;
	C|c)create_view_html;;
	E|e) exit 1;;
	*) echo "Please enter [ A|a B|b C|c E|e ]" ;;
esac
