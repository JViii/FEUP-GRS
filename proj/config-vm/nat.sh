#!/bin/bash

# Config VM
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -s 192.168.88.101 -o eth0 -j MASQUERADE
iptables -A FORWARD -s 192.168.88.101 -o eth0 -j ACCEPT
iptables -A FORWARD -s 192.168.88.100 -o eth1 -j ACCEPT
