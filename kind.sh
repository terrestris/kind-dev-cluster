#!/usr/bin/env bash

# Software versions
INGRESS_NGINX_VERSION="v1.13.2"
ARGO_WORKFLOWS_VERSION="v3.7.2"

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

DATA_DIR="./data"
DOCKER_REGISTRY_PROXY_DIR="./docker-registry-proxy"
DOCKER_REGISTRY_PROXY_SERVICE="docker-registry-proxy"

# Ensure required data directories exist
# These dirs are ignored by git via .gitignore
mkdir -p "$DOCKER_REGISTRY_PROXY_DIR/docker_mirror_cache"
mkdir -p "$DOCKER_REGISTRY_PROXY_DIR/docker_mirror_certs"
mkdir -p "$DATA_DIR/argo-workflow"

# Name of the Docker network we want to ensure exists
NETWORK_NAME="kind"

# Check if a Docker network with this name already exists
# --format '{{.Name}}' lists only the names of all networks
# grep -wq searches for an exact match quietly (no output)
if ! docker network ls --format '{{.Name}}' | grep -wq "$NETWORK_NAME"; then
  # If the network does NOT exist, create it
  echo "Network '$NETWORK_NAME' does not exist. Creating it..."
  docker network create "$NETWORK_NAME"
else
  # If the network already exists, do nothing
  echo "Network '$NETWORK_NAME' already exists. Nothing to do."
fi

# Start docker-registry-proxy compose from subfolder
echo "Starting $DOCKER_REGISTRY_PROXY_SERVICE service..."
docker compose -f "$DOCKER_REGISTRY_PROXY_DIR/docker-compose.yml" up -d

# Wait for the service to become healthy
echo "Waiting for $DOCKER_REGISTRY_PROXY_SERVICE to become healthy..."
while true; do
    STATUS=$(docker inspect --format='{{.State.Health.Status}}' $DOCKER_REGISTRY_PROXY_SERVICE)
    echo "Current status: $STATUS"

    if [ "$STATUS" == "healthy" ]; then
        echo "$DOCKER_REGISTRY_PROXY_SERVICE is healthy. Starting the cluster now."
        break
    elif [ "$STATUS" == "unhealthy" ]; then
        echo "$DOCKER_REGISTRY_PROXY_SERVICE is unhealthy. Exiting."
        exit 1
    fi

    sleep 2
done

# create the cluster based on the config
kind create cluster --config kind-cluster.yaml

SETUP_URL=http://docker-registry-proxy:3128/setup/systemd
pids=""

# Save the list of nodes into a variable
NODES=$(kind get nodes --name "kind-dev-cluster")

echo "Found nodes: $NODES"

# Loop through each node and execute the curl command inside it
for NODE in $NODES; do
  echo "Starting configuration for node: $NODE"

  docker exec "$NODE" sh -c "\
      curl $SETUP_URL \
      | sed s/docker\.service/containerd\.service/g \
      | sed '/Environment/ s/$/ \"NO_PROXY=127.0.0.0\/8,10.0.0.0\/8,172.16.0.0\/12,192.168.0.0\/16\"/' \
      | bash" &

  pid=$!
  pids="$pids $pid"
  echo "Started background process for node $NODE (PID: $pid)"
done

echo "Wait for all configurations to complete..."
wait $pids
echo "All configurations completed."

# Add repositories for Helm charts
echo "Adding kubernetes-dashboard Helm repository..."
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update kubernetes-dashboard

# create admin user and apply cluster role bindings
kubectl create serviceaccount admin-user -n kube-system
kubectl create clusterrolebinding admin-user-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:admin-user

# install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-${INGRESS_NGINX_VERSION}/deploy/static/provider/kind/deploy.yaml

# install the Kubernetes dashboard
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

# Install argo
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/${ARGO_WORKFLOWS_VERSION}/install.yaml
kubectl -n argo set env deployment/argo-server ARGO_BASE_HREF=/argo

# Create persistent volumes and claims for argo workflow data
kubectl apply -f templates/volumes.yaml
echo "Created persistent volumes and claims for argo workflow data"

# Create Argo workflow user with admin rights in the argo namespace
kubectl create serviceaccount workflow-user -n argo

# Create a RoleBinding giving workflow-user admin permissions in the argo namespace
kubectl create rolebinding workflow-user-admin-binding \
  --clusterrole=admin \
  --serviceaccount=argo:workflow-user \
  -n argo

kubectl rollout restart deployment argo-server -n argo

./wait_until_pods_have_started.sh "ingress-nginx" "app.kubernetes.io/instance=ingress-nginx" 1 2
./wait_until_pods_have_started.sh "kubernetes-dashboard" "app.kubernetes.io/instance=kubernetes-dashboard" 5 2

# Apply ingress resources
kubectl apply -f ./templates/ingress.yaml

echo
echo "Use this token to login on https://localhost/dashboard or https://localhost/argo :"
echo
# Create a token for the admin user
kubectl create token admin-user -n kube-system --duration=24h
echo
echo
