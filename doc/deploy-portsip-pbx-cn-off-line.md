# 准备离线资源(所有节点)
**上传git资源包，通过git下载并解压**

```
portsip-pbx-ha-guide
```

**注意需要把下面文件上传到portsip-pbx-ha-guide目录中**
```
docker.tar.gz

elrepo-release-7.el7.elrepo.noarch.rpm


pbx.tar.gz.gz

RPM-GPG-KEY-elrepo.org

yum.tar.gz

# 执行portsip-pbx-ha-guide目录下的install-off-line.sh
/bin/bash install-off-line.sh
```
# 先决条件

> 1. 至少 3 台节点

> 2. 操作系统：CentOS 7.6，须是 64 位系统。

>3. 必须设置每个节点的主机名 host 解析，要求必须能够 ping 通任一节点的主机名。 本文档以 192.168.1.11, 192.168.1.12, 192.168.1.13为例，假定他们的主机名分别为 pbx01, pbx02, pbx03。

>4. 3 台节点各需一块新硬盘，无需分区格式化操作，要求三个节点的新硬盘大小一致。或者每个节点各需一个新分区，新分区无需格式化操作，要求三个节点的新分区大小一致。新硬盘或者新分区里面不能有文件存在。

# 设置 host 解析
在每一个节点执行如下命令。**注意：需要把下面的命令里的 IP 和主机名替换成你的主机名和 IP**

```
cat <<EOF >>/etc/hosts
192.168.1.11 pbx01
192.168.1.12 pbx02
192.168.1.13 pbx03
EOF
```

# 设置免密码登录
本例中，pbx01, pbx02、pbx03分别是节点1、节点2和节点3。
本例在节点 pbx01 上执行如下命令，并按照提示生成证书：

```

[root@pbx01 ~]# ssh-keygen -t rsa 
```

设置 pbx02 免密码登录：

```
[root@pbx01 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub pbx02
```

设置 pbx03 免密码登录：

```
[root@pbx01 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub pbx03
```

测试 pbx02 免密码登录：

```
[root@pbx01 ~]# ssh pbx02 "w"
 14:14:20 up 8 min,  1 user,  load average: 0.00, 0.01, 0.02
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
root     pts/0    192.168.1.210    14:09    4:28   0.01s  0.01s -bash
[root@pbx01 ~]# 
```

测试 pbx03 免密码登录：

```
[root@pbx01 ~]# ssh pbx03 "w"
 14:14:20 up 8 min,  1 user,  load average: 0.00, 0.01, 0.02
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
root     pts/0    192.168.1.210    14:09    4:28   0.01s  0.01s -bash
[root@pbx01 ~]# 
```

# 配置pacemaker集群**只在master执行**


/bin/bash init-pacemaker.sh pbx02 pbx03

# 重启所有节点

```
ssh pbx02 "reboot"
ssh pbx03 "reboot"
reboot
```
# 配置 Linux lvm
在每一节点上分别执行如下命令查看 HA 要使用的硬盘名或者分区名，并记录下来：

```
fdisk -l
```

在每一台节点上分别执行如下命令：

```
yum install -y yum-utils device-mapper-persistent-data lvm2
pvcreate 该节点的硬盘名或者分区名
vgcreate pbxvg 该节点的硬盘名或者分区名
lvcreate -n pbxlv -L 128G pbxvg
```

上述命令中，挂载点为 **/dev/pbxvg/pbxlv**，128G分区大小，需要更改为您的硬盘或者分区大小。



# 配置 DRBD
以下操作只需在 master 节点上进行，本例中为 pbx01。

在 master 上修改 DRBD 的配置文件然后使用 scp 分发到各节点。

发送全局配置文件到各节点:

```
**注意后面的演示命令都是portsip-pbx-ha-guide下执行**
cd portsip-pbx-ha-guide
cp -f  ./global_common.conf /etc/drbd.d/
scp ./global_common.conf  pbx02:/etc/drbd.d/
scp ./global_common.conf  pbx03:/etc/drbd.d/
```

接着在 master 上配置 DRBD，修改当前目录下 pbxdata.res 文件：
```
sed -i 's#pbx01#your-host-name1#g' pbxdata.res
sed -i 's#pbx02#your-host-name2#g' pbxdata.res
sed -i 's#pbx03#your-host-name2#g' pbxdata.res
```

拷贝到本机

```
cp -f pbxdata.res /etc/drbd.d/
```
拷贝到 pbx02

```
scp  pbxdata.res pbx02:/etc/drbd.d/
```

拷贝到 pbx03

```
scp  pbxdata.res pbx03:/etc/drbd.d/
```



# 初始化 DRBD

在每个节点上都执行如下命令启动 DRBD：

```
systemctl start drbd
```

在每个节点上都查看 DRBD状态是否是 running。

```
systemctl status drbd
```

在每个节点上都执行如下命令：

```
drbdadm create-md pbxdata
```

只需 **master** 也就是 **pbx01** 上执行如下命令:

```
drbdadm -- --clear-bitmap new-current-uuid pbxdata
drbdadm primary --force pbxdata
mkfs.xfs /dev/drbd1
drbdadm secondary pbxdata
```

# 配置 PBX
部署 PortSIP PBX 为 HA 模式的时候，我们需要一个 Virtual IP 来用代表 PBX 让外部访问，这个 Virtual IP 必须没有被其他的机器所使用，本例中我们使用 **192.168.1.100** 作为 Virtual IP。在实际部署场景中，您需要根据您的网络情况来选中一个合适的 IP 作为 Virtual IP。

如下命令中，pbx02、pbx03 分别是 node2 和 node3。
其中123456是PortSIP 数据库密码, 您也可以设置使用其他密码.
如果因为拉镜像导致执行失败，当前步骤可以多次执行，直到成功。

```json
./docker.sh pbx02 pbx03 192.168.1.100 123456 portsip/pbx:12
```

# 创建资源
在master 也就是 pbx01上执行如下操作，如果不报错证明安装成功。可通过 ./bin/pbx-status查看状态。

命令中的 192.168.1.100 是本例的 Virtual IP, 您需要替换为您的实际 Virtual IP。

```
./create_pacemaker_resources.sh  pbx02 pbx03  192.168.1.100
```

现在您可以使用浏览器打开 http://192.168.1.100:8888 或者  https://192.168.1.100:8887 来配置您的 PBX。



# 几个常用的命令

## 查看pbx状态
```
./bin/pbx-status
```
## 重启pbx

```
./bin/pbx-restart
```
## 更新pbx
本例中的 pbx02、pbx03 分别是 node2 和 node3。
其中 **123456** 是 PortSIP 数据库密码,  您也可以设置使用其他密码。
其中 **portsip/pbx:12** 是要更新的版本，您可以自由地使用其他版本。

如果因为拉镜像导致执行失败，本步骤可以多次执行直到成功。
命令中的 192.168.1.100 是本例的 Virtual IP, 您需要替换为您的实际 Virtual IP。

```
./bin/pbx-update pbx02 pbx03 192.168.1.100 123456 portsip/pbx:12
```





