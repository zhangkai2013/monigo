#!/bin/bash
#

source  /var/www/rrdtool/scripts/config.sh
last_update=`date +%Y-%m-%d\ %T`
tcp_file=$html_dir/tcp.html
tcp_temp_file=$html_dir/tcp_temp.txt
tcp_temp_body_file=$html_dir/tcp_body_temp.txt

########################
function echo_head
{
cat >$tcp_temp_file<< EOF
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>
</title>
<style type="text/css">
      body { margin:20px 0 50px 0px;}
     .title {width:95%;height:80px;margin-bottom:20px;background:#CAE5E8;border:2px solid #ccc;border-width:2px;}
     .title .ttl {width:95%;height:100%;font-weight: bold;text-align:center;padding-top:25px;font-size:30px}
     .equalborder {width:95%;height:1px;display:table;border:1px solid #ccc;border-width:1px;border-collapse:separate;} 
     .equal {width:95%;height:25px;display:table;border:1px solid #ccc;border-width:0px;border-collapse:separate;background:#CAE5E8;} 
     .row { display:table-row; } 
     .row div { display:table-cell;width:10%;text-align:center;vertical-align:middle;font-size:15px;background:#CAE5E8;border: solid;border-width: 1px;border-color: #ccc;} 
</style>
</head>
<body><center>
<div class='title'><div class="ttl">服务器.TCP连接信息</div></div>
<hr size="4" color="#CAE5E8"><br>
     <div class='equalborder'></div>
     <div class='equal'> 
         <div class='row'>      	
                <div style=width:50%>天文时间：0000:00:00:123456789</div> 
                <div style=width:50%>最后更新时间：$last_update</div> 
	</div>
     </div>
     <div class='equal'> 
        <div class='row1' style=font-weight:bold >	 
                <div>HOST</div> 
                <div>LISTEN</div> 
                <div>SYN_RECV</div> 
                <div>ESTABLISHED</div> 
                <div>TIME_WAIT</div> 
                <div>CLOSE_WAIT</div> 
                <div>FIN_WAIT1</div> 
                <div>FIN_WAIT2</div> 
                <div>CLOSING</div> 
        </div> 
    </div> 
EOF
}


function echo_body_d
{
last_update=`date +%T`
color=#CAE5E8
lines=`awk 'END{print NR}' $conf_dir/$hostConf`  ; i=1
while (($i<=$lines))
do
        #passwd=`sed -n ${i}p  $conf_dir/$hostConf  | awk '{print $1}'`
        ip=`sed -n ${i}p  $conf_dir/$hostConf | awk '{print $2}'`
cat<<EOF
   <div class='equal'> 
        <div class='row'> 
                <div>$ip</div> 
                <div><div style=border-width:0px;height:25px;background:$color>10</div></div> 
                <div><div style=border-width:0px;height:25px;background:$color>11</div></div> 
                <div><div style=border-width:0px;height:25px;background:#FF8000>1000</div></div> 
                <div><div style=border-width:0px;height:25px;background:$color>13</div></div> 
                <div><div style=border-width:0px;height:25px;background:#FF0000>2000</div></div> 
                <div><div style=border-width:0px;height:25px;background:$color>15</div></div> 
                <div><div style=border-width:0px;height:25px;background:$color>16</div></div> 
                <div><div style=border-width:0px;height:25px;background:$color>18</div></div> 
        </div> 
    </div>
EOF
i=$(($i+1))
done
}

function echo_tail
{
echo "<div class='equalborder'></div>
</center>
</body>
</html>
">> $tcp_temp_file
}

#################


case $1 in
    "ok") 
	echo_head		
	cat $tcp_temp_body_file >> $tcp_temp_file
	echo_tail
	mv -f  $tcp_temp_file  $tcp_file
	> $tcp_temp_body_file
	;;
      *)
	color=#CAE5E8
	ip=$1
	echo "<div class='equal'> 
        <div class='row'> 
                <div>$ip</div> 
                <div>$2</div> 
                <div>$3</div> 
                <div>$4</div> 
                <div>$5</div> 
                <div>$6</div> 
                <div>$7</div> 
                <div>$8</div> 
                <div>$9</div> 
        	</div> 
	</div>" >> $tcp_temp_body_file
      ;;
esac
