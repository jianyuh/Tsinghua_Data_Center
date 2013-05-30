
DNS_SERVER=${DNS_SERVER:-"166.111.8.28"}

COMPUTE_MNG_ETH=${COMPUTE_EXT_ETH:-"eth2"}
COMPUTE_MNG_IP=${COMPUTE_EXT_IP:-"192.168.10.53"}

COMPUTE_VM_ETH=${COMPUTE_VM_ETH:-"eth4"}
COMPUTE_VM_IP=${COMPUTE_VM_IP:-"192.168.20.53"}


CONTROLLER_MNG_IP=${CONTROLLER_EXT_IP:-"192.168.10.51"}




#update the cloud source

CLOUD_SOURCELIST=${CLOUD_SOURCELIST:-"/etc/apt/sources.list.d/cloud-archive.list"}

apt-get install -y ubuntu-cloud-keyring
cat <<EOF >$CLOUD_SOURCELIST
deb http://ubuntu-cloud.archive.canonical.com/ubuntu precise-updates/folsom main
EOF


#Update the software
apt-get update -y
apt-get upgrade -y
apt-get dist-upgrade -y

####################################################
#Node synchronization
####################################################
apt-get install -y ntp
sed -i 's/server ntp.ubuntu.com/server $COMPUTE_MNG_IP/g' /etc/ntp.conf
#sed -i 's/server ntp.ubuntu.com/server 192.168.10.51/g' /etc/ntp.conf
service ntp restart

####################################################
#Other Service & Configurations
####################################################

apt-get install -y vlan bridge-utils

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
# To save you from rebooting, perform the following
sysctl net.ipv4.ip_forward=1


####################################################
#Network Interface
####################################################
cat << EOF >> "/etc/network/interfaces"

# OpenStack management
auto $COMPUTE_MNG_ETH
iface $COMPUTE_MNG_ETH inet static
address $COMPUTE_EXT_IP
netmask 255.255.255.0

# VM Configuration
auto $COMPUTE_VM_ETH
iface $COMPUTE_VM_ETH inet static
address $COMPUTE_VM_IP
netmask 255.255.255.0
EOF

apt-get install -y kvm libvirt-bin pm-utils

cat << EOF >> "/etc/libvirt/qemu.conf"
cgroup_device_acl = [
"/dev/null", "/dev/full", "/dev/zero",
"/dev/random", "/dev/urandom",
"/dev/ptmx", "/dev/kvm", "/dev/kqemu",
"/dev/rtc", "/dev/hpet","/dev/net/tun"
]
EOF

virsh net-destroy default
virsh net-undefine default

cat << EOF >> "/etc/libvirt/libvirtd.conf"
listen_tls = 0
listen_tcp = 1
auth_tcp = "none"
EOF

#?????????????????????????????????????????????
sed -i 's/env libvirtd_opts="-d"/env libvirtd_opts="-d -l"/g' /etc/init/libvirt-bin.conf

/etc/default/libvirt-bin
sed -i 's/libvirtd_opts="-d"/libvirtd_opts="-d -l"/g' /etc/default/libvirt-bin

service libvirt-bin restart

####################################################
#OpenvSwitch
####################################################

apt-get install -y openvswitch-switch openvswitch-datapath-dkms

#br-int will be used for VM integration
ovs-vsctl add-br br-int

#br-eth1 will be used for VM configuration
ovs-vsctl add-br br-eth1
ovs-vsctl add-port br-eth1 eth1



####################################################
#Quantum
####################################################
apt-get -y install quantum-plugin-openvswitch-agent

sed -i 's/#sql_connection = sqlite:////var/lib/quantum/ovs.sqlite/sql_connection = mysql://quantumUser:quantumPass@$CONTROLLER_MNG_IP/quantum/g' /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini 

cat <<EOF >> /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini
tenant_network_type=vlan
network_vlan_ranges = physnet1:1:4094
bridge_mappings = physnet1:br-eth1
EOF

sed -i 's/# rabbit_host = localhost/rabbit_host = $CONTROLLER_MNG_IP/g' /etc/quantum/quantum.conf


#[keystone_authtoken]
#auth_host = 192.168.10.51
#auth_port = 35357
#auth_protocol = http
#admin_tenant_name = service
#admin_user = quantum
#admin_password = service_pass
#
#signing_dir = /var/lib/quantum/keystone-signing
                                                 
service quantum-plugin-openvswitch-agent restart



####################################################
#Nova
####################################################
apt-get install -y nova-compute-kvm

 /etc/nova/api-paste.ini
[filter:authtoken]
paste.filter_factory = keystone.middleware.auth_token:filter_factory
auth_host = $CONTROLLER_MNG_IP
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = nova
admin_password = service_pass
signing_dirname = /tmp/keystone-signing-nova

cat <<EOF >  /etc/nova/nova-compute.conf 
[DEFAULT]
libvirt_type=kvm
libvirt_ovs_bridge=br-int
libvirt_vif_type=ethernet
libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
libvirt_use_virtio_for_bridges=True
EOF

cat <<EOF > /etc/nova/nova.conf
[DEFAULT]
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/run/lock/nova
verbose=True
api_paste_config=/etc/nova/api-paste.ini
#scheduler_driver=nova.scheduler.simple.SimpleScheduler
compute_scheduler_driver=nova.scheduler.filter_scheduler.FilterScheduler
s3_host=$CONTROLLER_MNG_IP
ec2_host=$CONTROLLER_MNG_IP
ec2_dmz_host=$CONTROLLER_MNG_IP
rabbit_host=$CONTROLLER_MNG_IP
dmz_cidr=169.254.169.254/32
#metadata_host=$CONTROLLER_MNG_IP
#metadata_listen=0.0.0.0
sql_connection=mysql://novaUser:novaPass@$CONTROLLER_MNG_IP/nova
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf

# Auth
use_deprecated_auth=false
auth_strategy=keystone
keystone_ec2_url=http://$CONTROLLER_MNG_IP:5000/v2.0/ec2tokens
# Imaging service
glance_api_servers=$CONTROLLER_MNG_IP:9292
image_service=nova.image.glance.GlanceImageService

# Vnc configuration
novnc_enabled=true
novncproxy_base_url=http://$CONTROLLER_MNG_IP:6080/vnc_auto.html
novncproxy_port=6080
vncserver_proxyclient_address=$COMPUTE_VM_IP
vncserver_listen=0.0.0.0

# Network settings
network_api_class=nova.network.quantumv2.api.API
quantum_url=http://$CONTROLLER_MNG_IP:9696
quantum_auth_strategy=keystone
quantum_admin_tenant_name=service
quantum_admin_username=quantum
quantum_admin_password=service_pass
quantum_admin_auth_url=http://$CONTROLLER_MNG_IP:35357/v2.0
libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver

#Metadata
service_quantum_metadata_proxy = True
quantum_metadata_proxy_shared_secret = helloOpenStack

# Compute #
compute_driver=libvirt.LibvirtDriver

# Cinder #
volume_api_class=nova.volume.cinder.API
osapi_volume_listen_port=5900
cinder_catalog_info=volume:cinder:internalURL
EOF

cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; done
nova-manage service list









