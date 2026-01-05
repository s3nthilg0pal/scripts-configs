#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./create-sealed-secret.sh <namespace> <secret-name> KEY=VALUE [KEY=VALUE...]
#
# Example:
#   ./create-sealed-secret.sh blinko gym-ollama-secret OLLAMA_URL=http://192.168.0.162:11434

if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <namespace> <secret-name> KEY=VALUE [KEY=VALUE...]"
  exit 1
fi

NAMESPACE="$1"
SECRET_NAME="$2"
shift 2

ENV_VARS=("$@")

echo "Ensuring namespace '$NAMESPACE' exists..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

SECRET_FILE="$(mktemp)"
SEALED_FILE="${SECRET_NAME}-sealed.yaml"

echo "Generating Kubernetes Secret manifest '$SECRET_FILE'..."
FROM_LITERALS=()
for kv in "${ENV_VARS[@]}"; do
  FROM_LITERALS+=(--from-literal="$kv")
done

kubectl -n "$NAMESPACE" create secret generic "$SECRET_NAME" \
  "${FROM_LITERALS[@]}" \
  --dry-run=client -o yaml > "$SECRET_FILE"

echo "Sealing secret to '$SEALED_FILE'..."
kubeseal \
  --controller-name=sealed-secrets \
  --controller-namespace=kube-system \
  --format yaml < "$SECRET_FILE" > "$SEALED_FILE"

echo "Securely deleting plain secret file..."
shred -u "$SECRET_FILE" 2>/dev/null || rm -f "$SECRET_FILE"

echo "Done."
echo "SealedSecret written to: $SEALED_FILE"