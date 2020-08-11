#/bin/bash
init(){
    sed -i 's#keepcache=0#keepcache=1#g' /etc/yum.conf
    rm -rf /var/cache/yum && tar xf yum.tar.gz && mv yum /var/cache/
    systemctl stop firewalld.service
	systemctl disable firewalld.service
	setenforce 0
    sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
	sed -i 's#SELINUX=permissive#SELINUX=disabled#g' /etc/selinux/config
}
install_pacemaker(){
      yum -y install pacemaker pcs
      systemctl start pcsd
      systemctl enable pcsd
}

install_drbd()){
    rpm --import RPM-GPG-KEY-elrepo.org
    rpm -Uvh elrepo-release-7.0-4.el7.elrepo.noarch.rpm
    yum install -y kmod-drbd90 drbd90-utils;systemctl start drbd
}
install_docker(){
    echo '解压tar包...'
    tar -xf docker.tar.gx
    cp ./* /usr/bin/
    cp docker.service /etc/systemd/system/
    chmod +x /etc/systemd/system/docker.service
    systemctl daemon-reload
    systemctl start docker
    systemctl enable docker.service
    docker -v
}
import_docker_image(){
    tar xf pbx.tar.gz.gz
    docker load < pbx.tar.gz
}
