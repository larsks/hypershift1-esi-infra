#!/bin/bash

set -e

for node in $(openstack baremetal node list -f value -c UUID); do
  echo "detaching all ports from node $node"
  openstack port list --host "$node" -f value -c ID |
    xargs -I PORT openstack esi node network detach --port PORT "$node"
done

for node in $(openstack baremetal node list -f value -c Name); do
  echo "attaching node $node to hypershift network"
  openstack esi node network attach --network hypershift "$node"

  echo "configuring node $node to boot from disk"
  openstack baremetal node boot device set "$node" disk --persistent
done

