#!/usr/bin/env bash

# Script to wait for applied Kubernetes resources and
# ensure that all underlying pods are fully created and running.

APP_NAME=$1        # Kubernetes namespace (application name)
SELECTOR=$2        # Label selector to identify pods
EXPECTED_LENGTH=$3 # Expected number of pods
SLEEP_TIME=$4      # Time to sleep between checks (in seconds)

# --- Step 1: Wait until all expected resources (pods) are created ---
if [ ! -z "$3" ]; then
  echo "[$APP_NAME] Checking if all pod(s) have been created..."

  # Get current number of pods in the namespace
  RESULT_LEN="$(kubectl get pod -n $APP_NAME -o go-template='{{.items | len}}')"
  echo "[$APP_NAME] Currently found $RESULT_LEN/$EXPECTED_LENGTH pod(s)."

  # Keep polling until the expected number of pods are created
  until test $RESULT_LEN -eq $EXPECTED_LENGTH; do
      echo "[$APP_NAME] Waiting... ($RESULT_LEN/$EXPECTED_LENGTH pods ready)"
      sleep $SLEEP_TIME
      RESULT_LEN="$(kubectl get pod -n $APP_NAME -o go-template='{{.items | len}}')"
  done

  echo "[$APP_NAME] All $EXPECTED_LENGTH pod(s) have been created."
fi

# --- Step 2: Wait until all pods are actually ready ---
echo "[$APP_NAME] Waiting for pods to become Ready (selector: $SELECTOR)..."
kubectl wait --namespace $APP_NAME --for=condition=Ready pod --selector=$SELECTOR --timeout=900s

echo "[$APP_NAME] ✅ All pods are Ready and fully available."
