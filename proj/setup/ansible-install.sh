#!/bin/bash
##install ansible
sudo apt install ansible

##install pip depedency
sudo apt install python3-pip

##install ansible modules
pip install napalm-ansible
pip install napalm-ros

##uploading configuration file
sudo cp ansible/ansible.cfg /etc/ansible/
