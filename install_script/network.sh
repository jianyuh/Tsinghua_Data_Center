


DNS_SERVER=${DNS_SERVER:-"166.111.8.28"}

#CONTROLLER_EXT_ETH=${CONTROLLER_EXT_ETH:-"eth0"}
NETWORK_EXT_IP=${NETWORK_EXT_EXT_IP:-"10.10.0.201"}
#CONTROLLER_EXT_GW=${CONTROLLER_EXT_IP:-"10.10.0.1"}

NETWORK_MNG_ETH=${NETWORK_EXT_EXT_ETH:-"eth2"}
NETWORK_MNG_IP=${NETWORK_EXT_EXT_IP:-"192.168.10.52"}

NETWORK_VM_ETH=${NETWORK_EXT_VM_ETH:-"eth1"}
NETWORK_VM_IP=${NETWORK_EXT_VM_IP:-"192.168.20.52"}

####################################################
#Node synchronization
####################################################
apt-get install -y ntp
sed -i 's/server ntp.ubuntu.com/server $CONTROLLER_MNG_IP/g' /etc/ntp.conf
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
# VM internet Access
auto eth0
iface eth0 inet dhcp

# OpenStack management
auto eth2
iface eth2 inet static
address $NETWORK_MNG_IP
netmask 255.255.255.0

# VM Configuration
auto eth1
iface eth1 inet static
address $NETWORK_VM_IP
netmask 255.255.255.0

####################################################
# OpenVSwitch
####################################################
apt-get install -y openvswitch-switch openvswitch-datapath-dkms

#br-int will be used for VM integration
ovs-vsctl add-br br-int

#br-eth1 will be used for VM configuration
ovs-vsctl add-br br-eth1
ovs-vsctl add-port br-eth1 $NETWORK_VM_ETH

#br-ex is used to make to VM accessible from the internet
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex $NETWORK_EXT_ETH


################???????????????cannot bridge????



####################################################
# Quantum
####################################################

apt-get -y install quantum-plugin-openvswitch-agent quantum-dhcp-agent quantum-l3-agent

/etc/quantum/api-paste.ini
[filter:authtoken]
paste.filter_factory = keystone.middleware.auth_token:filter_factory
auth_host = $CONTROLLER_MNG_IP
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = quantum
admin_password = service_pass

 /etc/quantum/plugins/openvswitch/ovs_quantum_plugin.ini 


#Under the database section
[DATABASE]
sql_connection = mysql://quantumUser:quantumPass@$CONTROLLER_MNG_IP/quantum

#Under the OVS section
[OVS]
tenant_network_type=vlan
network_vlan_ranges = physnet1:1:4094
bridge_mappings = physnet1:br-eth1

 /etc/quantum/l3_agent.ini

#####################????????????????????????????????????/auth_url!!!!!!!!!!!!!!!!!!!
auth_url = http://$CONTROLLER_MNG_IP:35357/v2.0
auth_region = RegionOne
admin_tenant_name = service
admin_user = quantum
admin_password = service_pass
metadata_ip = $CONTROLLER_EXT_IP
metadata_port = 8775



####################################################
# rabbitmq  /etc/quantum/quantum.conf
####################################################
rabbit_host = $CONTROLLER_MNG_IP


 /etc/quantum/quantum.conf
service quantum-plugin-openvswitch-agent restart
service quantum-dhcp-agent restart
service quantum-l3-agent restart
















