FROM jenkins/jenkins:latest
# This is the GID for the docker.sock file
ARG DOCKER_GID
ENV JENKINS_OPTS="--prefix=/jenkins --handlerCountMax=300 --logfile=/var/log/jenkins/jenkins.log --webroot=/var/cache/jenkins/war"
ENV CASC_JENKINS_CONFIG="/usr/share/jenkins/ref/casc.yaml"
USER root
COPY --chown=jenkins:jenkins ./config/plugins.txt /usr/share/jenkins/ref/plugins.txt
COPY --chown=jenkins:jenkins ./config/keys/converted-github-app.pem /tmp/converted-github-app.pem
# COPY --chown=jenkins:jenkins ./config/keys/known_hosts /var/jenkins_home/.ssh/known_hosts
COPY --chown=jenkins:jenkins ./config/DSL-jobs /tmp/DSL-jobs

#### Mounting to ease development
#COPY --chown=jenkins:jenkins ./config/casc.yaml /usr/share/jenkins/ref/casc.yaml
RUN mkdir /var/log/jenkins
RUN mkdir /var/cache/jenkins
RUN chown -R jenkins:jenkins /var/log/jenkins
RUN chown -R jenkins:jenkins /var/cache/jenkins
RUN groupadd -g ${DOCKER_GID} docker
RUN usermod -a -G docker jenkins

RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
# RUN apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
# RUN apt-get update && apt-get install vault
### Commented out for dev purposes, uncomment it for a normal run
# RUN apt-get update \
#     && apt-get install -y \
#     ansible

RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

USER jenkins
RUN mkdir "${JENKINS_HOME}/.ssh"

