
hostmac=$1
echo $hostmac
imagelocation=$2
echo $imagelocation

#tftpbootfile="/export/nfsos/tftpboot/pxelinux.cfg/01-"${hostmac//:/-}
tempfile=`echo ${hostmac}|sed -e "s/:/-/g"`
tftpbootfile="/export/nfsos/tftpboot/pxelinux.cfg/01-"${tempfile}
echo ${tftpbootfile}

tftpbootfile="test.txt"


cat <<EOF > ${tftpbootfile}
PROMPT 0
DEFAULT linux
LABEL linux
  KERNEL vmlinuz-3.5.0-27-generic
  APPEND root=/dev/nfs initrd=initrd.img-3.5.0-27-generic nfsroot=10.10.0.50    :$imagelocation ip=:::::eth0:dhcp rw
EOF

echo "finished"
