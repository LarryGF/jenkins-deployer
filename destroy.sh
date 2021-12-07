#! /bin/bash
printf "\n[*] Trying to figure out GID of docker.sock"
#Need to set the DOCKER_PATH env var before running the script if it's not running in this path
docker_gid=`ls -ldn ${DOCKER_PATH:-'/var/run/docker.sock'} | awk '{print $4}'`
printf "\n[*] Docker GID: $docker_gid \n Bringing the compose down with correct ownership for docker.sock"
DOCKER_GID=$docker_gid docker-compose down
sudo rm -r consul_data/*
sudo rm -r keys/*
sudo rm -r jenkins_home/*
sudo rm -r jenkins_logs/*
kubectl delete -f portainer-agent-k8s.yaml
