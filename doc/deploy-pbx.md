# 自动化安装pacemaker
主机名host解析,必须能够在任意的一个节点通过ping主机名能够通。
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
安装完成后重启，非常重要，非常重要，非常重要 在master上操作就行
```
git clone https://github.com/portsip/portsip-pbx-ha-guide.git
cd  portsip-pbx-ha-guide
执行pacemaker.sh 等待包安装完成后根据提示输入账号密码
./pacemaker.sh ptest02 ptest03
Username: hacluster
Password: 
输入用户 hacluster 密码123456
```

## 配置drbd
只在master上面修改drbd的配置文件然后使用scp分发到各节点 ptest02、ptest03为节点二和节点三根据实际情况替换
```
发送全局的配置文件到各节点
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
需要注意的是，如果每台机器的分区不一样，需要拷贝之前修改disk字段注明
拷贝到本机
cp -f pbxdata.res /etc/drbd.d/
拷贝到ptest02
scp  pbxdata.res ptest02:/etc/drbd.d/
拷贝到ptest03
scp  pbxdata.res ptest03:/etc/drbd.d/
```


## 配置pbx
所有节点

```json
sudo mkdir -p /var/lib/pbx/portsip
sudo docker container run -d --name pbx --network=host -v /var/lib/pbx/portsip:/var/lib/portsip -v /etc/localtime:/etc/localtime:ro  -e POSTGRES_PASSWORD=123456 -e POSTGRES_LISTEN_ADDRESSES="*,127.0.0.1" -e IP_ADDRESS="192.168.1.130"  portsip/pbx:12
...等待30s
$ sudo docker stop -t 30 pbx
$ sudo drbdadm status pbxdata
...等待drbd同步完成
```
## 创建资源
在master上操作就行
```
./create_pacemaker_resources.sh  ptest02 ptest03  yourvip
```