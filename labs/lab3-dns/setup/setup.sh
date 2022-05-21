#!/bin/bash

# Remove old ssh known_hosts
rm /home/theuser/.ssh/known_hosts

# Setup target vm
echo "Setting up target"
scp -r ./images/ vmb:/home/theuser/
scp ./docker-install.sh vmb:/home/theuser/
scp -r ./dns/ vmb:/home/theuser
ssh vmb "bash -s" < scripts-target.sh
