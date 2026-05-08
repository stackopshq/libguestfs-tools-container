#!/bin/bash
# Example: Convert VMware VMDK to QCOW2 format

set -euo pipefail

IMAGE_DIR="${IMAGE_DIR:-./images}"
SOURCE_IMAGE="${1:-source.vmdk}"
OUTPUT_IMAGE="${2:-output.qcow2}"
IMAGE="${IMAGE:-ghcr.io/stackopshq/libguestfs-tools:latest}"

echo "Converting $SOURCE_IMAGE to $OUTPUT_IMAGE..."

podman run --rm \
  -v "$IMAGE_DIR:/workspace/images:Z" \
  "$IMAGE" \
  qemu-img convert -f vmdk -O qcow2 \
  "/workspace/images/$SOURCE_IMAGE" \
  "/workspace/images/$OUTPUT_IMAGE"

echo "Conversion complete!"
echo "Output file: $IMAGE_DIR/$OUTPUT_IMAGE"
