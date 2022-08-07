# 目录
[TOC]

# 简介

为了提供高服务器的性能和高可用性，PortSIP PBX 支持将媒体服务器从 PBX 服务器剥离，单独部署在其他服务器上进行扩展。

本文提供扩展安装媒体服务器的步骤指南。

假定我们扩展安装三台媒体服务器， 该三台媒体服务器的主机名和 IP 设置为如下:

```
192.168.78.201 media01
192.168.78.202 media02
192.168.78.203 media03
```



硬盘大小推荐最小为100G，无需额外的数据盘。

**操作系统的版本和安装必须和 PBX 服务器操作系统一致（无需额外分配数据盘）。**



首先请确认已经按照手册将 PBX HA 集群安装完毕。



# 设置免密码登录

**设置媒体服务器免密码登录（只需在节点 pbx01上执行）：**

```shell

// 根据提示输入密码，如果出现（yes/no）?,需要输入yes
[root@pbx01 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub 192.168.78.201
[root@pbx01 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub 192.168.78.202
[root@pbx01 ~]# ssh-copy-id -i ~/.ssh/id_rsa.pub 192.168.78.203
```


# 安装

## 配置媒体服务器

1. 通过浏览器打开 PBX 配置界面： http://192.168.78.90:8888，这里的 IP 是 PBX HA 集群的虚拟IP。输入用户名和密码: admin/admin。

2. 打开菜单 `Advanced  -> Media Server`，点击按钮将默认服务器禁用。

   ![](../images/8B94C25A-64BA-46f6-B42A-22A724B78FE6.png)


3. 点击 "Add" 按钮，按照如下截图输入扩展媒体服务器的信息，如果服务器没有公网 IP， 请将内网 IP 作为公网 IP 输入。如果服务器没有内网 IP， 请将公网 IP 作为内网 IP 输入。

   ![](../images/E678CF1B-123C-4611-9264-0A973A7590E8.png)


4. 依次将 `media02` 和 `media03` 服务器配置完成。

   配置成功后，在媒体服务器列表界面，这三台服务器显示为 `offline` 状态。

## 安装服务

只在主节点也就是`节点 pbx01` 依次执行如下命令（执行过程可能较长，耐心等待即可，中途不要中断、重启或者关机）：

```shell
[root@pbx01 ~]# cd /root/portsip-pbx-ha-guide/ && /bin/sh install_ext_media.sh 192.168.78.201
[root@pbx01 ~]# cd /root/portsip-pbx-ha-guide/ && /bin/sh install_ext_media.sh 192.168.78.202
[root@pbx01 ~]# cd /root/portsip-pbx-ha-guide/ && /bin/sh install_ext_media.sh 192.168.78.203
```

安装成功后，刷新会议服务器列表界面，这三台服务器应该显示为 `online` 状态。
