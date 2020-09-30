#/bin/bash
init(){
    sed -i 's#keepcache=0#keepcache=1#g' /etc/yum.conf
    rm -rf /var/cache/yum && tar xf yum.tar.gz && mv yum /var/cache/
    if [ $? -ne 0 ];then
    echo "init error "
    exit 1
    fi
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    setenforce 0
    sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
    sed -i 's#SELINUX=permissive#SELINUX=disabled#g' /etc/selinux/config
}
install_pacemaker(){
      yum -y -C install pacemaker pcs
      systemctl start pcsd
      systemctl enable pcsd
}

install_drbd(){
    rpm --import ./RPM-GPG-KEY-elrepo.org
    rpm -Uvh elrepo-release-7.el7.elrepo.noarch.rpm
     if [ $? -ne 0 ];then
    echo "import rpm error"
    exit 1
    fi
    yum install -C  -y kmod-drbd90 drbd90-utils
}
install_docker(){
    tar -xf docker.tar.gz
    cp ./docker/* /usr/bin/
    cp ./docker/docker.service /etc/systemd/system/
    chmod +x /etc/systemd/system/docker.service
    systemctl daemon-reload
    systemctl start docker
    systemctl enable docker.service
    docker -v
    if [ $? -ne 0 ];then
    echo "install docker error"
    exit 1
    fi
}
import_docker_image(){
    tar xf pbx.tar.gz.gz
    docker load < pbx.tar.gz
    if [ $? -ne 0 ];then
    echo "import error"
    fi
}

init
if [ $? -ne 0 ];then
exit 1
fi


install_pacemaker
if [ $? -ne 0 ];then
exit 1
fi
install_drbd
if [ $? -ne 0 ];then
exit 1
fi
install_docker
if [ $? -ne 0 ];then
exit 1
fi
import_docker_image
if [ $? -ne 0 ];then
exit 1
fi
