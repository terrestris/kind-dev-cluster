#!/bin/bash

container_name="kind-dev-cluster-control-plane"
max_attempts=30
sleep_interval=5

# Check if the container is running
if [ "$(docker inspect -f '{{.State.Running}}' $container_name 2>/dev/null)" == "true" ]; then
    # Container is running, stop it
    echo "Stopping container $container_name..."
    docker stop $container_name
else
    # Container is not running, start it
    echo "Starting container $container_name..."
    docker start $container_name

    ./wait_until_pods_have_started.sh "kubernetes-dashboard" "app.kubernetes.io/instance=kubernetes-dashboard"

    echo
    echo "Use this token to login on https://localhost/dashboard or https://localhost/argo :"
    echo
    kubectl create token admin-user -n kube-system
    echo
    echo
fi
