## 前提


- 根据[HA部署手册](https://github.com/portsip/portsip-pbx-ha-guide/blob/master/doc)，已经成功部署高可用(`HA`)的`PortSIP PBX`

- 停止`PBX`服务

    仅在`pbx01`中执行如下命令：

    ```shell
    pcs resource disable pbx
    ```

- **备份**整个`PBX`数据目录
  
  **由于扩展磁盘存在不可靠的因素，为了数据的安全性，请进行备份。**

    获取`HA`当前的主节点：

    ```shell
    pcs status |  grep Masters
    ```
    
    数据目录在主节点目录`/var/lib/pbx/portsip`中。

## 新增存储卷

所有`HA`节点（不包含扩展的节点，例如扩展的media节点）各新增一块磁盘，要求相同大小、相同盘符、清零新的硬盘。<br/>

- 示例

  ```
  硬盘大小为：10G
  盘符为：/dev/sdc
  ```

- 硬盘清零

  **此步骤需要非常注意，必须根据实际情况调整盘符，否则会出现不可逆的异常状态。**

  **此步骤需要非常注意，必须根据实际情况调整盘符，否则会出现不可逆的异常状态。**

  **此步骤需要非常注意，必须根据实际情况调整盘符，否则会出现不可逆的异常状态。**

  当前示例盘符为 `/dev/sdc`，**必须**根据实际情况调整如下命令中的盘符信息，如下命令在`HA`中的所有节点分别执行：

  ```shell
  dd bs=64k if=/dev/zero of=/dev/sdc
  ```

## 下载补丁

只在`节点 pbx01` 执行如下命令：

```shell
cd portsip-pbx-ha-guide 

wget http://www.portsip.cn/downloads/ha/portsip-pbx-ha-guide-12.extend_disk.tar.gz

tar xf portsip-pbx-ha-guide-12.extend_disk.tar.gz
```

## 设置变量

| 参数名           | 类型   | 说明                                                         |
| ---------------- | ------ | ------------------------------------------------------------ |
| new_disk         | 字符串 | 新增硬盘的盘符，当前示例为：`/dev/sdc`                       |
| new_disk_size_MB | 数值   | 新增硬盘大小，单位为M，当前示例为：10000<br>**注意**当前采用 `1G = 1000M` 处理 |

**注意把相关信息改为自己真实的信息**

只在`节点 pbx01` 执行如下命令：

```shell
cat <<EOF >/root/portsip-pbx-ha-guide/vars_extend_disk.yml
new_disk: /dev/sdc
new_disk_size_MB: 10000
EOF
```

## 扩展

只在`节点 pbx01` 执行如下命令：

```shell
cd /root/portsip-pbx-ha-guide && ansible-playbook extend_disk.yaml
```

## 重启

只在`节点 pbx01` 执行如下命令：

```shell
ssh pbx03 "reboot"

ssh pbx02 "reboot"

reboot
```

