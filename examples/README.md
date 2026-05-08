# Examples

This directory contains example scripts demonstrating common use cases for the LibGuestFS Tools container.

## Available Examples

### 1. Convert VMDK to QCOW2
**File:** [`convert-vmdk-to-qcow2.sh`](convert-vmdk-to-qcow2.sh)

Converts a VMware VMDK image to QCOW2 format.

```bash
export IMAGE_DIR=/path/to/images
./convert-vmdk-to-qcow2.sh source.vmdk output.qcow2
```

### 2. Inspect VM Image
**File:** [`inspect-vm-image.sh`](inspect-vm-image.sh)

Inspects a VM image to retrieve OS information, installed applications, and filesystem details.

```bash
export IMAGE_DIR=/path/to/images
./inspect-vm-image.sh vm-image.qcow2
```

### 3. Customize VM Image
**File:** [`customize-vm.sh`](customize-vm.sh)

Customizes a VM image by installing packages and running commands.

```bash
export IMAGE_DIR=/path/to/images
./customize-vm.sh vm-image.qcow2
```

## Usage Notes

- All scripts use the `IMAGE_DIR` environment variable to specify the directory containing VM images
- Default value for `IMAGE_DIR` is `./images`
- The container image can be overridden via the `IMAGE` environment variable (default: `ghcr.io/stackopshq/libguestfs-tools:latest`)
- Make scripts executable: `chmod +x examples/*.sh`
- Podman must be installed and operational before executing scripts
- On SELinux Enforcing hosts the scripts use `:Z` on bind mounts so Podman relabels the volume

## Creating Custom Scripts

You can use these examples as templates for your own automation scripts. The general pattern is:

```bash
podman run --rm \
  -v "$IMAGE_DIR:/workspace/images:Z" \
  ghcr.io/stackopshq/libguestfs-tools:latest \
  <libguestfs-command> <arguments>
```

For interactive work, add `-it` flags and use `bash` as the command.
