FROM sitespeedio/browsertime:15.3.0
COPY ./daily-browsertime.sh /bin/
RUN chmod +x /bin/daily-browsertime.sh
ENTRYPOINT ["/bin/daily-browsertime.sh"]
RUN apt update && apt install -y vim iproute2 iputils-ping tcpdump iptables dnsutils curl iputils-tracepath
