#!/bin/bash

[[ $DISCOVERY_URL ]] || exit 1

set -e

for node in $(openstack baremetal node list -f value -c Name); do
  echo "configuring node $node"
  openstack baremetal node set --instance-info deploy_interface=ramdisk "$node"
  openstack baremetal node set --instance-info boot_iso="$DISCOVERY_URL" "$node"
  openstack esi node network attach --network provisioning "$node"
done

sleep 5

echo "Deploying..."
for node in $(openstack baremetal node list -f value -c Name); do
  echo "deploying node $node"
  openstack baremetal node show "$node" -f value -c provision_state | grep -q available &&
    openstack baremetal node deploy "$node"
done
