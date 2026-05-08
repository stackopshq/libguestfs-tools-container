# Performance and Limitations

This document outlines performance considerations and known limitations when using the LibGuestFS Tools container.

## Performance Considerations

### Memory Configuration

The container is configured with default memory settings:
- `LIBGUESTFS_MEMSIZE=4096` (4GB RAM for the libguestfs appliance)
- `LIBGUESTFS_SMP=4` (4 virtual CPUs)

**Recommendations:**
- For large images (>50GB): Increase memory to 8192MB or more
- For multiple concurrent operations: Adjust SMP based on host CPU cores
- Monitor host memory usage to avoid swapping

```bash
podman run --rm -e LIBGUESTFS_MEMSIZE=8192 -e LIBGUESTFS_SMP=8 \
  -v ./images:/workspace/images:Z \
  ghcr.io/stackopshq/libguestfs-tools
```

### Backend Selection

The container uses `LIBGUESTFS_BACKEND=direct` by default:
- **Pros**: Faster startup, lower overhead, no nested virtualization
- **Cons**: Requires privileged mode for some operations

For better isolation, you can use the libvirt backend:
```bash
podman run --rm -e LIBGUESTFS_BACKEND=libvirt \
  -v ./images:/workspace/images:Z \
  ghcr.io/stackopshq/libguestfs-tools
```

### Disk I/O Optimization

**Tips for better performance:**
1. Use local storage (avoid NFS/network mounts when possible)
2. Use SSD storage for temporary files
3. Ensure sufficient disk space (3x the image size recommended)
4. Use qcow2 format with compression for storage efficiency

### KVM Acceleration

For operations requiring virtualization, KVM acceleration significantly improves performance:

```bash
podman run --rm --device=/dev/kvm \
  -v ./images:/workspace/images:Z \
  ghcr.io/stackopshq/libguestfs-tools
```

**Note**: Requires KVM support on the host system.

## Known Limitations

### 1. Privileged Mode Requirement

Some operations require `--privileged` flag:
- Mounting filesystems with `guestmount`
- Direct device access
- Certain filesystem operations

```bash
podman run --rm --privileged \
  -v ./images:/workspace/images:Z \
  ghcr.io/stackopshq/libguestfs-tools
```

### 2. Filesystem Support

**Fully Supported:**
- ext2, ext3, ext4
- XFS, BTRFS
- NTFS, FAT32
- ISO9660

**Limited Support:**
- ZFS (read-only in most cases)
- F2FS (requires additional packages)
- ReiserFS (deprecated)

### 3. Image Format Limitations

**Input Formats:**
- Maximum tested image size: 500GB
- Sparse files are supported
- Compressed formats may require decompression first

**Output Formats:**
- qcow2: Recommended, supports compression and snapshots
- Raw: Fastest but largest size
- VMDK: Compatible with VMware but slower conversion

### 4. Concurrent Operations

- Running multiple containers simultaneously is supported
- Each container should have dedicated memory allocation
- Avoid operating on the same image file from multiple containers

### 5. Network Operations

The container has limited network tools by default. For network-heavy operations:
- Install additional tools as needed
- Consider using a custom Containerfile extending this image

### 6. Windows Guest Support

Windows guest operations have limitations:
- Registry editing requires Windows-specific tools
- Some Windows-specific operations may not work
- NTFS support is read/write but may be slower than ext4

## Troubleshooting Performance Issues

### Slow Operations

**Symptoms:** Operations take significantly longer than expected

**Solutions:**
1. Check host CPU and memory usage
2. Increase `LIBGUESTFS_MEMSIZE` and `LIBGUESTFS_SMP`
3. Enable KVM acceleration if available
4. Use local storage instead of network mounts
5. Enable verbose logging to identify bottlenecks:
   ```bash
   podman run --rm -e LIBGUESTFS_VERBOSE=1 -e LIBGUESTFS_DEBUG=1 ...
   ```

### Out of Memory Errors

**Symptoms:** Operations fail with memory-related errors

**Solutions:**
1. Increase container memory limit:
   ```bash
   podman run --rm --memory=8g --memory-swap=16g ...
   ```
2. Increase libguestfs appliance memory:
   ```bash
   podman run --rm -e LIBGUESTFS_MEMSIZE=8192 ...
   ```
3. Process images in smaller chunks if possible

### Disk Space Issues

**Symptoms:** "No space left on device" errors

**Solutions:**
1. Ensure sufficient space in Podman's storage location (`~/.local/share/containers/storage` for rootless, `/var/lib/containers/storage` for rootful)
2. Clean up unused images and containers:
   ```bash
   podman system prune -a
   ```
3. Use external volumes with more space
4. Enable qcow2 compression for output images

## Benchmarks

Approximate performance metrics (on modern hardware):

| Operation | Image Size | Time | Notes |
|-----------|-----------|------|-------|
| qcow2 → raw conversion | 10GB | ~2 min | With SSD |
| VMDK → qcow2 conversion | 20GB | ~5 min | With compression |
| virt-inspector | 10GB | ~30 sec | Cached |
| virt-customize (package install) | 10GB | ~3 min | Network dependent |
| Filesystem mount | Any | ~5 sec | With --privileged |

**Note:** Actual performance varies based on hardware, image complexity, and operations performed.

## Best Practices

1. **Pre-allocate resources** based on expected workload
2. **Use progress monitoring** with `LIBGUESTFS_PROGRESS=1`
3. **Test with small images** before processing large ones
4. **Monitor host resources** during operations
5. **Use appropriate image formats** for your use case
6. **Keep images on fast storage** (SSD preferred)
7. **Clean up temporary files** after operations

## Getting Help

If you encounter performance issues not covered here:
1. Enable verbose logging
2. Check system resources (CPU, memory, disk)
3. Review libguestfs documentation
4. Open an issue with detailed information
