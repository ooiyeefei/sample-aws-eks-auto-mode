#!/bin/bash
set -e
eval "$(jq -r '@sh "NAMESPACE=\(.namespace) SERVICE_NAME=\(.service_name)"')"

# This script now includes the --kubeconfig flag for robustness
KUBECONFIG_PATH="/tmp/kubeconfig"

# Poll for the hostname
for i in {1..60}; do
  HOSTNAME=$(kubectl --kubeconfig "$KUBECONFIG_PATH" get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  if [ -n "$HOSTNAME" ]; then
    jq -n --arg hostname "$HOSTNAME" '{"hostname": $hostname}'
    exit 0
  fi
  sleep 5
done
exit 1