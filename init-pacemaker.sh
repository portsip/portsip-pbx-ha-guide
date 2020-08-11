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
set_pacemaker_user $1 $2
pcs cluster auth `hostname` $1 $2
pcs cluster setup --name ha_cluster `hostname` $1 $2
pcs cluster start --all
pcs cluster enable --all
pcs property set stonith-enabled=false