#!/bin/bash
set -e

# This script polls a Kubernetes service until its load balancer has an ingress hostname.
# It expects the namespace and service name to be passed as JSON on stdin.
# Example: echo '{"namespace":"vllm-inference", "service_name":"open-webui-service"}' | ./get-lb-hostname.sh

eval "$(jq -r '@sh "NAMESPACE=\(.namespace) SERVICE_NAME=\(.service_name)"')"

for i in {1..60}; do
  HOSTNAME=$(kubectl get service "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  if [ -n "$HOSTNAME" ]; then
    # Success! Output the hostname as a JSON object to stdout.
    jq -n --arg hostname "$HOSTNAME" '{"hostname": $hostname}'
    exit 0
  fi
  sleep 5
done

# Failure: If the loop finishes, exit with an error.
jq -n '{"error": "timed out waiting for load balancer hostname"}' >&2
exit 1