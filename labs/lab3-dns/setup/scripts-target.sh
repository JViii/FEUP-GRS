#!/bin/bash

# Route setup to access internet
sudo ip route del default via 192.168.88.1
sudo ip r a default via 192.168.88.100

# Install docker if not installed
if [ ! $(which docker) ]
then
  echo "Installing docker"
  chmod +x docker-install.sh
  ./docker-install.sh
fi

# Restart and setup interfaces
sudo docker rm -f client server router edgerouter externalhost bind9_myorg_auth
sudo docker network rm client_net server_net public_net dmz_net
sudo ip l set ens19 up
sudo ip l set ens20 up
sudo ip l set ens21 up

# Networks
sudo docker network create -d macvlan --subnet=10.0.1.0/24 --gateway=10.0.1.1 -o parent=ens19 client_net
sudo docker network create -d macvlan --subnet=10.0.2.0/24 --gateway=10.0.2.1 -o parent=ens20 server_net
sudo docker network create public_net --subnet=172.31.255.0/24 --gateway=172.31.255.254
sudo docker network create -d macvlan --subnet=172.16.123.128/28 --gateway=172.16.123.140 -o parent=ens21 dmz_net

# Build images
sudo docker build --tag router-ubuntu:latest ./images/router-ubuntu
sudo docker build --tag server-nginx:latest ./images/server-nginx
sudo docker build --tag client-browsertime:latest ./images/client-browsertime

# Router
sudo docker run -d -t --net client_net --ip 10.0.1.254 --cap-add=NET_ADMIN --name router router-ubuntu
sudo docker network connect server_net router --ip 10.0.2.254
# sudo docker network disconnect public_net router
sudo docker network connect dmz_net router --ip 172.16.123.142

# External Router
sudo docker run -d --rm --net dmz_net --ip 172.16.123.139 --cap-add=NET_ADMIN --name edgerouter router-ubuntu
sudo docker network connect public_net edgerouter --ip 172.31.255.253

# External Client
sudo docker run -d --net public_net --ip 172.31.255.100 --cap-add=NET_ADMIN --name externalhost client-browsertime

# Client and server
sudo docker run -d --net server_net --ip 10.0.2.100 --cap-add=NET_ADMIN --name server server-nginx 
sudo docker run -d --net client_net --ip 10.0.1.100 --cap-add=NET_ADMIN --name client client-browsertime

# DNS Server
# sudo docker run -d --name bind9_myorg_auth --volume dns/etcbind:/etc/bind --volume /var/cache/bind --volume /var/lib/bind --rm --net dmz_net --ip 172.16.123.129 --cap-add=NET_ADMIN internetsystemsconsortium/bind9:9.16

sudo docker run -d --volume "/home/theuser/dns/etcbind/db.feup.up.pt:/etc/bind/db.feup.up.pt" --volume "/home/theuser/dns/etcbind/named.conf.local:/etc/bind/named.conf.local" --volume /var/cache/bind --volume /var/lib/bind --rm --net dmz_net --ip 172.16.123.129 --cap-add=NET_ADMIN --name bind9_myorg_auth internetsystemsconsortium/bind9:9.16

# Routing
sudo docker exec client /bin/bash -c 'ip r del default via 10.0.1.1'
sudo docker exec client /bin/bash -c 'ip r a 10.0.2.0/24 via 10.0.1.254'
sudo docker exec client /bin/bash -c 'ip r a default via 10.0.1.254'

sudo docker exec server /bin/bash -c 'ip r del default via 10.0.2.1'
sudo docker exec server /bin/bash -c 'ip r a 1.0.1.0/24 via 10.0.2.254'
sudo docker exec server /bin/bash -c 'ip r a default via 10.0.2.254'

sudo docker exec router /bin/bash -c 'ip r d default via 10.0.1.1'
sudo docker exec router /bin/bash -c 'ip r a default via 172.16.123.139'

sudo docker exec edgerouter /bin/bash -c 'ip r d default via 172.16.123.140'
sudo docker exec edgerouter /bin/bash -c 'ip r a default via 172.31.255.254'
sudo docker exec edgerouter /bin/bash -c 'ip r a 10.0.0.0/8 via 172.16.123.142'
sudo docker exec edgerouter /bin/bash -c 'iptables -t nat -F'
sudo docker exec edgerouter /bin/bash -c 'iptables -t filter -F'
sudo docker exec edgerouter /bin/bash -c 'iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -o eth1 -j MASQUERADE'
sudo docker exec edgerouter /bin/bash -c 'iptables -P FORWARD DROP'
sudo docker exec edgerouter /bin/bash -c 'iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT'
sudo docker exec edgerouter /bin/bash -c 'iptables -A FORWARD -m state --state NEW -i eth0 -j ACCEPT'
sudo docker exec edgerouter /bin/bash -c 'iptables -A FORWARD -m state --state NEW -i eth1 -d 172.16.123.128/28 -j ACCEPT'

sudo docker exec externalhost /bin/bash -c 'ip r a 172.16.123.128/28 via 172.31.255.253'
sudo docker exec externalhost /bin/bash -c 'ip r a 10.0.0.0/8 via 172.31.255.253'

sudo docker exec bind9_myorg_auth ip r d default via 172.16.123.140
sudo docker exec bind9_myorg_auth ip r a default via 172.16.123.139

# Let docker know about the DMZ network and NAT it
sudo ip r a 172.16.123.128/28 via 172.31.255.253
sudo iptables -t nat -A POSTROUTING -s 172.16.123.128/28 -o eth4 -j MASQUERADE
