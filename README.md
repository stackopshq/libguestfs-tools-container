<div id="top"></div>

<!-- PROJECT SHIELDS -->
<div align="center">

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![GPL-3.0 License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

</div>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/stackopshq/libguestfs-tools-container">
    <img src="images/logo.svg" alt="Logo" width="250">
  </a>

<h3 align="center">LibGuestFS Container</h3>

  <p align="center">
    OCI container with libguestfs, qemu and image manipulation tools (Podman-first)
    <br />
    <a href="https://github.com/stackopshq/libguestfs-tools-container"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/stackopshq/libguestfs-tools-container/issues">Report Bug</a>
    ·
    <a href="https://github.com/stackopshq/libguestfs-tools-container/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#getting-started">Getting Started</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#environment-variables">Environment Variables</a></li>
    <li><a href="#supported-formats">Supported Formats</a></li>
    <li><a href="#troubleshooting">Troubleshooting</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

<!-- ABOUT THE PROJECT -->
## About The Project

This project provides an OCI container image containing libguestfs, qemu, and other essential tools for virtual machine image manipulation. Based on Rocky Linux 10 UBI, this container is optimized for size and performance.

The image is built with **Buildah** and run with **Podman** (rootless-friendly, no daemon). Any OCI-compatible engine works at runtime, but all examples in this repo use `podman`.

### Variants

The image is published in two variants. Pick by tag:

| Tag                | Contents                                                                                       | Architectures      | Use case                                                                  |
|--------------------|------------------------------------------------------------------------------------------------|--------------------|---------------------------------------------------------------------------|
| `:latest`, `:slim` | libguestfs + qemu + Linux filesystem tools (ext/xfs/btrfs/fat) + parted/gdisk + cloud-utils    | amd64 + arm64      | **Default.** Building and customizing Linux VM images (virt-customize, virt-sysprep, virt-sparsify). Powers the openimages.cloud build pipeline. |
| `:full`            | Everything in `:slim` **plus** `virt-v2v` and `ntfs-3g`                                         | amd64 only*        | VMware/Hyper-V → KVM conversions, Windows guest manipulation              |

\* `virt-v2v` is not packaged for aarch64 on EPEL 10 (it converts VMs from x86 hypervisors), so the `:full` variant is published amd64-only.

Both variants are signed via cosign keyless (Sigstore) and ship with an SPDX SBOM attestation.

### Key Features

- Ready-to-use libguestfs with `direct` backend (no libvirtd required)
- Linux filesystems out of the box: ext2/3/4, XFS, BTRFS, FAT32 (NTFS only in `:full`)
- `qemu-kvm-core` (no graphical/audio subpackages) — minimal qemu surface
- Pre-tuned env vars for libguestfs appliance memory & CPU
- Provenance: OCI labels (revision, version, created, source), Cosign signature, SPDX SBOM

### Verifying the image

The image is signed keyless via GitHub OIDC. To verify before pulling:

```bash
cosign verify ghcr.io/stackopshq/libguestfs-tools:latest \
  --certificate-identity-regexp '^https://github.com/stackopshq/libguestfs-tools-container/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

The SBOM is attached as a cosign attestation:

```bash
cosign download attestation ghcr.io/stackopshq/libguestfs-tools:latest \
  --predicate-type https://spdx.dev/Document
```

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started

### Prerequisites

- [Podman](https://podman.io/) 4.0 or later installed on your system
- Sufficient disk space for your VM images
- Basic knowledge of libguestfs tools
- For advanced operations: ability to run containers with `--privileged`
- Optional: `/dev/kvm` access for better performance with nested virtualization

> **SELinux note:** on Enforcing hosts (RHEL/Rocky/Fedora), append `:Z` to bind-mount sources (e.g. `-v ./images:/workspace/images:Z`) so Podman relabels the volume for the container. Without this you'll hit permission denied errors.

### Installation

Pull the image from GitHub Container Registry:
```bash
podman pull ghcr.io/stackopshq/libguestfs-tools:latest        # slim (default)
podman pull ghcr.io/stackopshq/libguestfs-tools:full          # with virt-v2v + ntfs-3g
podman pull ghcr.io/stackopshq/libguestfs-tools:v1            # pinned major (slim)
podman pull ghcr.io/stackopshq/libguestfs-tools:v1.0.0-full   # pinned full
```

### Building Locally

To build the image yourself:
```bash
git clone https://github.com/stackopshq/libguestfs-tools-container.git
cd libguestfs-tools-container

# Slim (default)
podman build -t libguestfs-tools:local .

# Full (with virt-v2v + ntfs-3g)
podman build --build-arg VARIANT=full -t libguestfs-tools:local-full .
```

### Using Compose

A [`compose.yml`](compose.yml) file is provided for easier container management. With [`podman-compose`](https://github.com/containers/podman-compose):

```bash
podman-compose run --rm libguestfs-tools bash
```

Or run specific commands:
```bash
podman-compose run --rm libguestfs-tools virt-df -a /workspace/images/my-vm.qcow2
```

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- USAGE EXAMPLES -->
## Usage

### Basic Usage

1. **Mount a volume to share images with the container**
   ```bash
   podman run --rm -v /local/path/images:/workspace/images:Z \
     ghcr.io/stackopshq/libguestfs-tools \
     virt-df -a /workspace/images/my-vm.qcow2
   ```

2. **Run libguestfs tools interactively**
   ```bash
   podman run --rm -it -v /local/path/images:/workspace/images:Z \
     ghcr.io/stackopshq/libguestfs-tools bash
   ```

3. **Execute specific commands**
   ```bash
   podman run --rm -v /local/path/images:/workspace/images:Z \
     ghcr.io/stackopshq/libguestfs-tools \
     virt-customize -a /workspace/images/my-vm.qcow2 --install nginx
   ```

### Advanced Examples

#### Converting VMware to qcow2 format (requires `:full` variant)

```bash
podman run --rm -v /local/path/images:/workspace/images:Z \
  ghcr.io/stackopshq/libguestfs-tools:full \
  virt-v2v -i ova /workspace/images/source-vm.ova -o local -os /workspace/images -of qcow2
```

#### Inspecting a VM image

```bash
podman run --rm -v /local/path/images:/workspace/images:Z \
  ghcr.io/stackopshq/libguestfs-tools \
  virt-inspector /workspace/images/my-vm.qcow2
```

#### Resizing a disk image

```bash
podman run --rm -v /local/path/images:/workspace/images:Z \
  ghcr.io/stackopshq/libguestfs-tools \
  qemu-img resize /workspace/images/my-vm.qcow2 +10G
```

#### Mounting and exploring filesystem

```bash
podman run --rm -it --privileged -v /local/path/images:/workspace/images:Z \
  ghcr.io/stackopshq/libguestfs-tools \
  guestmount -a /workspace/images/my-vm.qcow2 -m /dev/sda1 /mnt
```

### Example Scripts

The `examples/` directory contains ready-to-use shell scripts for common operations:

- **convert-vmdk-to-qcow2.sh** - Convert VMware images to QCOW2 format
- **inspect-vm-image.sh** - Inspect VM images for OS and application details
- **customize-vm.sh** - Customize VM images by installing packages

See the [examples/README.md](examples/README.md) for detailed usage instructions.

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- ENVIRONMENT VARIABLES -->
## Environment Variables

The container is configured with the following environment variables for libguestfs:

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `LIBGUESTFS_BACKEND` | `direct` | Uses direct backend (no nested VM) |
| `LIBGUESTFS_DEBUG` | `0` | Set to `1` to enable debug output |
| `LIBGUESTFS_TRACE` | `0` | Set to `1` to enable function tracing |
| `LIBGUESTFS_PROGRESS` | `1` | Shows progress bars during operations |
| `LIBGUESTFS_VERBOSE` | `0` | Set to `1` for verbose output |
| `LIBGUESTFS_MEMSIZE` | `4096` | Memory size in MB for libguestfs appliance |
| `LIBGUESTFS_SMP` | `4` | Number of virtual CPUs for libguestfs appliance |

### Overriding Environment Variables

You can override these values when running the container:

```bash
podman run --rm -e LIBGUESTFS_VERBOSE=1 -e LIBGUESTFS_DEBUG=1 \
  -v /local/path:/workspace/images:Z \
  ghcr.io/stackopshq/libguestfs-tools
```

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- SUPPORTED FORMATS -->
## Supported Formats

### Input Formats (read by `qemu-img` and `virt-*` tools)
- qcow2, raw, VMDK, VDI, VHD/VHDX (handled natively by `qemu-img`)
- OVA / OVF — **`:full` only** (requires `virt-v2v`)

### Output Formats
- qcow2 (recommended for KVM/OpenStack — sparse, snapshots, compression)
- raw (fastest, largest)
- VMDK (for VMware compat)
- VDI (for VirtualBox compat)

### Filesystem Support
- **`:slim` (default)** — Linux: ext2/3/4, XFS, BTRFS · FAT32 · ISO9660/UDF
- **`:full`** — adds NTFS (read/write) for Windows guests via `ntfs-3g`

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- TROUBLESHOOTING -->
## Troubleshooting

### Common Issues

**Permission denied on bind mounts (SELinux):**
The host is running SELinux in Enforcing mode. Append `:Z` to the volume so Podman relabels it for the container, e.g. `-v ./images:/workspace/images:Z`. Never disable SELinux as a workaround.

**Permission denied for privileged operations:**
```bash
# Run with --privileged for guestmount, direct device access, etc.
podman run --rm --privileged -v /local/path:/workspace/images:Z \
  ghcr.io/stackopshq/libguestfs-tools
```

**Enable verbose output for debugging:**
```bash
podman run --rm -e LIBGUESTFS_VERBOSE=1 -e LIBGUESTFS_DEBUG=1 \
  -v /local/path:/workspace/images:Z \
  ghcr.io/stackopshq/libguestfs-tools
```

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

### How to Contribute

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Don't forget to give the project a star! ⭐ Thanks again!

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- LICENSE -->
## License

Distributed under the GPL-3.0 License. See [`LICENSE`](LICENSE) for more information.

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- CONTACT -->
## Contact

**Kevin Allioli**
- Twitter: [@stackopshq](https://twitter.com/stackopshq)
- Email: kevin@stackops.ch
- LinkedIn: [kevinallioli](https://linkedin.com/in/kevinallioli)

**Project Links:**
- Repository: [https://github.com/stackopshq/libguestfs-tools-container](https://github.com/stackopshq/libguestfs-tools-container)
- Issues: [Report a Bug](https://github.com/stackopshq/libguestfs-tools-container/issues)
- Container Registry: [ghcr.io/stackopshq/libguestfs-tools](https://github.com/stackopshq/libguestfs-tools-container/pkgs/container/libguestfs-tools)

<p align="right">(<a href="#top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/stackopshq/libguestfs-tools-container.svg?style=for-the-badge
[contributors-url]: https://github.com/stackopshq/libguestfs-tools-container/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/stackopshq/libguestfs-tools-container.svg?style=for-the-badge
[forks-url]: https://github.com/stackopshq/libguestfs-tools-container/network/members
[stars-shield]: https://img.shields.io/github/stars/stackopshq/libguestfs-tools-container.svg?style=for-the-badge
[stars-url]: https://github.com/stackopshq/libguestfs-tools-container/stargazers
[issues-shield]: https://img.shields.io/github/issues/stackopshq/libguestfs-tools-container.svg?style=for-the-badge
[issues-url]: https://github.com/stackopshq/libguestfs-tools-container/issues
[license-shield]: https://img.shields.io/github/license/stackopshq/libguestfs-tools-container.svg?style=for-the-badge
[license-url]: https://github.com/stackopshq/libguestfs-tools-container/blob/main/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/kevinallioli
