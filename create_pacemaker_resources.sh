#!/bin/bash
init(){
ssh $1 "mkdir -p /usr/lib/ocf/resource.d/portsip/"
ssh $2 "mkdir -p /usr/lib/ocf/resource.d/portsip/"
scp ./pbx $1:/usr/lib/ocf/resource.d/portsip/
scp ./pbx $2:/usr/lib/ocf/resource.d/portsip/
mkdir -p /usr/lib/ocf/resource.d/portsip/
cp -f ./pbx /usr/lib/ocf/resource.d/portsip/
chmod +x /usr/lib/ocf/resource.d/portsip/pbx
ssh $1 "chmod +x /usr/lib/ocf/resource.d/portsip/pbx"
ssh $2 "chmod +x /usr/lib/ocf/resource.d/portsip/pbx"
##init
pcs  resource delete drbd_devpath_master >/dev/null 2>&1
pcs resource delete vip >/dev/null 2>&1
pcs resource delete src_pkt_ip  >/dev/null 2>&1
pcs resource delete datapath_fs >/dev/null 2>&1
pcs resource delete  pbx >/dev/null 2>&1
pcs resource cleanup  >/dev/null 2>&1
}
create(){
pcs cluster cib drbd_cfg
pcs -f drbd_cfg resource create drbd_devpath ocf:linbit:drbd drbd_resource=pbxdata op monitor interval=10s
pcs -f drbd_cfg resource master drbd_devpath_master drbd_devpath master-max=1 master-node-max=1 clone-max=3 clone-node-max=1 notify=true
pcs cluster cib-push drbd_cfg --config
pcs resource enable drbd_devpath_master
pcs cluster cib vip_cfg
pcs -f vip_cfg resource create vip ocf:heartbeat:IPaddr2 ip=$1 cidr_netmask=24 op monitor interval=5s
pcs -f vip_cfg constraint colocation add vip with drbd_devpath_master INFINITY with-rsc-role=Master
pcs -f vip_cfg constraint order promote drbd_devpath_master then start vip
pcs cluster cib-push vip_cfg --config
pcs resource enable vip
pcs cluster cib ipsrcaddr_cfg
pcs -f ipsrcaddr_cfg resource create src_pkt_ip ocf:heartbeat:IPsrcaddr ipaddress=$1 cidr_netmask=32 op monitor interval=5s
pcs -f ipsrcaddr_cfg constraint colocation add src_pkt_ip with vip INFINITY
pcs -f ipsrcaddr_cfg constraint order vip then src_pkt_ip
pcs cluster cib-push ipsrcaddr_cfg --config
pcs resource enable src_pkt_ip
pcs cluster cib datapath_fs_cfg
pcs -f datapath_fs_cfg resource create datapath_fs Filesystem device="/dev/drbd1" directory="/var/lib/pbx" fstype="xfs"
pcs -f datapath_fs_cfg constraint colocation add datapath_fs with drbd_devpath_master INFINITY with-rsc-role=Master
pcs -f datapath_fs_cfg constraint order promote drbd_devpath_master then start datapath_fs
pcs -f datapath_fs_cfg constraint colocation add datapath_fs with vip INFINITY
pcs cluster cib-push datapath_fs_cfg --config
pcs resource enable datapath_fs
pcs resource defaults resource-stickiness=100
pcs resource cleanup
pcs cluster cib pbx_cfg
pcs -f pbx_cfg resource create pbx ocf:portsip:pbx op monitor interval=10s
pcs  -f pbx_cfg constraint colocation add pbx with datapath_fs INFINITY
pcs  -f pbx_cfg constraint order datapath_fs then pbx
pcs cluster cib-push pbx_cfg --config
pcs resource enable pbx
}
create_pbx(){
pcs cluster cib pbx_cfg
pcs -f pbx_cfg resource create pbx ocf:portsip:pbx op monitor interval=10s
pcs  -f pbx_cfg constraint colocation add pbx with datapath_fs INFINITY
pcs  -f pbx_cfg constraint order datapath_fs then pbx
pcs cluster cib-push pbx_cfg --config
pcs resource enable pbx

}
init $1 $2
create $3
#create_pbx
