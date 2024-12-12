#!/bin/bash

api_port=$(
openstack port show hypershift-vip-api -f value -c id 2>/dev/null ||
  openstack port create \
            --network hypershift \
            --fixed-ip subnet=hypershift-subnet0,ip-address=10.233.0.10 hypershift-vip-api  \
            -f value -c id
)

ingress_port=$(
openstack port show hypershift-vip-ingress -f value -c id 2>/dev/null ||
  openstack port create \
            --network hypershift \
            --fixed-ip subnet=hypershift-subnet0,ip-address=10.233.0.11 hypershift-vip-ingress \
            -f value -c id
)

has_api_port=$(openstack floating ip list -f json | jq --arg port "$api_port" '[.[]|select(.Port == $port)]|length')
has_ingress_port=$(openstack floating ip list -f json | jq --arg port "$ingress_port" '[.[]|select(.Port == $port)]|length')

if ! (( has_api_port )); then
  api_vip=$(openstack floating ip create external -f value -c floating_ip_address)
  openstack floating ip set --port "$api_port" "$api_vip"
fi

if ! (( has_ingress_port )); then
  ingress_vip=$(openstack floating ip create external -f value -c floating_ip_address)
  openstack floating ip set --port "$ingress_port" "$ingress_vip"
fi
