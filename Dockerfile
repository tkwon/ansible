FROM alpine:3.9

# Put there required Ansible version. If it doesn't matter - put ANSIBLE_VERSION=latest
ARG ANSIBLE_VERSION=2.8.4

USER root

# Install all the dependencies needed for ansible operation.
RUN apk --update --no-cache add \
        ca-certificates \
        git \
        openssh-client \
        openssl \
        python3\
        rsync \
        sshpass

# Install ansible. All the dependencies needed only for install (not to operate) Ansible will be removed to optimize space.
RUN apk --update add --virtual \
        .build-deps \
        python3-dev \
        libffi-dev \
        openssl-dev \
        build-base \
 && pip3 install --upgrade \
        pip \
        cffi \
 && pip3 install \
        ansible==${ANSIBLE_VERSION} \
 && apk del \
        .build-deps \
 && rm -rf /var/cache/apk/*

# Create default ansible hosts file with localhost inside. Adding turn off ssh host checking to avoid interactive prompt.
RUN mkdir -p /etc/ansible && \
    echo 'localhost' > /etc/ansible/hosts && \
    echo -e """\
\n\
Host *\n\
    StrictHostKeyChecking no\n\
    UserKnownHostsFile=/dev/null\n\
""" >> /etc/ssh/ssh_config

# Set workdir
WORKDIR /ansible


# Docker Desktop for Windows sets permissions on shared volumes to a default value of 0777 (read, write, execute permissions for user and for group).
# The default permissions on shared volumes are not configurable. Because we have files which are sensetive for permissions,
# like ssh keys or ansible vault files, we should copy them to container manually.
# To do so you should copy file to the build folder, and use these commands in Dockerfile:
COPY id_rsa /root/.ssh/
COPY id_rsa.pub /root/.ssh/
COPY vault.key /root/

RUN chmod 600 /root/.ssh/id_rsa && \
    chmod 644 /root/.ssh/id_rsa.pub && \
    chmod 600 /root/vault.key


# Default command: display Ansible version
CMD [ "ansible-playbook", "--version" ]


# Instructions

# put the Dockerfile in any folder on Windows.
# put ssh keys to this folder
# go to this folder
# start CMD/Powershell and run docker build command and name you container:
# "docker build --tag=dockeransible ."

# wait ~ 5 min

# Docker command to run container
# "docker run -it --rm --network="host" -v c:/Vasya/Code/ansible:/ansible dockeransible ansible-playbook -i inventory playbooks/test_playbook.yml --vault-id /root/vault.key"
# --rm - delete container after stop
# --network="host" - docker container use the same IP Address as the host PC. If the PC can connect to remote host, docker container can do as well.
# -v c:/Vasya/Code/ansible/jenkins-manage:/ansible dockeransible - share folders btw docker and Windows. -v <host-directory>:<container-path>. Use forward slash.
# dockeransible - name of the container
# ansible-playbook -i inventory playbooks/test_playbook.yml - ordinary ansible commands. Note, you are in WORKDIR /ansible