#! /bin/bash
echo 'Trying to figure out GID of docker.sock'
DOCKER_GID=`ls -ldn ${DOCKER_PATH:-'/var/run/docker.sock'} | awk '{print $4}'`
echo "Docker GID: ${DOCKER_GID}"
echo  "Bringing the compose up with correct ownership for docker.sock"
DOCKER_GID=$DOCKER_GID docker-compose up --build --remove-orphans