#!/bin/bash

# This script will deploy k8s dashboard
# create admin user
# fetch token to login into dashboard
CLUSTERAMD='kops validate cluster'
if [[ -z $CLUSTERAMD ]]; then
  echo "Cluster not available. Please try later"
  exit 1
fi

echo "Deploying dashboard using kubectl"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc3/aio/deploy/recommended.yaml
if [[ $? -eq 0 ]]; then
  kubectl apply -f dashboard-adminuser.yaml
  kubectl apply -f dashboard-adminuser-clusterrole.yaml
fi
echo "Getting token to login into dashboard"
export TOKEN=$(kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}'))
if [[ $TOKEN ]]; then
  echo "use this token to login into dashboard"
  echo $TOKEN
  kubectl proxy
fi
