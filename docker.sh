sudo docker container run -d --name pbx --network=host -v /var/lib/pbx/portsip:/var/lib/portsip -v /etc/localtime:/etc/localtime:ro  -e POSTGRES_PASSWORD=$4 -e POSTGRES_LISTEN_ADDRESSES="*,127.0.0.1" -e IP_ADDRESS="$3"  $5
sudo docker stop -t 30 pbx
mkdir -p /var/lib/pbx/portsip
ssh $1 "mkdir -p /var/lib/pbx/portsip"
ssh $2 "mkdir -p /var/lib/pbx/portsip"
ssh $1 "sudo docker container run -d --name pbx --network=host -v /var/lib/pbx/portsip:/var/lib/portsip -v /etc/localtime:/etc/localtime:ro  -e POSTGRES_PASSWORD=$4 -e POSTGRES_LISTEN_ADDRESSES="*,127.0.0.1" -e IP_ADDRESS="$3"  $5"
ssh $1 "sudo docker stop -t 30 pbx"
ssh $2 "sudo docker container run -d --name pbx --network=host -v /var/lib/pbx/portsip:/var/lib/portsip -v /etc/localtime:/etc/localtime:ro  -e POSTGRES_PASSWORD=$4-e POSTGRES_LISTEN_ADDRESSES="*,127.0.0.1" -e IP_ADDRESS="$3"  $5"
ssh $2 "sudo docker stop -t 30 pbx"