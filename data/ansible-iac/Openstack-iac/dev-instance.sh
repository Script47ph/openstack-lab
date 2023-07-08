#!/bin/bash

source /root/admin-openrc

openstack network create  --share --external \
  --provider-physical-network physdev \
  --provider-network-type flat public-dev

PROVIDER_START_IP_ADDRESS=172.18.224.10
PROVIDER_END_IP_ADDRESS=172.18.224.254
PROVIDER_NETWORK_GATEWAY=172.18.224.1
DNS_RESOLVER=8.8.8.8
PROVIDER_NETWORK_CIDR=172.18.224.0/24

openstack subnet create --network public-dev \
  --allocation-pool start=$PROVIDER_START_IP_ADDRESS,end=$PROVIDER_END_IP_ADDRESS \
  --dns-nameserver $DNS_RESOLVER --gateway $PROVIDER_NETWORK_GATEWAY \
  --subnet-range $PROVIDER_NETWORK_CIDR dev-subnet

openstack network create dev-private-network

PRIVATE_NETWORK_CIDR=192.168.88.0/24
PRIVATE_START_IP_ADDRESS=192.168.88.10
PRIVATE_END_IP_ADDRESS=192.168.88.254
PRIVATE_NETWORK_GATEWAY=192.168.88.1
DNS_RESOLVER=8.8.8.8

openstack subnet create --network dev-private-network \
  --allocation-pool start=$PRIVATE_START_IP_ADDRESS,end=$PRIVATE_END_IP_ADDRESS \
  --dns-nameserver $DNS_RESOLVER --gateway $PRIVATE_NETWORK_GATEWAY \
  --subnet-range $PRIVATE_NETWORK_CIDR dev-private-subnet

openstack router create dev-router
openstack router set --external-gateway public-dev dev-router
openstack router add subnet dev-router dev-private-subnet

openstack server create --flavor standard \
  --image bionic-server-cloudimg-amd64 \
  --key-name controller-key \
  --security-group allow-all-traffic \
  --network dev-private-network \
  ubuntu-dev

openstack floating ip create public-dev

FLOATING_IP_ADD=$(openstack floating ip list --network public-dev -f json|jq '.[]."Floating IP Address"'|tr -d '"')

openstack server add floating ip ubuntu-dev $FLOATING_IP_ADD
