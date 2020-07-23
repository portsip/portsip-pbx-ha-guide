#!/bin/bash
init(){
	systemctl stop firewalld.service
	systemctl disable firewalld.service
	setenforce 0
	ssh $1 "setenforce 0"
	ssh $2 "setenforce 0"
	ssh $1 "systemctl stop firewalld.service && systemctl disable firewalld.service"
	ssh $2 "systemctl stop firewalld.service && systemctl disable firewalld.service"
	sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
	sed -i 's#SELINUX=permissive#SELINUX=disabled#g' /etc/selinux/config
	ssh $1 "sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config"
	ssh $2 "sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config"
	ssh $1 "sed -i 's#SELINUX=permissive#SELINUX=disabled#g' /etc/selinux/config"
	ssh $2 "sed -i 's#SELINUX=permissive#SELINUX=disabled#g' /etc/selinux/config"

}
init $1 $2
install_pacemaker(){
      yum -y install pacemaker pcs
      systemctl start pcsd
      systemctl enable pcsd
      ssh $1 "yum -y install pacemaker pcs && systemctl start pcsd && systemctl enable pcsd"
      ssh $2 "yum -y install pacemaker pcs && systemctl start pcsd && systemctl enable pcsd"
}
install_pacemaker $1 $2


set_pacemaker_user(){
	echo "123456"|passwd --stdin hacluster
        ssh $1 "echo "123456"|passwd --stdin hacluster"
        ssh $2 "echo "123456"|passwd --stdin hacluster"
        mkdir -p /usr/lib/heartbeat/
        rm -rf /usr/lib/heartbeat/*
        cp -f /usr/lib/ocf/lib/heartbeat/* /usr/lib/heartbeat/
        ssh $1 "mkdir -p /usr/lib/heartbeat/ && rm -rf /usr/lib/heartbeat/* && cp -f /usr/lib/ocf/lib/heartbeat/* /usr/lib/heartbeat/"
     	ssh $2 "mkdir -p /usr/lib/heartbeat/ && rm -rf /usr/lib/heartbeat/* && cp -f /usr/lib/ocf/lib/heartbeat/* /usr/lib/heartbeat/"
}
install_drbd(){
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org ; rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm ; yum install -y kmod-drbd90 drbd90-utils;systemctl start drbd;systemctl enable drbd
        ssh $1 "rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org ; rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm ; yum install -y kmod-drbd90 drbd90-utils;systemctl start drbd;systemctl enable drbd"
        ssh $2 "rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org ; rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm ; yum install -y kmod-drbd90 drbd90-utils;systemctl start drbd;systemctl enable drbd"
	echo "drbd" >/etc/modules-load.d/drbd.conf;echo "drbd_transport_tcp" >>/etc/modules-load.d/drbd.conf
	ssh $1 "echo "drbd" >/etc/modules-load.d/drbd.conf;echo "drbd_transport_tcp" >>/etc/modules-load.d/drbd.conf"
        ssh $2 "echo "drbd" >/etc/modules-load.d/drbd.conf;echo "drbd_transport_tcp" >>/etc/modules-load.d/drbd.conf"
	mkdir -p /var/lib/pbx
        ssh $1 "mkdir -p /var/lib/pbx"
        ssh $2 "mkdir -p /var/lib/pbx"
}
install_docker(){
  sudo yum install -y yum-utils device-mapper-persistent-data lvm2
  sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
  sudo yum makecache fast
  sudo yum -y install docker-ce
  systemctl start docker
  systemctl enable docker
  ssh $1 "yum install -y yum-utils device-mapper-persistent-data lvm2"
  ssh $1 "yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"
  ssh $1 "yum makecache fast"
  ssh $1 "yum -y install docker-ce"
  ssh $1 "systemctl start docker"
  ssh $1 "systemctl enable docker"
  ssh $2 "yum install -y yum-utils device-mapper-persistent-data lvm2"
  ssh $2 "yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo"
  ssh $2 "yum makecache fast"
  ssh $2 "yum -y install docker-ce"
  ssh $2 "systemctl start docker"
  ssh $2 "systemctl enable docker"
}

set_pacemaker_user $1 $2
pcs cluster auth `hostname` $1 $2
pcs cluster setup --name ha_cluster `hostname` $1 $2
pcs cluster start --all
pcs cluster enable --all
pcs property set stonith-enabled=false
install_drbd $1 $2

