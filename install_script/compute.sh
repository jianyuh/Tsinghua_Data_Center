DNS_SERVER=${DNS_SERVER:-"166.111.8.28"}



COMPUTE_MNG_ETH=${COMPUTE_EXT_ETH:-"eth2"}
COMPUTE_MNG_IP=${COMPUTE_EXT_IP:-"192.168.10.53"}

COMPUTE_VM_ETH=${COMPUTE_VM_ETH:-"eth1"}
COMPUTE_VM_IP=${COMPUTE_VM_IP:-"192.168.20.53"}

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
/etc/network/interfaces
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

####################################################
#KVM
####################################################

apt-get install -y cpu-checker
kvm-ok


apt-get install -y kvm libvirt-bin pm-utils

 /etc/libvirt/qemu.conf 
cgroup_device_acl = [
"/dev/null", "/dev/full", "/dev/zero",
"/dev/random", "/dev/urandom",
"/dev/ptmx", "/dev/kvm", "/dev/kqemu",
"/dev/rtc", "/dev/hpet","/dev/net/tun"
]

virsh net-destroy default
virsh net-undefine default


/etc/libvirt/libvirtd.conf 
#########????????????????libvirtddddddd
listen_tls = 0
listen_tcp = 1
auth_tcp = "none"

/etc/init/libvirt-bin.conf 

env libvirtd_opts="-d -l"

/etc/default/libvirt-bin
libvirtd_opts="-d -l"

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

/etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini 
#Under the database section
[DATABASE]
sql_connection = mysql://quantumUser:quantumPass@$CONTROLLER_MNG_IP/quantum

#Under the OVS section
[OVS]
tenant_network_type=vlan
network_vlan_ranges = physnet1:1:4094
bridge_mappings = physnet1:br-eth1


 /etc/quantum/quantum.conf 

rabbit_host = $CONTROLLER_MNG_IP

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

 /etc/nova/nova-compute.conf 

[DEFAULT]
libvirt_type=kvm
libvirt_ovs_bridge=br-int
libvirt_vif_type=ethernet
libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
libvirt_use_virtio_for_bridges=True

/etc/nova/nova.conf
[DEFAULT]
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/run/lock/nova
verbose=True
api_paste_config=/etc/nova/api-paste.ini
scheduler_driver=nova.scheduler.simple.SimpleScheduler
s3_host=192.168.10.51
ec2_host=192.168.10.51
ec2_dmz_host=192.168.10.51
rabbit_host=192.168.10.51
dmz_cidr=169.254.169.254/32
metadata_host=192.168.10.51
metadata_listen=0.0.0.0
sql_connection=mysql://novaUser:novaPass@192.168.10.51/nova
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf

# Auth
use_deprecated_auth=false
auth_strategy=keystone
keystone_ec2_url=http://192.168.10.51:5000/v2.0/ec2tokens
# Imaging service
glance_api_servers=192.168.10.51:9292
image_service=nova.image.glance.GlanceImageService

# Vnc configuration
novnc_enabled=true
novncproxy_base_url=http://10.10.0.200:6080/vnc_auto.html
novncproxy_port=6080
vncserver_proxyclient_address=192.168.10.53
vncserver_listen=0.0.0.0

# Network settings
network_api_class=nova.network.quantumv2.api.API
quantum_url=http://192.168.10.51:9696
quantum_auth_strategy=keystone
quantum_admin_tenant_name=service
quantum_admin_username=quantum
quantum_admin_password=service_pass
quantum_admin_auth_url=http://192.168.10.51:35357/v2.0
libvirt_vif_driver=nova.virt.libvirt.vif.LibvirtHybridOVSBridgeDriver
linuxnet_interface_driver=nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver=nova.virt.libvirt.firewall.IptablesFirewallDriver

# Compute #
compute_driver=libvirt.LibvirtDriver

# Cinder #
volume_api_class=nova.volume.cinder.API
osapi_volume_listen_port=5900


cd /etc/init.d/; for i in $( ls nova-* ); do sudo service $i restart; done


nova-manage service list




