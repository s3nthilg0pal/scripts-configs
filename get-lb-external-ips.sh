#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./get-lb-external-ips.sh [namespace]
#
# If namespace is provided, list LoadBalancer services in that namespace.
# Otherwise, list all LoadBalancer services across all namespaces.
#
# Output: Table format with SERVICE and EXTERNAL_IP columns

NAMESPACE="${1:-}"

if [ -n "$NAMESPACE" ]; then
  SERVICES=$(kubectl get svc -n "$NAMESPACE" --field-selector spec.type=LoadBalancer -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name} {.status.loadBalancer.ingress[0].ip}{"\n"}{end}')
else
  SERVICES=$(kubectl get svc --all-namespaces --field-selector spec.type=LoadBalancer -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name} {.status.loadBalancer.ingress[0].ip}{"\n"}{end}')
fi

if [ -n "$SERVICES" ]; then
  printf "%-50s %-20s\n" "SERVICE" "EXTERNAL_IP"
  printf "%-50s %-20s\n" "--------------------------------------------- " "-------------------"
  echo "$SERVICES" | while IFS= read -r line; do
    if [ -n "$line" ]; then
      printf "%-50s %-20s\n" $line
    fi
  done
else
  echo "No LoadBalancer services found."
fi