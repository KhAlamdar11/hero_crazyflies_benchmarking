#!/bin/bash
set -e

TYPE=$1

if [[ "$TYPE" != "real" && "$TYPE" != "sim" ]]; then
  echo "Usage: $0 [real|sim]"
  exit 1
fi

IMAGE_NAME="crazy_${TYPE}"

docker build --target "$TYPE" -t "$IMAGE_NAME" .

echo "Built $IMAGE_NAME"