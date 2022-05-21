#!/bin/bash
ssh vmb 'sudo docker kill `docker ps -aq`'
ssh vmb 'sudo docker rm `docker ps -aq`'
ssh vmb 'sudo docker system prune -f'
ssh vmb 'sudo rm -rf /home/theuser/setup'
