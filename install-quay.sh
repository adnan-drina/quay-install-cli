#!/bin/bash

#Make sure you're connected to your OpenShift cluster with admin user before running this script

echo "***********************************************"
echo "Installing Quay Operator"
echo "***********************************************"
echo "Creating Quay namespace"
oc apply -f quay-namespace.yaml
echo " "

echo "Creating Quay Config Bundle Secret"
oc apply -f quay-config-bundle-secret.yaml
echo " "

echo "Creating Quay Subscription"
oc apply -f quay-sub.yaml
echo "Wait for Quay Operator to become ready"
sleep 30
QUAY="$(oc get subs -o name -n openshift-operators | grep quay-operator)"
oc -n openshift-operators wait --timeout=120s --for=condition=CatalogSourcesUnhealthy=False ${QUAY}
echo " "

echo "Deploying QuayRegistry CR"
oc apply -f quay-cr.yaml
echo " "
sleep 30
echo " "
echo "***********************************************"
echo "Quay Security Operator"
echo "***********************************************"
echo "Install Quay Security Operator"
oc apply -f quay-security-sub.yaml
echo "Quay Security Operator installed!"
echo " "
echo "Searching for available routes"
oc get routes -n quay
echo " "
echo "connect to the route named container-registry-quay using your browser"