#!/usr/bin/expect -f

if { $argc < 3 } {
puts stderr "Usage: $argv0 Filename IPAdress  Passwd"
exit
}

set FILE [lindex $argv 0]
set IPADDR [lindex $argv 1]
set OLD_PW [lindex $argv 2]

set timeout 30

stty -echo

spawn scp -P8244 $FILE  $IPADDR:/opt/mrtg/
expect {
     "*yes/no*" {
 	send "yes\r"
        exp_continue
    } "*password:*"  {
        send "$OLD_PW\r"
        exp_continue
    } timeout {
        send_user "connection to $IPADDR timeout!\n"
        exit 1
    } "*Permission*" {  #for LINUX ssh
        send_user "password Error!\n"
        exit 2
    } eof {
        exit 3
    }
}

