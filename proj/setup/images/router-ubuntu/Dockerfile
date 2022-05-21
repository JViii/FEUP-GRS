FROM ubuntu:21.10
ENTRYPOINT ["tail", "-f", "/dev/null"]
RUN apt update && apt install -y vim iproute2 iputils-ping tcpdump iptables dnsutils curl
RUN sysctl -w net.ipv4.ip_forward=1
