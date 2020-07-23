#!/bin/sh

 sudo pcs cluster cib drbd_cfg
 sudo pcs -f drbd_cfg resource create drbd_devpath ocf:linbit:drbd drbd_resource=pbxdata op monitor interval=10s
 sudo pcs -f drbd_cfg resource master drbd_devpath_master drbd_devpath master-max=1 master-node-max=1 clone-max=3 clone-node-max=1 notify=true
 sudo pcs cluster cib-push drbd_cfg --config
 sudo pcs resource enable drbd_devpath_master

 sudo pcs cluster cib vip_cfg
 sudo pcs -f vip_cfg resource create vip ocf:heartbeat:IPaddr2 ip=192.168.1.94 cidr_netmask=24 op monitor interval=5s
 sudo pcs -f vip_cfg constraint colocation add vip with drbd_devpath_master INFINITY with-rsc-role=Master
 sudo pcs -f vip_cfg constraint order promote drbd_devpath_master then start vip
 sudo pcs cluster cib-push vip_cfg --config
 sudo pcs resource enable vip

 rm -rf ipsrcaddr_cfg
 sudo pcs cluster cib ipsrcaddr_cfg
 sudo pcs -f ipsrcaddr_cfg resource create src_pkt_ip ocf:heartbeat:IPsrcaddr ipaddress=192.168.1.94 cidr_netmask=32 op monitor interval=5s
 sudo pcs -f ipsrcaddr_cfg constraint colocation add src_pkt_ip with vip INFINITY
 sudo pcs -f ipsrcaddr_cfg constraint order vip then src_pkt_ip
 sudo pcs cluster cib-push ipsrcaddr_cfg --config
 sudo pcs resource enable src_pkt_ip

rm -f datapath_fs_cfg
pcs cluster cib datapath_fs_cfg
pcs -f datapath_fs_cfg resource create datapath_fs Filesystem device="/dev/drbd1" directory="/var/lib/pbx" fstype="xfs"
pcs -f datapath_fs_cfg constraint colocation add datapath_fs with drbd_devpath_master INFINITY with-rsc-role=Master
pcs -f datapath_fs_cfg constraint order promote drbd_devpath_master then start datapath_fs
pcs -f datapath_fs_cfg constraint colocation add datapath_fs with vip INFINITY
pcs cluster cib-push datapath_fs_cfg --config
pcs resource enable datapath_fs

pcs resource defaults resource-stickiness=100
