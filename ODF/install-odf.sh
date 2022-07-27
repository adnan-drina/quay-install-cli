#!/bin/bash

#Make sure you're connected to your OpenShift cluster with admin user before running this script

echo "***********************************************"
echo "Installing ODF Operator"
echo "***********************************************"
echo "Creating ODF namespace"
oc apply -f ./ODF/odf-namespace.yaml
echo " "

echo "Creating ODF OperatorGroup"
oc apply -f ./ODF/odf-og.yaml
echo " "

echo "Creating ODF Subscription"
oc apply -f ./ODF/odf-sub.yaml
echo " "

echo "Creating ODF Console"
oc apply -f ./ODF/odf-console-plugin.yaml
echo " "

echo "Creating ODF Console SA"
oc apply -f ./ODF/odf-enable-console-plugin-sa.yaml
echo " "

echo "Creating ODF Console RBAC"
oc apply -f ./ODF/odf-enable-console-plugin-rbac.yaml
echo " "

echo "Creating ODF Console job"
oc apply -f ./ODF/odf-enable-console-plugin-job.yaml
echo " "

echo "Wait for ODF Operator 60 sec"
sleep 30
ODF="$(oc get subs -o name -n openshift-storage | grep odf-operator)"
oc -n openshift-storage wait --timeout=120s --for=condition=CatalogSourcesUnhealthy=False ${ODF}

echo "Label worker nodes"
./ODF/odf-label-nodes.sh
echo " "

echo "Creating ODF Storage System"
oc apply -f ./ODF/odf-storagesystem.yaml
echo " "

echo "Creating ODF Storage Cluster"
oc apply -f ./ODF/odf-storagecluster.yaml
echo " "

echo "Initialize ODF Storage Cluster"
oc apply -f ./ODF/odf-initialization.yaml
echo " "