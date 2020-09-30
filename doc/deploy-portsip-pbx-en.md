# Deploying PortSIP PBX HA

- [Architecture](#Architecture-diagram)
- [Prerequisites](#Prerequisites)
- [Resolving to the host name](#Resolving-to-the-host-name)
- [Setting up password-free SSH login](#Setting-up-password-free-SSH-login)
- [Installing pacemaker and drbd automatically](#Installing-pacemaker-and-drbd-automatically)
- [Configuring the Linux lvm](#Configuring-the-Linux-lvm)
- [Configuring DRBD](#Configuring-DRBD)
- [Initializingthe DRBD](#Initializing-the-DRBD)
- [Configuring PBX](#Configuring-PBX)
- [Creating resources](#Creating-resources)
- [Frequently used commands](#Frequently-used-commands)
  - [Checking PBX status](#Checking-PBX-status)
  - [Restarting pbx](#Restarting-pbx)
  - [Updating pbx](#Updating-pbx)



PortSIP PBX enables HA deployment, which is typically implemented with three servers (Physical machine or Virtual machine). When one of the PBX servers is down, the registrations and calls on this PBX server will be restored on another server automatically.

With the HA mode, the PBX uses virtual IP to provide the service to client, and the client App/IP Phone registers to the PBX and makes call(s) with the PBX by using this virtual IP.



## Architecture

![pbx](pbx.png)
## Prerequisites
> 1. Must be started with a minimum of three PBX nodes

> 2. The OS should be: CentOS 7.6, 64 bit.

> 3. Must resolve three PBX nodes host name to the IP, so that each host should can be pinged from other nodes. In this guide, we assume the node IPs are 192.168.1.11, 192.168.1.12, 192.168.1.13 and the host names are pbx01, pbx02, pbx03.

> 4. Each node needs a new disk or a new disk partition , no formatting required. The disk or disk partition **size should be same**. Do not put any files into the disk / disk partition.
## Resolving to the host name
Execute below command on each node. **Note: the IP and host name must be replaced with your IP address and host name**
```
cat <<EOF >>/etc/hosts
192.168.1.11 pbx01
192.168.1.12 pbx02
192.168.1.13 pbx03
EOF
```
## Setting up password-free SSH login
**This step is very important!**

We assuming the host name pbx01, pbx02、pbx03 is the node 1, node 2, node 3.

Perform below commands on pbx01, enter necessary information according the prompts:

```
[root@pbx01 ~]# ssh-keygen -t rsa 
```

Setup password-free SSH login on pbx02：

```
[root@pbx01 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub pbx02
```

Setup password-free SSH login on pbx03：

```
[root@pbx01 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub pbx03
```

Test password-free SSH login on pbx02:

```
[root@pbx01 ~]# ssh pbx02 "w"
 14:14:20 up 8 min,  1 user,  load average: 0.00, 0.01, 0.02
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
root     pts/0    192.168.1.210    14:09    4:28   0.01s  0.01s -bash
[root@pbx01 ~]# 
```

Test password-free SSH login on pbx03:

```
[root@pbx01 ~]# ssh pbx03 "w"
 14:14:20 up 8 min,  1 user,  load average: 0.00, 0.01, 0.02
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
root     pts/0    192.168.1.210    14:09    4:28   0.01s  0.01s -bash
[root@pbx01 ~]# 
```



## Installing pacemaker and drbd automatically

Set pbx01 as master, and perform below commands on it:

```
yum -y install git
git clone https://github.com/portsip/portsip-pbx-ha-guide.git
cd  portsip-pbx-ha-guide
```

Now execute **pacemaker.sh**. Once the installation completes, enter the username and password as prompted:

```
./pacemaker.sh pbx02 pbx03
Username: hacluster
Password: 
```

Enter username **hacluster** and password **123456**. Once the installation completes, perform below command one by one to restart all nodes:
```
ssh pbx02 "reboot"
ssh pbx03 "reboot"
reboot
```


## Configuring the Linux lvm
Perform below command  on each pbx node to show the disk name or disk partition name and note them down:

```
fdisk -l
```

Perform below commands on each PBX node (Note: The disk name **/dev/sdb** should be replaced with your actual disk name or disk partition name):

```
yum install -y yum-utils device-mapper-persistent-data lvm2
pvcreate /dev/sdb
vgcreate pbxvg /dev/sdb
lvcreate -n pbxlv -L 128G pbxvg
```

In above commands, the mount point is /dev/pbxvg/pbxlv ( **do not change it**), and disk / disk partition size is 128G. **Please change the size to actual disk / disk partition size.**



## Configuring DRBD
Modify the DRBD configuration on master node (in this case it is the pbx01) and send to other nodes by using scp.

Send the global configuration file to other nodes:

```
cp -f  ./global_common.conf /etc/drbd.d/
scp ./global_common.conf  pbx02:/etc/drbd.d/
scp ./global_common.conf  pbx03:/etc/drbd.d/
```



Modify the **pbxdata.res** in current path:

```
resource pbxdata {

meta-disk internal;
device /dev/drbd1;
disk /dev/pbxvg/pbxlv;

syncer {
  verify-alg sha1;
}

net {
# allow-two-primaries no;
  after-sb-0pri discard-zero-changes;
  after-sb-1pri discard-secondary;
  after-sb-2pri disconnect;
}
# node 1 
on pbx01 {
  address pbx01ip:7789;
  node-id 0;
}
# node 2
on pbx02 {
  address pbx02ip:7789;
  node-id 1;
}
# node 3
on pbx03 {
  address pbx03ip:7789;
  node-id 2;
}

connection-mesh {
  # the host name of node 1, node 2, node 3
  hosts pbx01 pbx02 pbx03;
  net {
      use-rle no;
  }
}

}
```

Copy to local host

```
cp -f pbxdata.res /etc/drbd.d/
```
Copy to pbx02

```
scp  pbxdata.res pbx02:/etc/drbd.d/
```

Copy to pbx03

```
scp  pbxdata.res pbx03:/etc/drbd.d/
```



### Initializing the DRBD

Start the DRBD on each node by executing below command:

```
systemctl start drbd
```

Check if the DRBD status on each node is running:

```
systemctl status drbd
```

Perform below commands on each node:

```
drbdadm create-md pbxdata
drbdadm down pbxdata && drbdadm up pbxdata
```

Perform below command **on master only,  i.e. pbx01:**

```
drbdadm -- --clear-bitmap new-current-uuid pbxdata
drbdadm primary --force pbxdata
mkfs.xfs /dev/drbd1
drbdadm secondary pbxdata
```




## Configuring PBX
When configuring the PBX HA , we will need a virtual IP for accessing the PBX cluster, and the virtual IP must not be used by other machines.

In below commands, **we assume use 192.168.1.100 for virtual IP.**

The 123456 is he PBX DB password, the pbx02 and pbx03 is the host name of node1, node2.

If it fails in this step, repeat below command until successful execution.

```json
./docker.sh pbx02 pbx03 192.168.1.100 123456 portsip/pbx:12
```
## Creating resources
Perform below commands on master node (In this case it is the pbx01). No error appeared indicates that you have successfully configured the PortSIP PBX HA.

The 192.168.1.100 is the virtual IP you use.

You can use **./bin/pbx-status** to view the status.

```
./create_pacemaker_resources.sh  pbx02 pbx03  192.168.1.100
```

Now you can use your browser to visit http://192.168.1.100:8888 or https://192.168.1.100:8887 to configure your PBX.



# Frequently used commands

## Checking PBX status
```
./bin/pbx-status
```
## Restarting PBX

```
./bin/pbx-restart
```
## Updating PBX
In this case the pbx02 is node2, and pbx 03 is node3.
The 123456 is password for PortSIP PBX DB, you can use other words as your password.
The **portsip/pbx:12** is the new version to be updated to.

The 192.168.1.100 is the virtual IP you used.

If you fail this step, you can repeat below command until success.

Perform below command on pbx01:

```
./bin/pbx-update pbx02 pbx03 192.168.1.100 123456 portsip/pbx:12
```

