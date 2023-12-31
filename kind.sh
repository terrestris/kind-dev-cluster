#!/usr/bin/env bash

# function to wait for applied resources and
# the underlying pods to be fully created and started
function wait_until_pods_have_started() {
  APP_NAME=$1
  SELECTOR=$2
  EXPECTED_LENGTH=$3
  SLEEP_TIME=$4

  echo "Waiting for $APP_NAME resources to be fully created"
  RESULT_LEN="$(kubectl get pod -n $APP_NAME -o go-template='{{.items | len}}')"
  until test $RESULT_LEN -eq $EXPECTED_LENGTH; do
      sleep $SLEEP_TIME
      RESULT_LEN="$(kubectl get pod -n $APP_NAME -o go-template='{{.items | len}}')"
  done
  echo "Resources for $APP_NAME have been fully created. The pods will start now."

  # wait until the controller pod has fully started
  echo "Waiting for $APP_NAME pods to be fully available"
  kubectl wait --namespace $APP_NAME --for=condition=Ready pod --selector=$SELECTOR --timeout=90s
  echo "Pods for $APP_NAME have started and are fully available now"
}

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
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.4/deploy/static/provider/kind/deploy.yaml
wait_until_pods_have_started "ingress-nginx" "app.kubernetes.io/component=controller" 3 2

# install kubernetes-dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
wait_until_pods_have_started "kubernetes-dashboard" "k8s-app=kubernetes-dashboard" 2 2
kubectl apply -f ./templates/ingress-dashboard.yaml

# create admin user and apply cluster role bindings
# https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
kubectl apply -f ./templates/dashboard-adminuser.yaml
kubectl apply -f ./templates/dashboard-adminuser-secret.yaml
kubectl apply -f ./templates/cluster-role-binding.yaml


echo
echo "Use this token to login on http://localhost :"
echo
kubectl get -n kubernetes-dashboard secret/admin-user-secret -o=jsonpath='{.data.token}' | base64 -d
echo
echo
