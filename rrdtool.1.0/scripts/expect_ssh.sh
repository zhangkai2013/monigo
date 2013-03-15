#!/usr/bin/expect -f

if { $argc < 3 } {
puts stderr "Usage: $argv0 IPAdress Login OldPasswd Options"
exit
}

set IPADDR [lindex $argv 0]
set LOGIN [lindex $argv 1]
set OLD_PW [lindex $argv 2]
set OPTIONS [lindex $argv 3]

set timeout 30
stty -echo

if { $OPTIONS  == "snmprestart" } {
spawn ssh $IPADDR -l $LOGIN  -p8244
expect {
     "*yes/no*" {
        send "yes\r"
        exp_continue
    } "*password:*"  {
        send "$OLD_PW\r"
        exp_continue
    } "*Last login:*" {
        #interact
	send -- "service snmpd"
	expect -exact "pd"
	send -- " restart\r"
        expect "*#"
	#send -- "exit\r"
        exit 0
    } timeout {
        send_user "connection to $IPADDR timeout!\n"
        exit 1
    } "*incorrect*" {
        send_user "password incorrect!\n"
        exit 2
    } "*Permission*" {  
        send_user "password Error!\n"
        exit 2
    } eof {
        exit 3
    }
}

} else {
spawn ssh $IPADDR -l $LOGIN  -p8244
expect {
     "*yes/no*" {
        send "yes\r"
        exp_continue
    } "*password:*"  {
        send "$OLD_PW\r"
        exp_continue
    } "*Last login:*" {
        #interact
	send -- "n=`awk '/#disk/{print NR}' /etc/snmp/snmpd.conf`"
	expect -exact "n=`awk '/#disk/{print NR}' /etc/snmp/snmpd.conf`"
	send -- "\r"
	expect "*#"
	send -- "sed -i \"\"\$n\"adisk $OPTIONS 10000\"  /etc/snmp/snmpd.conf      "
	expect -exact "sed -i \"\"\$n\"adisk $OPTIONS 10000\"  /etc/snmp/snmpd.conf      "
	send -- "\r"
        expect "*#"
	#send -- "exit\r"
        exit 0
    } timeout {
        send_user "connection to $IPADDR timeout!\n"
        exit 1
    } "*incorrect*" {
        send_user "password incorrect!\n"
        exit 2
    } "*Permission*" {  
        send_user "password Error!\n"
        exit 2
    } eof {
        exit 3
    }
}

}
