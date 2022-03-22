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
sudo docker rm -f client server router
sudo docker network rm client_net server_net
sudo ip l set ens19 up
sudo ip l set ens20 up

# Networks
sudo docker network create -d macvlan --subnet=10.0.1.0/24 --gateway=10.0.1.1 -o parent=ens19 client_net
sudo docker network create -d macvlan --subnet=10.0.2.0/24 --gateway=10.0.2.1 -o parent=ens20 server_net

# Build images
sudo docker build --tag router-ubuntu:latest ./images/router-ubuntu
sudo docker build --tag server-nginx:latest ./images/server-nginx
sudo docker build --tag client-browsertime:latest ./images/client-browsertime

# Router
sudo docker run -d -t --net client_net --ip 10.0.1.254 --cap-add=NET_ADMIN --name router router-ubuntu
sudo docker network connect server_net router --ip 10.0.2.254

# Client and server
sudo docker run -d --net server_net --ip 10.0.2.100 --cap-add=NET_ADMIN --name server server-nginx 
sudo docker run -d --net client_net --ip 10.0.1.100 --cap-add=NET_ADMIN --name client client-browsertime

# Routing
sudo docker exec client /bin/bash -c 'ip r del default via 10.0.1.1'
sudo docker exec client /bin/bash -c 'ip r a 10.0.2.0/24 via 10.0.1.254'
sudo docker exec server /bin/bash -c 'ip r del default via 10.0.2.1'
sudo docker exec server /bin/bash -c 'ip r a 10.0.1.0/24 via 10.0.2.254'
