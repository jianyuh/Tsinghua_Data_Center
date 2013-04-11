#root right
if [ `whoami` != "root" ]; then  
        sudo passwd  
        exec su -c 'sh ./test.sh'  
fi  


#change the order of NIC
NIC_FILE=${NIC_FILE:-"/etc/udev/rules.d/70-persistent-net.rules"}
sed -i "s/eth2/eth6/g" $NIC_FILE
sed -i "s/eth3/eth2/g" $NIC_FILE
sed -i "s/eth4/eth3/g" $NIC_FILE
sed -i "s/eth6/eth4/g" $NIC_FILE

reboot


#####################################################################

#change the sourcelist
SOURCE_FILE=${SOURCE_FILE:-"/etc/apt/sources.list"} 
cp $SOURCE_FILE $SOURCE_FILE.bak  
cat <<APT >$SOURCE_FILE 
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ precise main multiverse restricted universe 
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ precise-backports main multiverse restricted universe 
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ precise-proposed main multiverse restricted universe 
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ precise-security main multiverse restricted universe 
deb http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ precise-updates main multiverse restricted universe 
deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ precise main multiverse restricted universe 
deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ precise-backports main multiverse restricted universe 
deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ precise-proposed main multiverse restricted universe 
deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ precise-security main multiverse restricted universe 
deb-src http://mirrors.tuna.tsinghua.edu.cn/ubuntu/ precise-updates main multiverse restricted universe
APT

#update the cloud source
apt-get install -y ubuntu-cloud-keyring

CLOUD_SOURCELIST=${CLOUD_SOURCELIST:-"/etc/apt/sources.list.d/cloud-archive.list"}
cat <<EOF >$CLOUD_SOURCELIST
deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/folsom main
EOF


#Update the software
apt-get update -y
apt-get upgrade -y


















