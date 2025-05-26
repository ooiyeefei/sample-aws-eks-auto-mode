#!/bin/bash

# Script to update LiteLLM API keys in AWS Secrets Manager
# This script reads from ../.env file and updates the secret created by Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}LiteLLM API Keys Update Script${NC}"
echo "================================"

# Check if .env file exists
ENV_FILE="../.env"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: .env file not found at $ENV_FILE${NC}"
    echo "Please create .env file from .env.tpl template and add your API keys"
    exit 1
fi

# Get the secret name from Terraform output
echo "Getting secret name from Terraform..."
cd ../terraform
SECRET_ARN=$(terraform output -raw litellm_api_keys_secret_arn 2>/dev/null)
if [ -z "$SECRET_ARN" ]; then
    echo -e "${RED}Error: Could not get secret ARN from Terraform output${NC}"
    echo "Make sure you have run 'terraform apply' first"
    exit 1
fi
# Extract just the secret name without the version suffix
SECRET_NAME=$(echo $SECRET_ARN | awk -F: '{print $7}' | awk -F- '{for(i=1;i<=NF-1;i++) printf "%s%s", $i, (i<NF-1?"-":"")}')
cd - > /dev/null

echo -e "Secret name: ${YELLOW}$SECRET_NAME${NC}"

# Parse .env file and create JSON dynamically
echo "Parsing .env file for API keys..."
echo "{" > /tmp/litellm-api-keys.json

# Read .env file and extract all KEY=VALUE pairs (excluding comments and empty lines)
first_entry=true
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    if [[ ! "$key" =~ ^[[:space:]]*# ]] && [[ -n "$key" ]]; then
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Remove quotes if present
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"
        
        # Add comma for all entries except the first
        if [ "$first_entry" = true ]; then
            first_entry=false
        else
            echo "," >> /tmp/litellm-api-keys.json
        fi
        
        # Write the key-value pair to JSON
        printf '  "%s": "%s"' "$key" "$value" >> /tmp/litellm-api-keys.json
    fi
done < "$ENV_FILE"

echo "" >> /tmp/litellm-api-keys.json
echo "}" >> /tmp/litellm-api-keys.json

# Show what keys were found
echo "Found the following API keys:"
grep -E '^\s*"[^"]+":' /tmp/litellm-api-keys.json | sed 's/.*"\([^"]*\)".*/  - \1/'

# Update the secret in AWS Secrets Manager
echo "Updating secret in AWS Secrets Manager..."
if aws secretsmanager put-secret-value \
    --secret-id "$SECRET_NAME" \
    --secret-string file:///tmp/litellm-api-keys.json \
    --region $(aws configure get region) 2>/dev/null; then
    echo -e "${GREEN}✓ Secret updated successfully!${NC}"
else
    echo -e "${RED}Error: Failed to update secret${NC}"
    rm -f /tmp/litellm-api-keys.json
    exit 1
fi

# Clean up
rm -f /tmp/litellm-api-keys.json

# Check if External Secrets Operator will sync
echo ""
echo "Checking External Secrets sync status..."
kubectl get externalsecret litellm-api-keys -n litellm -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -q "True"
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ External Secrets Operator is ready and will sync the changes${NC}"
else
    echo -e "${YELLOW}⚠ External Secrets Operator sync status unknown. It may take a few minutes to sync.${NC}"
fi

echo ""
echo -e "${GREEN}API keys have been updated in AWS Secrets Manager!${NC}"
echo ""
echo "Next steps:"
echo "1. Wait for External Secrets Operator to sync (usually within 15 minutes)"
echo "2. Restart LiteLLM deployment to pick up new keys:"
echo "   kubectl rollout restart deployment litellm-deployment -n litellm"
echo ""
echo "To verify the secret was synced to Kubernetes:"
echo "   kubectl get secret litellm-api-keys -n litellm"
