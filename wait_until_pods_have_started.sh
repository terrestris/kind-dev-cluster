#!/usr/bin/env bash

# script to wait for applied resources and
# the underlying pods to be fully created and started

APP_NAME=$1
SELECTOR=$2
EXPECTED_LENGTH=$3
SLEEP_TIME=$4

if [ ! -z "$3" ]; then
  echo "Waiting for $APP_NAME resources to be fully created"
  RESULT_LEN="$(kubectl get pod -n $APP_NAME -o go-template='{{.items | len}}')"
  until test $RESULT_LEN -eq $EXPECTED_LENGTH; do
      sleep $SLEEP_TIME
      RESULT_LEN="$(kubectl get pod -n $APP_NAME -o go-template='{{.items | len}}')"
  done
  echo "Resources for $APP_NAME have been fully created. The pods will start now."
fi

# wait until the controller pod has fully started
echo "Waiting for $APP_NAME pods to be fully available"
kubectl wait --namespace $APP_NAME --for=condition=Ready pod --selector=$SELECTOR --timeout=90s
echo "Pods for $APP_NAME have started and are fully available now"
