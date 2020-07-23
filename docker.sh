sudo docker container run -d --name pbx --network=host -v /var/lib/pbx/portsip:/var/lib/portsip -v /etc/localtime:/etc/localtime:ro  -e POSTGRES_PASSWORD=123456 -e POSTGRES_LISTEN_ADDRESSES="*,127.0.0.1" -e IP_ADDRESS="192.168.1.130"  portsip/pbx:12
sudo docker stop -t 30 pbx
ssh $1 "sudo docker container run -d --name pbx --network=host -v /var/lib/pbx/portsip:/var/lib/portsip -v /etc/localtime:/etc/localtime:ro  -e POSTGRES_PASSWORD=123456 -e POSTGRES_LISTEN_ADDRESSES="*,127.0.0.1" -e IP_ADDRESS="192.168.1.130"  portsip/pbx:12"
ssh $1 "sudo docker stop -t 30 pbx"
ssh $2 "sudo docker container run -d --name pbx --network=host -v /var/lib/pbx/portsip:/var/lib/portsip -v /etc/localtime:/etc/localtime:ro  -e POSTGRES_PASSWORD=123456 -e POSTGRES_LISTEN_ADDRESSES="*,127.0.0.1" -e IP_ADDRESS="192.168.1.130"  portsip/pbx:12"
ssh $2 "sudo docker stop -t 30 pbx"