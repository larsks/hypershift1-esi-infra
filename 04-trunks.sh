#!/bin/bash

trunk_exists() {
  local _exists
  _exists=$(openstack esi trunk list -f json | jq --arg trunk "$1" '[.[]|select(.Trunk == $trunk)]|length')
  ((_exists))
}

# check if needle ($1) is contained in haystack ($@)
contains() {
  local needle=$1
  shift
  local item
  for item in "$@"; do
    if [[ "$item" = "$needle" ]]; then
      return 0
    fi
    return 1
  done
}

for node in $(openstack baremetal node list --resource-class fc830 -f value -c name); do
  if ! trunk_exists "hypershift-${node}-trunk"; then
    openstack esi trunk create hypershift-"$node"-trunk --native-network nese-storage --tagged-networks nerc-infra-routed
  fi
done

mapfile -t nodes_with_trunks < <(openstack esi node network list -f json | jq -r '.[]|select(.Port != null)|select(.Port|contains("trunk"))|.Node')

for node in $(openstack baremetal node list --resource-class fc830 -f value -c name); do
  if contains "$node" "${nodes_with_trunks[@]}"; then
    continue
  fi

  openstack esi node network attach --trunk "hypershift-${node}-trunk" "$node"
done
