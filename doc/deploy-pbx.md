# 自动化安装pbx高可用
## 需要满足以下条件
>1主机名host解析,必须能够在任意的一个节点通过ping主机名能够通

>2、最少3台节点

>3、3台节点需要3快新的硬盘，无需分区格式化操作
## 设置host解析
所有节点执行,把下面的ip和主机名替换成，你的真实主机名和ip
```
cat <<EOF >>/etc/hosts
127.0.0.1 ptest01
127.0.0.1 ptest02
127.0.0.1 ptest03
EOF
```
## 设置免密钥登录
非常重要，非常重要，非常重要
```
ptest02、ptest03分别是节点2和节点3 
[root@ptest01 ~]# ssh-keygen -t rsa
[root@ptest01 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub ptest02
[root@ptest01 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub ptest03
#测试免密码登录
[root@ptest01 ~]# ssh ptest02 "w"
 14:14:20 up 8 min,  1 user,  load average: 0.00, 0.01, 0.02
USER     TTY      FROM             LOGIN@   IDLE   JCPU   PCPU WHAT
root     pts/0    192.168.1.210    14:09    4:28   0.01s  0.01s -bash
[root@ptest01 ~]# 

```
## 自动安装pacemaker 和drbd
在master上操作就行
```
yum -y install git
git clone https://github.com/portsip/portsip-pbx-ha-guide.git
cd  portsip-pbx-ha-guide
执行pacemaker.sh 等待包安装完成后根据提示输入账号密码
./pacemaker.sh ptest02 ptest03
Username: hacluster
Password: 
输入用户 hacluster 密码123456
后安装完成后重启所以的节点，非常重要，非常重要，非常重要 
```
## linux lvm搭建配置
当前步骤是可选择的，不想使用lvm，跳过即可，如果你想用lvm来替代你的硬盘或者分区，可以参考。
```
yum install -y yum-utils device-mapper-persistent-data lvm2
pvcreate 你的硬盘名
vgcreate pbxvg 你的硬盘名
lvcreate -n pbxlv -L 128G pbxvg
挂载点为/dev/pbxvg/pbxlv，如果你用lvm当drbd硬盘的话，使用/dev/pbxvg/pbxlv填写drbd配置文件中的disk既可。
```
## 配置drbd
只在master上面修改drbd的配置文件然后使用scp分发到各节点 ptest02、ptest03为节点二和节点三根据实际情况替换disk字段即可
```
发送全局配置文件到各节点
cp -f  ./global_common.conf /etc/drbd.d/
scp ./global_common.conf  ptest02:/etc/drbd.d/
scp ./global_common.conf  ptest02:/etc/drbd.d/
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

on ptest01 {
  address ptest01ip:7789;
  node-id 0;
}

on ptest02 {
  address ptest02ip:7789;
  node-id 1;
}

on ptest03 {
  address ptest03ip:7789;
  node-id 2;
}

connection-mesh {
  hosts ptest01 ptest02 ptest03;
  net {
      use-rle no;
  }
}

}
需要注意的是，如果每台机器的分区不一样，需要拷贝之前修改disk字段注明ptest01ip、ptest02ip、ptest03ip需要修改成真实的ip
拷贝到本机
cp -f pbxdata.res /etc/drbd.d/
拷贝到ptest02
scp  pbxdata.res ptest02:/etc/drbd.d/
拷贝到ptest03
scp  pbxdata.res ptest03:/etc/drbd.d/
```
### 初始化drbd
ptest02 ptest03 node2和node3
```
./drbd_init.sh ptest02 ptest03
查看状态如下,就可以执行下面操作了，如果报错，需要检查drbd的配置是否正确
[root@pptest02 portsip-pbx-ha-guide]# drbdadm status
pbxdata1 role:Secondary
  disk:UpToDate
  pptest01 role:Secondary
    peer-disk:UpToDate
  pptest03 role:Secondary
    peer-disk:UpToDate
```


## 配置pbx
其中ptest02 ptest03 分别是node2和node3
其中123456是PortSIP 数据库密码, 你可以自由地使用其他密码.
66.175.222.20是PBX 运行容器运行的 IP地址，如果运行在公网，那么此处需要指定公网IP，如果是内网，则指定内网IP, 在本例中，使用的 IP 是66.175.222.20, 你需要根据实际情况来修改该 IP.
如果因为拉镜像导致执行失败，当前步骤可以多次执行，直到成功
```json
./docker.sh ptest02 ptest03 66.175.222.20 123456 portsip/pbx:12
```
## 创建资源
在master上操作就行，如果不报错证明，安装成功。可通过./bin/pbx-status查看状态
```
./create_pacemaker_resources.sh  ptest02 ptest03  yourvip
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
其中ptest02 ptest03 分别是node2和node3
其中123456是PortSIP 数据库密码, 你可以自由地使用其他密码.
66.175.222.20是PBX 运行容器运行的 IP地址，如果运行在公网，那么此处需要指定公网IP，如果是内网，则指定内网IP, 在本例中，使用的 IP 是66.175.222.20, 你需要根据实际情况来修改该 IP
其中portsip/pbx:12是要更新的版本，你可以自由地使用其他版本。
如果因为拉镜像导致执行失败，次步骤可以多次执行
```
./bin/pbx-update ptest02 ptest03 66.175.222.20 123456 portsip/pbx:12
```
