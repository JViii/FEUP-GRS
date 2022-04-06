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
sudo docker rm -f database zabbix-server
sudo docker network rm monitoring_net

# Networks
sudo docker network create -d macvlan --subnet=192.168.88.0/24 --gateway=192.168.88.1 -o parent=eth0 monitoring_net

# Build images
sudo docker build --tag zabbix-server:latest ./images/zabbix-server
sudo docker build --tag mysql-db:latest ./images/mysql-db

# Zabbix and mysql database
sudo docker run -d --net monitoring_net --ip 192.168.88.3 --cap-add=NET_ADMIN --name database -e MYSQL_ROOT_PASSWORD=mysqlpassword mysql-db:latest
sudo docker run -d --net monitoring_net --ip 192.168.88.4 --cap-add=NET_ADMIN --name zabbix-server -e DB_SERVER_HOST="192.168.88.3" -e MYSQL_USER="root" -e MYSQL_PASSWORD="mysqlpassword" zabbix-server:latest

# Routing
# sudo docker exec client /bin/bash -c 'ip r del default via 10.0.1.1'
# sudo docker exec client /bin/bash -c 'ip r a 10.0.2.0/24 via 10.0.1.254'
# sudo docker exec server /bin/bash -c 'ip r del default via 10.0.2.1'
# sudo docker exec server /bin/bash -c 'ip r a 10.0.1.0/24 via 10.0.2.254'
