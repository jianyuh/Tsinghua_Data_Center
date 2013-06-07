#!/usr/bin/expect
set timeout 10

set hostmac [lindex $argv 0]
set imagelocation [lindex $argv 1]
set kernel [lindex $argv 2]
set initrd [lindex $argv 3]

spawn /usr/bin/ssh iiis@10.10.0.50
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
expect "*password*" 
send "siii\r"
expect "# " 
send "bash mapHostImage.sh $hostmac $imagelocation $kernel $initrd\r"

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
