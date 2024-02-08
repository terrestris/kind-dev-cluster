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

    ./wait_until_pods_have_started.sh "kubernetes-dashboard" "k8s-app=kubernetes-dashboard"

    echo
    echo "Use this token to login on http://localhost :"
    echo
    kubectl get -n kubernetes-dashboard secret/admin-user-secret -o=jsonpath='{.data.token}' | base64 -d
    echo
    echo
fi
