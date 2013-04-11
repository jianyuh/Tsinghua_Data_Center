

VMs gain access to the metadata server locally present in the controller node via the external network. To create that necessary connection perform the following:

Get the IP address of router proj one:

quantum port-list -- --device_id <router_proj_one_id> --device_owner network:router_gateway
Add the following route on controller node only:

route add -net 50.50.1.0/24 gw $router_proj_one_IP



Unfortunatly, you can't use the dashboard to assign floating IPs to VMs so you need to get your hands a bit dirty to give your VM a public IP.

Start by allocating a floating ip to the project one tenant:

quantum floatingip-create --tenant-id $put_id_of_project_one ext_net
pick the id of the port corresponding to your VM:

quantum port-list
Associate the floating IP to your VM:

quantum floatingip-associate $put_id_floating_ip $put_id_vm_port
