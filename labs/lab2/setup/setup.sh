#!/bin/bash

# Remove old ssh known_hosts
rm /home/theuser/.ssh/known_hosts

# Setup target vm
echo "Setting up target"
scp -r ./images/ vmc:/home/theuser/
scp ./docker-install.sh vmc:/home/theuser/
ssh vmc "bash -s" < scripts-target.sh
