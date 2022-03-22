#!/bin/bash
scp -i ./setup/ssh/keys/gors-2122-2s.rsa -r ./setup theuser@192.168.109.159:/home/theuser/setup
