#!/bin/bash -e

echo "127.0.0.1" $(hostname) | tee -a /etc/hosts

apt-get update
apt-get install -y wget python python-pip
wget -qO- https://get.docker.com/ | sh
usermod -aG docker ubuntu

docker run --restart=always -d --name dd-agent \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /proc/:/host/proc/:ro \
  -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
  -e API_KEY=23242424242424242 \
  -e SD_BACKEND=docker \
  -p 8125:8125/udp \
  datadog/docker-dd-agent

echo "Userdata-executed"
