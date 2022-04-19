## Prerequisite


- The `PortSIP PBX HA` has been successfully deployed as [HA guide](https://github.com/portsip/portsip-pbx-ha-guide/blob/master/doc)

- Stop `PBX` service

    Only perform the commands below on the master node. `pbx01`：

    ```shell
    pcs resource disable pbx
    ```

- Back kup the `PBX` data
  
    Show the master node infomation of `PBX HA`:

    ```shell
   pcs status |  grep Masters
    ```
    
    The command above will reveal the master node, all that is required is a backup of the master node's `/var/lib/pbx/portsip` folder.

## Add new disk volume

Add a new disk to each `HA` node; the disks must be the same size, have the same path, and be empty and formatted.
<br/>

- Example

  ```
  disk size：10G
  path：/dev/sdc
  ```

- Clean disk

  **This is a risky step; the most important thing is to replace the disk path to the actual disk path!!!**

When performing the command below, the disk path `/dev/sdc` must be replaced with the real disk path.
In each `PBX HA` node, perform the following command:

  ```shell
  dd bs=64k if=/dev/zero of=/dev/sdc
  ```

## Download the patch

Only perform the command below on node `pbx01`:

```shell
cd portsip-pbx-ha-guide 

wget https://www.portsip.com/downloads/ha/lan/portsip-pbx-ha-guide-12.extend_disk.tar.gz

tar xf portsip-pbx-ha-guide-12.extend_disk.tar.gz
```

## Set up variables

| Variable name           | Type   | Description                                                         |
| ---------------- | ------ | ------------------------------------------------------------ |
| new_disk         | String | The new disk path, in this case is `/dev/sdc`, must be changed to the real disk path.                 |
| new_disk_size_MB | Integer   | Size of the new disk, should be M, in this case, the size is 10000<br>**Note:** the 1000 means 1GB |

**Important**: Replace `new_disk` and `new_disk_size_MB` with their actual values when performing the below commands.

In the `pbx01` node, perform the commands following.：

```shell
cat <<EOF >/root/portsip-pbx-ha-guide/vars_extend_disk.yml
new_disk: /dev/sdc
new_disk_size_MB: 10000
EOF
```

## Extend

Perform the below commands in the node `pbx01` ：

```shell
cd /root/portsip-pbx-ha-guide && ansible-playbook extend_disk.yml
```

## Restart

Perform the below commands in the node `pbx01` ：

```shell
ssh pbx03 "reboot"

ssh pbx02 "reboot"

reboot
```

