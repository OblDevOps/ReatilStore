#!/bin/bash
set -e

ACCOUNT_ID="603084994385"
REGION="us-east-1"
REGISTRY="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

SERVICES=("ui" "catalog" "cart" "orders" "checkout" "admin" "db")

echo "→ Login a ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY

for SERVICE in "${SERVICES[@]}"; do
  echo "Build $SERVICE..."
  docker build -t $REGISTRY/$SERVICE:latest src/$SERVICE/

  echo "Push $SERVICE..."
  docker push $REGISTRY/$SERVICE:latest
done

echo "Todas las imágenes subidas"