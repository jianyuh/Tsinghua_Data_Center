=================================================

===================================================

Modified from:
https://help.ubuntu.com/community/DisklessUbuntuHowto


Table of Contents
=================
::

   What is diskless booting?
   Why do it?
   How is this different than ThinClientHowto?
   How does it work?
   Requirements
   Getting Started
     Naming Conventions
     Set up your Server
     Creating your NFS installation
   
Getting Started
================

Naming Conventions
---------------------

Client: A diskless system that you wish to boot via a network connection 
Server: An always-on system which will provide the neccesary files to allow the client to boot over the network

Set up your Server
-------------------

* 1. Install the required packages::
   sudo apt-get install dhcp3-server tftpd-hpa syslinux nfs-kernel-server initramfs-tools
* 2. Configure your DHCP server 

You need to set up the DHCP server to offer /tftpboot/pxelinux.0 as a boot file as a minimum. You also assign a fixed IP to the machine you want to boot with PXE (the client). A range of other options are also available but are beyond the scope of this article. Your /etc/dhcp/dhcpd.conf might look like this assuming your subnet is 10.100.0.0/24 ::
   allow booting;
   allow bootp;
    
   ddns-update-style none;
   
   option domain-name "example.org";
   option domain-name-servers ns1.example.org, ns2.example.org;
   
   default-lease-time 600;
   max-lease-time 7200;
   
   log-facility local7;
   
   subnet 10.10.0.0 netmask 255.255.255.0 {
       range 10.10.0.200 10.10.0.250;
       option broadcast-address 10.10.0.255;
       option routers 10.10.0.1;
       option domain-name-servers 8.8.4.4;
   
       filename "/pxelinux.0";
   }
   
   # eth0 of NFS server
   host nfseth0 {
       hardware ethernet 60:de:44:75:14:3a;
       fixed-address 10.10.0.50;
   }
   
   # eth1 of NFS server
   host nfseth1 {
       hardware ethernet 60:de:44:75:14:3b;
       fixed-address 10.10.0.51;
   }
   
   #host client1eth0{
   #    hardware ethernet

NOTE : the filename is a relative path to the root of the tftp server. 

Restart DHCP Server using the command::
   sudo service isc-dhcp-server restart

   ps -elf| grep dhcp

   netstat  –pna | grep dhcp

* 3.Configure the TFTP Server

We need to set tftp-hpa to run in daemon mode and to use /tftpboot as its root directory. 
Here is an example /etc/default/tftpd-hpa file::
  # /etc/default/tftpd-hpa
  
  #defaults for tftpd-hpa
  
  RUN_DAEMON="yes"
  TFTP_USERNAME="tftp"
  
  TFTP_DIRECTORY="/export/nfsos/tftpboot"
  
  TFTP_ADDRESS="0.0.0.0:69"
   
  #TFTP_OPTIONS="--secure"
  TFTP_OPTIONS="-l -s"
  
  #OPTIONS="-l -s /export/nfsos/tftpboot"
  #OPTIONS="-l -s /var/lib/tftpboot"

