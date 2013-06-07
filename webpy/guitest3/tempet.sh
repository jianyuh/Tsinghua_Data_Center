

set hostmac [lindex $argv 0]
set imagelocation [lindex $argv 1]

#hostmac=$1
#echo $hostmac
#imagelocation=$2
#echo $imagelocation
tempfile=`echo ${hostmac}|sed -e "s/:/-/g"`
tftpbootfile="/export/nfsos/tftpboot/pxelinux.cfg/01-"${tempfile}
send_user ${tftpbootfile}

tftpbootfile="test.txt"

set cmd {
cat <<EOF > ${tftpbootfile}
PROMPT 0
DEFAULT linux
LABEL linux
  KERNEL vmlinuz-3.5.0-27-generic
  APPEND root=/dev/nfs initrd=initrd.img-3.5.0-27-generic nfsroot=10.10.0.50:$imagelocation ip=:::::eth0:dhcp rw
EOF
}

#echo "finished"


set timeout 10
spawn /usr/bin/ssh iiis@166.111.129.19
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
send "$cmd\r"

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
