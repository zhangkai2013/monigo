#!/bin/bash
#
source  /var/www/rrdtool/scripts/config_develop.sh
######################

#hostConf=host_config.list
hostConf=host_config.list.temp

lines=`awk 'END{print NR}' $conf_dir/$hostConf` ; i=1

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

function set_add_line
{
# 设定添加项目的记录行数
A=`awk 'END{print NR}' $html_dir/${ip}.html`
A=$(($A-4))
}



function add_element_to_host_html
{
while (($i<=$lines))
do
        ip=`sed -n "$i"p $conf_dir/$hostConf | awk '{print $2}'`
	set_add_line
        for element in $elements
        do
		## 添加页面主题
                #sed -i "s/<center>/&<table><tr><td>Svr-${ip}服务器监控资源<\/td><\/tr><\/table><p><p>/"  $html_dir/${ip}.html &
		#echo "add ${ip}.html successfull...."
                #sed -i "${A}a<h1>Svr-${ip}服务器监控资源</h1><p><p>"  $html_dir/${ip}.html &
                #sed -i "/Svr-172.16.1.1/d"  $html_dir/${ip}.html &
		#echo "delete ${ip}.html successfull....."

		#sed -i "/style/d" $html_dir/${ip}.html 
	        #sleep 1
		#sed -i "s/<\/head>/\<style type='text\/css'\>table\{width:882;border:2px solid #ccc;border-width:2px;background:CAE5E8;\}table td \{height:100;text-align:center;font:30\}\<\/style\>\<\/head\>/g"  $html_dir/${ip}.html 
		#sed -i "2a\<style type='text\/css'\>table\{width:882;border:2px solid #ccc;border-width:2px;background:CAE5E8;\}table td \{height:100;text-align:center;font:30\} #TL \{width:100%;height:35;background:94AAD6;text-align:left;font-size:25;\} \<\/style\>\<\/head\>"  $html_dir/${ip}.html 
                #echo "add ${ip}.html successfull....."

                ## 系统负载
                if [[ $element == upload ]];then
	               sed -i "/System-Upload/d"  $html_dir/${ip}.html &&  sed -i "${A}a<div id='TL'>System-Upload</div><p>" $html_dir/${ip}.html &&  set_add_line v &&  sed -i "/${element}/d"  $html_dir/${ip}.html && sed -i "${A}a<img src='..\/images\/${element}\/${ip}.day1.png'   alt='系统负载' /><p>"  $html_dir/${ip}.html && set_add_line
                       echo "$ip:${element}:ok"
                fi


                ## 接口流量
                if [[ $element == traffic ]];then
                   sed -i "/System-Traffic/d"  $html_dir/${ip}.html && sed -i "${A}a<div id='TL'>System-Traffic</div><p>" $html_dir/${ip}.html && set_add_line
                   for interface in `snmpwalk -v2c $ip -c crhkey IF-MIB::ifDescr |awk '{print $4}' | grep -v lo | grep -v sit0|grep -v tun`
                   do
			sleep 2
			sed -i "/${interface}/d"  $html_dir/${ip}.html &&   sed -i "${A}a<img src='..\/images\/${element}\/${ip}.${interface}.day1.png'   alt='接口流量' /><p>"  $html_dir/${ip}.html && set_add_line
			echo "$ip:${interface}:ok"
                   done
                fi


                ## 磁盘io 画图
                if [[ $element == io ]];then
                
                   # 遍历每个磁盘的io
                   sed -i "/System-Disk-IO/d"  $html_dir/${ip}.html && sed -i "${A}a<div id='TL'>System-Disk-IO</div><p>" $html_dir/${ip}.html && set_add_line
                   for diskname in `snmpwalk -v2c $ip -c crhkey UCD-DISKIO-MIB::diskIODevice |grep sd |awk '{print $4}'|cut -c 1-3|uniq`
                   do
   	             for iorw in  rsws rnwn
                     do
			 sleep 2
			 sed -i "/${ip}.${diskname}.${iorw}/d"  $html_dir/${ip}.html &&  sed -i "${A}a<img src='..\/images\/${element}\/${ip}.${diskname}.${iorw}.day1.png' alt='diskIO' /><p>" $html_dir/${ip}.html && set_add_line
		         echo "$ip:${diskname}.${iorw}:ok"
		     done
		   done
		fi

                ## memory
                if [[ $element == memory ]];then
	
	     sed -i "/System-Memory/d"  $html_dir/${ip}.html && sed -i "${A}a<div id='TL'>System-Memory</div><p>" $html_dir/${ip}.html && set_add_line
                     for memory in   memTotalAvail  BufferCached  Swap
                     do
                         sleep 2
                         sed -i "/${ip}.${memory}/d"  $html_dir/${ip}.html && sed -i "${A}a<img src='..\/images\/${element}\/${ip}.${memory}.day1.png' alt='memory' /><p>" $html_dir/${ip}.html && set_add_line
                         echo "$ip:${memory}:ok"
                     done
                fi



	done
        i=$(($i+1))
done
}

add_element_to_host_html
