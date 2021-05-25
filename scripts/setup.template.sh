#!/bin/bash -x
# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#
# Description: Sets up kind Basic a.k.a. "Monolite".
# Return codes: 0 =
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

# Configure firewall
firewall-offline-cmd --add-port=80/tcp
firewall-offline-cmd --add-port=443/tcp
firewall-offline-cmd --add-port=8080/tcp

# Docker
firewall-offline-cmd --zone=public --add-port=2377/tcp
firewall-offline-cmd --zone=public --add-port=7946/tcp
firewall-offline-cmd --zone=public --add-port=7946/udp
firewall-offline-cmd --zone=public --add-port=4789/udp
systemctl restart firewalld

dnf clean metadata -y

# Install tools
dnf -y install unzip jq

# Install Oracle Instant Client
dnf -y install oracle-release-el8
dnf config-manager --enable ol8_oracle_instantclient
dnf -y install oracle-instantclient${oracle_client_version}-basic oracle-instantclient${oracle_client_version}-jdbc oracle-instantclient${oracle_client_version}-sqlplus

# Setup Docker
dnf config-manager --enable ol8_baseos_latest ol8_appstream
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sed -i "s/\$releasever/8/g" /etc/yum.repos.d/docker-ce.repo
dnf -y install docker-ce docker-ce-cli containerd.io
systemctl enable --now docker

source /root/kind.env
export $(cut -d= -f1 /root/kind.env)

my_ip=$(ip a show enp0s3|grep 'inet '|cut -d' ' -f6| sed 's/\/24//')
my_base_hostname="oci-kind-$DEPLOY_ID"

echo "${private_key_pem}" > /root/.ssh/id_rsa
echo "${public_key_openssh}" > /root/.ssh/authorized_keys
chmod go-rwx /root/.ssh/*

docker plugin install --alias s3fs mochoa/s3fs-volume-plugin-aarch64 --grant-all-permissions --disable

# Kind setup
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.0/kind-linux-arm64
chmod +x ./kind
mv ./kind /usr/bin/kind

# Kubectl
dnf config-manager --add-repo https://packages.cloud.google.com/yum/repos/kubernetes-el7-aarch64
dnf -y install --nogpgcheck kubectl

# Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
mv /usr/local/bin/helm /usr/bin/helm

######################################
echo "Finished running setup.sh"