Configure your tftp root directory
   a. Create directories::
      sudo mkdir -p /tftpboot/pxelinux.cfg
   b. Copy across bootfile::
      sudo cp /usr/lib/syslinux/pxelinux.0 /tftpboot
   c. Create default configuration file /tftpboot/pxelinux.cfg/default::
   (https://wiki.archlinux.org/index.php/Diskless_System)
   (http://ubuntuforums.org/showthread.php?t=1838201 )
   PROMPT 0
   DEFAULT linux
   LABEL linux
     KERNEL vmlinuz-3.5.0-23-generic
     APPEND root=/dev/nfs initrd=initrd.imgnew3 nfsroot=10.10.0.50:/export/nfsos/newnfsroot ip=:::::eth0:dhcp rw
   
NOTE1: your nfs server IP address, kernel name, and initrd name will likely be different. If you have a preconfigured system the names should be the names of the kernel and initrd (see below) on the client system 
NOTE2: to find the vmlinuz type uname -r 
NOTE3: There are more options available such as MAC or IP identification for multiple config files see syslinux/pxelinux documentation for help. 
NOTE4: Newer distributions might require that you append ",rw" to the end of the "nfsroot=" specification, to prevent a race in the Upstart version of the statd and portmap scripts.

d. Set permissions::
   sudo chmod -R 777 /tftpboot
NOTE:If the files do not have the correct permissions you will receive a "File Not Found" or "Permission Denied" error.

e. Start the tftp-hpa service:::
  sudo /etc/init.d/tftpd-hpa start

16. Configure OS root
-----------------------------
a. Create a directory to hold the OS files for the client::
   sudo mkdir /nfsroot
b. configure your /etc/exports to export your /nfsroot::
   /export/nfsos		10.10.0.0/24(rw,no_root_squash,async,insecure)
NOTE: The '192.168.2.xxx' should be replaced with either the client IP or hostname for single installations, or wildcards to match the set of servers you are using. 
Note: In versions prior to Ubuntu 11.04 the option ',insecure' is not required after async.

c. sync your exports::
   sudo exportfs -rv

Creating your NFS installation
-------------------------------

There are a few ways you can go about this:
debbootstrap (as outlined at Installation/OnNFSDrive)
copying the install from your server
install [lk]ubuntu on the client from CD, after you've got your system installed and working on the network mount the /nfsroot and copy everything from your working system to it.
This tutorial will focus on the last option. The commands in this section should be carried out on the client machine unless it is explicitly noted otherwise. You should ensure that the following package is installed on the client nfs-common
1. Copy current kernel version to your home directory.

uname -r will print your kernel version, and ~ is shorthand for your home directory.::
   cp /boot/vmlinuz-`uname -r` ~
2. Create an initrd.img file
Change the BOOT flag to nfs in /etc/initramfs-tools/initramfs.conf::
   #
   # BOOT: [ local | nfs ]
   #
   # local - Boot off of local media (harddrive, USB stick).
   #
   # nfs - Boot using an NFS drive as the root of the drive.
   #
   
   BOOT=nfs
   Change the MODULES flag to netboot in /etc/initramfs-tools/initramfs.conf
   #
   # MODULES: [ most | netboot | dep | list ]
   #
   # most - Add all framebuffer, acpi, filesystem, and harddrive drivers.
   #
   # dep - Try and guess which modules to load.
   #
   # netboot - Add the base modules, network modules, but skip block devices.
   #
   # list - Only include modules from the 'additional modules' list
   #
   
   MODULES=netboot
   NOTE: if you have anything in /etc/initramfs-tools/conf.d/driver-policy, this line will be ignored.
   
   Check which modules you will need for your network adapters and put their names into /etc/initramfs-tools/modules (for example forcedeth , r8169 or tulip)
   
   
   #vi /etc/udev/rules.d/70-persistent-net.rules
   # This file was automatically generated by the /lib/udev/write_net_rules
   # program, run by the persistent-net-generator.rules rules file.
   #
   # You can modify it, as long as you keep each rule on a single
   # line, and change only the value of the NAME= key.
   
   # PCI device 0x8086:/sys/devices/pci0000:00/0000:00:01.1/0000:02:00.0 (igb)
   #SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="60:de:44:75:14:34", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth0"
   
   # PCI device 0x8086:/sys/devices/pci0000:00/0000:00:01.1/0000:02:00.2 (igb)
   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="60:de:44:75:14:36", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth2"
   
   # PCI device 0x8086:/sys/devices/pci0000:00/0000:00:01.1/0000:02:00.3 (igb)
   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="60:de:44:75:14:37", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth3"
   
   # PCI device 0x8086:/sys/devices/pci0000:80/0000:80:01.0/0000:81:00.1 (ixgbe)
   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="10:47:80:01:69:db", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth5"
   
   # PCI device 0x8086:/sys/devices/pci0000:80/0000:80:01.0/0000:81:00.0 (ixgbe)
   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="10:47:80:01:69:da", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth4"
    
   # PCI device 0x8086:/sys/devices/pci0000:00/0000:00:01.1/0000:02:00.1 (igb)
   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="60:de:44:75:14:35", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth1"
   
   # PCI device 0x8086:/sys/devices/pci0000:00/0000:00:01.1/0000:02:00.2 (igb)
   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="60:de:44:75:14:42", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth6"
   
   # PCI device 0x8086:/sys/devices/pci0000:00/0000:00:01.1/0000:02:00.3 (igb)
   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="60:de:44:75:14:43", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth7"
   
   # PCI device 0x8086:/sys/devices/pci0000:80/0000:80:01.0/0000:81:00.0 (ixgbe)
   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="10:47:80:01:69:d4", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth8"
   
   # PCI device 0x8086:/sys/devices/pci0000:80/0000:80:01.0/0000:81:00.1 (ixgbe)
   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="10:47:80:01:69:d5", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth9"
   
   # PCI device 0x8086:/sys/devices/pci0000:00/0000:00:01.1/0000:02:00.1 (igb)
   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="60:de:44:75:14:41", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth10"
   
   # PCI device 0x8086:/sys/devices/pci0000:00/0000:00:01.1/0000:02:00.0 (igb)
   SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="60:de:44:75:14:40", ATTR{dev_id}=="0x0", ATTR{type}=="1", KERNEL=="eth*", NAME="eth0"
   
The above network interface card driver is igb and ixgbe.::
   update-initramfs -c -k 'uname -r' -b /home/<USERNAM

   #/usr/share/initramfs-tools/modules.d
   created the file /usr/share/initramfs-tools/modules.d/igb. That file contained a single word, igb.
   created the file /usr/share/initramfs-tools/modules.d/ixgbe. That file contained a single word,ixgbe.
   
Refer to http://blather.michaelwlucas.com/archives/665::
   # update-initramfs -u -k all
   # mkinitramfs -o /home/mwlucas/initrd.img-2.6.35-27-server-pxe



Run mkinitramfs

Some people prefer to append the kernel version to the end of the initrd.img file just to keep track of things. Since we just found which version our kernel is, run the command 
mkinitramfs -o /home/<USERNAME>/initrd.img-`uname -r`
NOTE: you can also accomplish the same result as above with: 
update-initramfs -c -k 'uname -r' -b /home/<USERNAME>
but this has the advantage of choosing the kernel version specified instead of using the most recent installed
3. Copy OS files to the server::
   mount -t nfs -onolock 10.10.0.50:/export/nfsos/newnfsroot /mnt
   cp -ax /. /mnt/.
   cp -ax /dev/. /mnt/dev/.
NOTE: If the client source installation you copied the files from should remain bootable and usable from local hard disk, restore the former BOOT=local and MODULES=most options you changed in /etc/initramfs-tools/initramfs.conf. Otherwise, the first time you update the kernel image on the originating installation, the initram will be built for network boot, giving you "can't open /tmp/net-eth0.conf" and "kernel panic". Skip this step if you no longer need the source client installation.
4. Copy kernel and initrd to tftp root.

Run these commands ON THE SERVER::
   cp /nfsroot/home/<USERNAME>/<vmlinuz-xxxx> /tftpboot/
   cp /nfsroot/home/<USERNAME>/<initrd.img-xxxx> /tftpboot/
5. Modify /nfsroot/etc/network/interfaces

When booting over the network, the client will already have carried out a DHCP discovery before the OS is reached. For this reason you should ensure the OS does not try to reconfigure the interface later. 
You should set your network interface to be "manual" not "auto" or "dhcp". Below is an example file.::
   # This file describes the network interfaces available on your system
   # and how to activate them. For more information, see interfaces(5).
   
   # The loopback network interface
   auto lo
   iface lo inet loopback
   
   # The primary network interface, commented out for NFS root
   #auto eth0
   #iface eth0 inet dhcp
   iface eth0 inet manual
NOTE: For Ubuntu 7.04 (Feisty Fawn) it seems the /etc/network/interfaces needs a little tweak, in order *not* to have theNetworkManager fiddle with the interface since it's already configured (see also bug #111227 : "NFS-root support indirectly broken in Feisty")
6. Configure fstab

/nfsroot/etc/fstab contains the information the client will use to mount file systems on boot, edit it to ensure it looks something like this ('note no swap')::
   # /etc/fstab: static file system information.
   #
   # Use 'blkid' to print the universally unique identifier for a
   # device; this may be used with UUID= as a more robust way to name devices
   # that works even if disks are added and removed. See fstab(5).
   #
   # <file system> <mount point>   <type>  <options>       <dump>  <pass>
   #proc            /proc           proc    nodev,noexec,nosuid 0       0
   /dev/nfs	/	nfs	defaults	0	0
   none	/tmp	tmpfs	defaults	0	0
   none	/var/run	tmpfs	defaults	0	0
   none	/var/lock	tmpfs	defaults	0	0
   none	/var/tmp	tmpfs	defaults	0	0
   /dev/hdc	/media/cdrom0	udf,iso9660	user,noauto	0	0
NOTE: if you have entries for other tmpfs that's fine to leave them in there



