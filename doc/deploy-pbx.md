# 自动化安装pbx高可用
## 需要满足以下条件
>1主机名host解析,必须能够在任意的一个节点通过ping主机名能够通。 本文档以 192.168.1.11, 192.168.1.12, 192.168.1.13为例，假定他们的主机名分别为 pbx01, pbx02, pbx03。

>2、最少3台节点

>3、3台节点各需一块新硬盘，无需分区格式化操作，要求三个节点的新硬盘大小一致。或者每个节点各需一个新分区，新分区无需格式化操作，要求三个节点的新分区大小一致。新硬盘或者新分区里面不能有文件存在。
## 设置host解析
在每一个节点执行如下命令。**注：需要把下面的命令里的ip和主机名替换成你的主机名和ip**
```
cat <<EOF >>/etc/hosts
192.168.1.11 pbx01
192.168.1.12 pbx02
192.168.1.13 pbx03
EOF
```
## 设置免密钥登录
非常重要，非常重要，非常重要!
```
pbx02、pbx03分别是节点2和节点3 
一直输入回车即可
[root@pbx01 ~]# ssh-keygen -t rsa   
输入pbx02密码
[root@pbx01 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub pbx02
输入pbx03的密码
[root@pbx01 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub pbx03
#测试免密码登录
[root@pbx01 ~]# ssh pbx02 "w"
 14:14:20 up 8 min,  1 user,  load average: 0.00, 0.01, 0.02
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
root     pts/0    192.168.1.210    14:09    4:28   0.01s  0.01s -bash
[root@pbx01 ~]# 

```
## 自动安装pacemaker 和drbd
在master上操作就行
```
yum -y install git
git clone https://github.com/portsip/portsip-pbx-ha-guide.git
cd  portsip-pbx-ha-guide
执行pacemaker.sh 等待包安装完成后根据提示输入账号密码
./pacemaker.sh pbx02 pbx03
Username: hacluster
Password: 
输入用户 hacluster 密码123456
后安装完成后重启所以的节点，非常重要，非常重要，非常重要 
```
## linux lvm搭建配置
每一台节点都需要执行
```
yum install -y yum-utils device-mapper-persistent-data lvm2
pvcreate 你的硬盘名
vgcreate pbxvg 你的硬盘名
lvcreate -n pbxlv -L 128G pbxvg
挂载点为/dev/pbxvg/pbxlv，128G是大小，根据实际情况更改，如果你用lvm当drbd硬盘的话，使用/dev/pbxvg/pbxlv填写drbd配置文件中的disk既可。
```
## 配置drbd
只在master上面修改drbd的配置文件然后使用scp分发到各节点 pbx02、pbx03为节点二和节点三根据实际情况替换disk字段即可
```
发送全局配置文件到各节点
cp -f  ./global_common.conf /etc/drbd.d/
scp ./global_common.conf  pbx02:/etc/drbd.d/
scp ./global_common.conf  pbx03:/etc/drbd.d/
配置drbd
修改当前目录下pbxdata.res文件
resource pbxdata {

meta-disk internal;
device /dev/drbd1;
#disk /dev/pbxvg/pbxlv;
disk 你的硬盘或者分区;

syncer {
  verify-alg sha1;
}

net {
# allow-two-primaries no;
  after-sb-0pri discard-zero-changes;
  after-sb-1pri discard-secondary;
  after-sb-2pri disconnect;
}
#节点一名字和ip
on pbx01 {
  address pbx01ip:7789;
  node-id 0;
}
#节点二名字和ip
on pbx02 {
  address pbx02ip:7789;
  node-id 1;
}
#节点三名字和ip
on pbx03 {
  address pbx03ip:7789;
  node-id 2;
}

connection-mesh {
  #节点1、2、3名字
  hosts pbx01 pbx02 pbx03;
  net {
      use-rle no;
  }
}

}
需要注意的是，如果每台机器的分区不一样，需要拷贝之前修改disk字段注明pbx01ip、pbx02ip、pbx03ip需要修改成真实的ip
拷贝到本机
cp -f pbxdata.res /etc/drbd.d/
拷贝到pbx02
scp  pbxdata.res pbx02:/etc/drbd.d/
拷贝到pbx03
scp  pbxdata.res pbx03:/etc/drbd.d/
```
### 初始化drbd
```
所有节点启动drbd systemctl status drbd查看状态是否为running
systemctl start drbd
所有节点执行 
drbdadm create-md pbxdata
drbdadm up pbxdata
只在一台节点执行
drbdadm -- --clear-bitmap new-current-uuid pbxdata
drbdadm primary --force pbxdata
mkfs.xfs /dev/drbd1
drbdadm secondary pbxdatagit
```


## 配置pbx
其中pbx02 pbx03 分别是node2和node3
其中123456是PortSIP 数据库密码, 你可以自由地使用其他密码.
66.175.222.20是PBX 运行容器运行的 IP地址，如果运行在公网，那么此处需要指定公网IP，如果是内网，则指定内网IP, 在本例中，使用的 IP 是66.175.222.20, 你需要根据实际情况来修改该 IP.
如果因为拉镜像导致执行失败，当前步骤可以多次执行，直到成功
```json
./docker.sh pbx02 pbx03 66.175.222.20 123456 portsip/pbx:12
```
## 创建资源
在master上操作就行，如果不报错证明，安装成功。可通过./bin/pbx-status查看状态
```
./create_pacemaker_resources.sh  pbx02 pbx03  yourvip
```
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
其中pbx02 pbx03 分别是node2和node3
其中123456是PortSIP 数据库密码, 你可以自由地使用其他密码.
66.175.222.20是PBX 运行容器运行的 IP地址，如果运行在公网，那么此处需要指定公网IP，如果是内网，则指定内网IP, 在本例中，使用的 IP 是66.175.222.20, 你需要根据实际情况来修改该 IP
其中portsip/pbx:12是要更新的版本，你可以自由地使用其他版本。
如果因为拉镜像导致执行失败，次步骤可以多次执行
```
./bin/pbx-update pbx02 pbx03 66.175.222.20 123456 portsip/pbx:12
```
