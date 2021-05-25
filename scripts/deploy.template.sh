#!/bin/bash -x
# Copyright (c) 2019, 2020 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
#
# Description: Sets up kind Basic a.k.a. "Monolite".
# Return codes: 0 =
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

get_object() {
    out_file=$1
    os_uri=$2
    success=1
    for i in $(seq 1 9); do
        echo "trying ($i) $2"
        http_status=$(curl -w '%%{http_code}' -L -s -o $1 $2)
        if [ "$http_status" -eq "200" ]; then
            success=0
            echo "saved to $1"
            break 
        else
             sleep 15
        fi
    done
    return $success
}

# get artifacts from object storage
get_object /root/wallet.64 ${wallet_par}
# Setup ATP wallet files
base64 --decode /root/wallet.64 > /root/wallet.zip
unzip /root/wallet.zip -d /usr/lib/oracle/${oracle_client_version}/client64/lib/network/admin/

source /root/kind.env
export $(cut -d= -f1 /root/kind.env)
ln -s /usr/lib/oracle/${oracle_client_version}/client64/lib/network/admin /root/wallet
docker plugin set s3fs AWSACCESSKEYID=$AWSACCESSKEYID
docker plugin set s3fs AWSSECRETACCESSKEY="$AWSSECRETACCESSKEY"
docker plugin set s3fs DEFAULT_S3FSOPTS="nomultipart,use_path_request_style,url=https://$OBJECT_NAMESPACE.compat.objectstorage.$REGION_ID.oraclecloud.com/"
docker plugin enable s3fs

# Init DB
if [[ $(echo $(hostname) | grep "\-0$") ]]; then
    sqlplus ADMIN/"${atp_pw}"@${db_name}_tp @/root/catalogue.sql
fi

mkdir -p /var/log/traefik
mkdir -p /root/data/action.d/
mkdir -p /root/data/filter.d/
mkdir -p /root/data/jail.d/
cat >> /root/data/jail.d/sshd.conf <<EOF 
[sshd]
enabled = true
chain = INPUT
port = ssh
filter = sshd[mode=aggressive]
logpath = /var/log/secure
maxretry = 5
EOF

# start fail2ban as Docker container
docker run -d --name fail2ban \
    --restart always \
    --network host \
    --cap-add NET_ADMIN \
    --cap-add NET_RAW \
    -v /root/data:/data \
    -v /var/log:/var/log:ro \
    -e F2B_LOG_LEVEL=DEBUG \
    crazymax/fail2ban:latest

# Kubernet cluster install using Kind --image rossgeorgiev/kind-node-arm64 
# https://kind.sigs.k8s.io/docs/user/quick-start/#installation
mkdir -p /home/kind
kind create cluster --config=/root/kind-multinode.yaml

kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false", "storageclass.beta.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true", "storageclass.beta.kubernetes.io/is-default-class":"true"}}}'
# Ingress NGinx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
# CertManager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager
helm install --generate-name --namespace cert-manager --wait jetstack/cert-manager
# ClusterIssuer
kubectl apply -f https://gist.githubusercontent.com/marcelo-ochoa/5df1fd6f62815caf038d9993fd306c0e/raw/66bef42fb45842c030a491b2bd5b2541bdb1bd9f/letsencrypt-http01.yaml
kubectl apply -f https://gist.githubusercontent.com/marcelo-ochoa/e9be42c86b56a05429f1befe33a4a7ab/raw/51e8012bda44340fb9f68021a030cd5ba4c4d302/letsencrypt-staging-http01.yaml
# Sample echo app
kubectl create deployment web --image=nginx
kubectl expose deployment web --port=80
sleep 30s
kubectl apply -f https://gist.githubusercontent.com/marcelo-ochoa/17097f078966081c94f423fb08d344ae/raw/749ab552cd82aa6fd3f1f1577633c9c366d5c9c9/sample-app.yaml
# test
# curl -v -I --resolve www.example.com:80:127.0.0.1 http://www.example.com/
# curl -v -I -k --resolve www.example.com:443:127.0.0.1 https://www.example.com/
