#!/bin/bash

# Remove old ssh known_hosts
rm /home/theuser/.ssh/known_hosts

# Setup target vm
echo "Setting up fe.up.pt on vmb"
scp -r ./images/ vmb:/home/theuser/
scp ./docker-install.sh vmb:/home/theuser/
scp -r ./dns/dns-feup/ vmb:/home/theuser
ssh vmb "bash -s" < scripts-target-feup.sh

echo "Setting up fc.up.pt on vmc"
scp -r ./images/ vmc:/home/theuser/
scp ./docker-install.sh vmc:/home/theuser/
scp -r ./dns/dns-fcup/ vmc:/home/theuser
ssh vmc "bash -s" < scripts-target-fcup.sh
