#!/bin/bash

for node in $(kubectl get node -o name --selector='!node-role.kubernetes.io/master');
do
  echo "oc label nodes ${node##*/} cluster.ocs.openshift.io/openshift-storage="" --overwrite=true"
  oc label nodes ${node##*/} cluster.ocs.openshift.io/openshift-storage="" --overwrite=true
done