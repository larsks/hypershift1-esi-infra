#!/bin/bash

set -e

echo "create hypershift network"
network_id=$(
  openstack network show hypershift -f value -c id 2>/dev/null ||
    openstack network create hypershift -f value -c id
)

echo "create hypershift subnet"
subnet_id=$(
  openstack subnet show hypershift-subnet0 -f value -c id 2>/dev/null ||
    openstack subnet create hypershift-subnet0 --network hypershift \
      --allocation-pool start=10.233.0.50,end=10.233.15.254 \
      --subnet-range 10.233.0.0/20 \
      --dns-nameserver 8.8.8.8 \
      -f value -c id
)

echo "create hypershift router"
router_id=$(
  openstack router show hypershift -f value -c id 2>/dev/null ||
    openstack router create hypershift -f value -c id
)

echo "configure hypershift router"
openstack router set hypershift --external-gateway external

echo "attach subnet to hypershift router"
openstack router show hypershift -f json -c interfaces_info | jq -r ".interfaces_info[]|.subnet_id" | grep -q "$subnet_id" ||
  openstack router add subnet hypershift hypershift-subnet0
