#!/usr/bin/expect
set timeout 10

set hostip [lindex $argv 0]

spawn /usr/bin/ssh iiisclient@$hostip
expect {
"password:" {
send "siii\r"
}
}

#interact {
#timeout 60 {send " "}
#}

expect "$ " 
send "sudo -s\r"
#expect "*password*" 
send "siii\r"
expect "# " 
#send "reboot\r"
send "mkdir et3test\r"

expect "# " 
send "reboot\r"
#interact

#set argc {llength $argv}
#for {set i 0} {$i<$argc} {incr i} {
#	send "[lindex $argv $i]\r"
#	expect "#"
#}

send "\r"
expect "# "
send "exit\r"
send "\r"

expect "$ "
send "exit\r"
send "exit\r"
#expect "$ " {
send_user "\n"
#}
#
