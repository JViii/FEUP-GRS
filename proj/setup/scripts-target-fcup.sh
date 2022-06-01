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
sudo docker rm -f client server router edgerouter bind9_myorg_auth mailserver
sudo docker network rm client_net server_net public_net dmz_net
# Ativar quando o proxmox voltar a estar disponivel
# sudo ip l set ens19 up
# sudo ip l set ens20 up
# sudo ip l set ens21 up

# Networks
sudo docker network create --subnet=10.10.1.0/24 --gateway=10.10.1.1 client_net
sudo docker network create --subnet=10.10.2.0/24 --gateway=10.10.2.1 server_net
sudo docker network create --subnet=172.131.255.0/24 --gateway=172.131.255.254 public_net
# sudo docker network create --subnet=172.131.255.0/24 --gateway=172.131.255.254 -o parent=ens19 public_net
# sudo docker network create -d macvlan --subnet=172.131.255.0/24 --gateway=172.131.255.254 -o parent=ens19 public_net
sudo docker network create --subnet=172.116.123.128/28 --gateway=172.116.123.140 dmz_net

# Build images
sudo docker build --tag router-ubuntu:latest ./images/router-ubuntu
sudo docker build --tag server-nginx:latest ./images/server-nginx
sudo docker build --tag client-browsertime:latest ./images/client-browsertime

# Router
sudo docker run -d -t --net client_net --ip 10.10.1.254 --cap-add=NET_ADMIN --name router router-ubuntu
sudo docker network connect server_net router --ip 10.10.2.254
# sudo docker network disconnect public_net router
sudo docker network connect dmz_net router --ip 172.116.123.142

# External Router
sudo docker run -d --rm --net dmz_net --ip 172.116.123.139 --cap-add=NET_ADMIN --name edgerouter router-ubuntu
sudo docker network connect public_net edgerouter --ip 172.131.255.253

# Client and server
sudo docker run -d --net server_net --ip 10.10.2.100 --cap-add=NET_ADMIN --name server server-nginx 
sudo docker run -d --net client_net --ip 10.10.1.100 --cap-add=NET_ADMIN --name client client-browsertime

# DNS Server
# sudo docker run -d --name bind9_myorg_auth --volume dns/etcbind:/etc/bind --volume /var/cache/bind --volume /var/lib/bind --rm --net dmz_net --ip 172.116.123.129 --cap-add=NET_ADMIN internetsystemsconsortium/bind9:9.16
sudo docker run -d --volume "/home/theuser/dns-fcup/etcbind/db.fe.up.pt:/etc/bind/db.fe.up.pt" --volume "/home/theuser/dns-fcup/etcbind/named.conf.local:/etc/bind/named.conf.local" --volume /var/cache/bind --volume /var/lib/bind --rm --net dmz_net --ip 172.116.123.129 --cap-add=NET_ADMIN --name bind9_myorg_auth internetsystemsconsortium/bind9:9.16

# Mail server
# Password bigger than 5 characters and containing 2 numbers
sudo docker run -d \
                -e "ADMIN_USERNAME=root" \
                -e "ADMIN_PASSWD=password"  \
                -e "DOMAIN_NAME=fc.up.pt" \
                -e "USERS=john12:john12,alice12:alice12" \
                -v "/home/theuser/data/fcup/mysql":"/var/lib/mysql" -v "/home/theuser/data/fcup/vmail/":"/var/vmail" -v "/home/theuser/data/fcup/log":"/var/log" \
                --net dmz_net --ip 172.116.123.130 --cap-add=NET_ADMIN \
                --name mailserver marooou/postfix-roundcube
                # -p 25:25 -p 80:80 -p 110:110 -p 143:143 -p 465:465 -p 993:993 -p 995:995 \

# sudo docker run -e "ADMIN_USERNAME=root" -e "ADMIN_PASSWD=password" -e "DOMAIN_NAME=fe.up.pt" -e "USERS=john12:john12,alice12:alice12" -d -v /home/theuser/data/mysql:/var/lib/mysql -v /home/theuser/data/vmail/:/var/vmail -v /home/theuser/data/log:/var/log --name mailserver -p 25:25 -p 80:80 -p 110:110 -p 143:143 -p 465:465 -p 993:993 -p 995:995 --net dmz_net --ip 172.116.123.130 --cap-add=NET_ADMIN marooou/postfix-roundcube


# Routing
sudo docker exec client /bin/bash -c 'ip r del default via 10.10.1.1'
sudo docker exec client /bin/bash -c 'ip r a 10.10.2.0/24 via 10.10.1.254'
sudo docker exec client /bin/bash -c 'ip r a default via 10.10.1.254'

sudo docker exec server /bin/bash -c 'ip r del default via 10.10.2.1'
sudo docker exec server /bin/bash -c 'ip r a 10.10.1.0/24 via 10.10.2.254'
sudo docker exec server /bin/bash -c 'ip r a default via 10.10.2.254'

sudo docker exec router /bin/bash -c 'ip r d default via 10.10.1.1'
sudo docker exec router /bin/bash -c 'ip r a default via 172.116.123.139'

sudo docker exec edgerouter /bin/bash -c 'ip r d default via 172.116.123.140'
sudo docker exec edgerouter /bin/bash -c 'ip r a default via 172.131.255.254'
sudo docker exec edgerouter /bin/bash -c 'ip r a 10.0.0.0/8 via 172.116.123.142'
sudo docker exec edgerouter /bin/bash -c 'iptables -t nat -F'
sudo docker exec edgerouter /bin/bash -c 'iptables -t filter -F'
sudo docker exec edgerouter /bin/bash -c 'iptables -t nat -A POSTROUTING -s 10.0.0.0/8 -o eth1 -j MASQUERADE'
sudo docker exec edgerouter /bin/bash -c 'iptables -P FORWARD DROP'
sudo docker exec edgerouter /bin/bash -c 'iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT'
sudo docker exec edgerouter /bin/bash -c 'iptables -A FORWARD -m state --state NEW -i eth0 -j ACCEPT'
sudo docker exec edgerouter /bin/bash -c 'iptables -A FORWARD -m state --state NEW -i eth1 -d 172.116.123.128/28 -j ACCEPT'

sudo docker exec bind9_myorg_auth /bin/bash -c 'ip r d default via 172.116.123.140'
sudo docker exec bind9_myorg_auth /bin/bash -c 'ip r a default via 172.116.123.139'

sudo docker exec mailserver /bin/bash -c 'ip r d default via 172.116.123.140'
sudo docker exec mailserver /bin/bash -c 'ip r a default via 172.116.123.139'

# Let docker know about the DMZ network and NAT it
sudo ip r a 172.116.123.128/28 via 172.131.255.253
sudo iptables -t nat -A POSTROUTING -s 172.116.123.128/28 -o eth4 -j MASQUERADE
