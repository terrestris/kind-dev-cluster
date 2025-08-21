#!/usr/bin/env bash

# exit if cluster is already running
if kind get clusters | grep -q 'kind-dev-cluster'; then
  read -p "Cluster kind-dev-cluster already exists! Do you want to DELETE it and continue (y/Y) or abort (n/N)?" -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    exit 1;
  fi
fi

# delete any existing clusters
kind delete cluster --name kind-dev-cluster

# create the cluster based on the config
kind create cluster --config kind-cluster.yaml

# install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.1/deploy/static/provider/kind/deploy.yaml
./wait_until_pods_have_started.sh "ingress-nginx" "app.kubernetes.io/component=controller" 3 2

# Add kubernetes-dashboard repository
echo "Adding kubernetes-dashboard Helm repository..."
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update

# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
./wait_until_pods_have_started.sh "kubernetes-dashboard" "app.kubernetes.io/instance=kubernetes-dashboard" 5 2

# Apply the Ingress resource for the dashboard
kubectl apply -f ./templates/ingress-dashboard.yaml

# create admin user and apply cluster role bindings
kubectl create serviceaccount admin-user -n kube-system

# Create a ClusterRoleBinding to give the admin user cluster-admin permissions
kubectl create clusterrolebinding admin-user-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:admin-user

echo
echo "Use this token to login on https://localhost :"
echo
# Create a token for the admin user
kubectl create token admin-user -n kube-system
echo
echo
