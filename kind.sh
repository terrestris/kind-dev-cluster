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

# Add repositories for Helm charts
echo "Adding kubernetes-dashboard Helm repository..."
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# create admin user and apply cluster role bindings
kubectl create serviceaccount admin-user -n kube-system
kubectl create clusterrolebinding admin-user-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:admin-user

# install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.2/deploy/static/provider/kind/deploy.yaml

# install the Kubernetes dashboard
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

# Install argo
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.7.2/install.yaml
kubectl -n argo patch deployment argo-server   --type='json'   -p='[{"op": "add", "path": "/spec/template/spec/containers/0/env", "value": [{"name": "ARGO_BASE_HREF", "value": "/argo"}]}]'
kubectl rollout restart deployment argo-server -n argo

./wait_until_pods_have_started.sh "ingress-nginx" "app.kubernetes.io/instance=ingress-nginx" 3 2
./wait_until_pods_have_started.sh "kubernetes-dashboard" "app.kubernetes.io/instance=kubernetes-dashboard" 5 2
# ./wait_until_pods_have_started.sh "argo" "app.kubernetes.io/instance=argo" 2 2

# Apply ingress resources
kubectl apply -f ./templates/ingress-dashboard.yaml
kubectl apply -f ./templates/ingress-argo.yaml

echo
echo "Use this token to login on https://localhost/dashboard or https://localhost/argo :"
echo
# Create a token for the admin user
kubectl create token admin-user -n kube-system
echo
echo
