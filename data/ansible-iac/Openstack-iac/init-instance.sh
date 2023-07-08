#!/bin/bash

cd /root/
source admin-openrc

openstack network create  --share --external \
  --provider-physical-network physprod \
  --provider-network-type flat public-prod

PROVIDER_START_IP_ADDRESS=172.18.216.10
PROVIDER_END_IP_ADDRESS=172.18.216.254
PROVIDER_NETWORK_GATEWAY=172.18.216.1
DNS_RESOLVER=8.8.8.8
PROVIDER_NETWORK_CIDR=172.18.216.0/24

openstack subnet create --network public-prod \
  --allocation-pool start=$PROVIDER_START_IP_ADDRESS,end=$PROVIDER_END_IP_ADDRESS \
  --dns-nameserver $DNS_RESOLVER --gateway $PROVIDER_NETWORK_GATEWAY \
  --subnet-range $PROVIDER_NETWORK_CIDR prod-subnet

openstack network create private-net

PRIVATE_NETWORK_CIDR=192.168.100.0/24
PRIVATE_START_IP_ADDRESS=192.168.100.10
PRIVATE_END_IP_ADDRESS=192.168.100.254
PRIVATE_NETWORK_GATEWAY=192.168.100.1
DNS_RESOLVER=8.8.8.8

openstack subnet create --network private-net \
  --allocation-pool start=$PRIVATE_START_IP_ADDRESS,end=$PRIVATE_END_IP_ADDRESS \
  --dns-nameserver $DNS_RESOLVER --gateway $PRIVATE_NETWORK_GATEWAY \
  --subnet-range $PRIVATE_NETWORK_CIDR private-subnet

openstack router create myrouter
openstack router set --external-gateway public-prod myrouter
openstack router add subnet myrouter private-subnet

wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

openstack image create --disk-format qcow2 --container-format bare \
  --public --file ./bionic-server-cloudimg-amd64.img bionic-server-cloudimg-amd64

openstack flavor create --ram 2048 --disk 25 --vcpus 2 --public standard

openstack security group create allow-all-traffic --description 'Allow All Ingress Traffic'
openstack security group rule create --protocol icmp allow-all-traffic
openstack security group rule create --protocol tcp  allow-all-traffic
openstack security group rule create --protocol udp  allow-all-traffic

openstack keypair create --public-key ~/.ssh/id_rsa.pub controller-key

openstack server create --flavor standard \
  --image bionic-server-cloudimg-amd64 \
  --key-name controller-key \
  --security-group allow-all-traffic \
  --network private-net \
  ubuntu0

FLOATING_IP_ADD=172.18.216.72

openstack floating ip create public-prod --floating-ip-address $FLOATING_IP_ADD

openstack server add floating ip ubuntu0 $FLOATING_IP_ADD

nova list
