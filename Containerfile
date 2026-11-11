# syntax: oci
# Base: Rocky Linux 10 UBI (non-init).
# The libguestfs appliance boots its own kernel/init inside a child VM —
# the host container needs no systemd-as-pid1, so we use :10-ubi (not :10-ubi-init).
# Digest pinned for reproducibility; bumped by Renovate (see renovate.json).
FROM quay.io/rockylinux/rockylinux:10-ubi@sha256:b316080c3c3cc005af04d71e66bc7a4a3efd50dba43dee641efffdddc79c9441

# Build-time provenance (passed by CI via --build-arg).
ARG VERSION=dev
ARG COMMIT_SHA=
ARG BUILD_DATE=

# Variant: "slim" (default) ships only what openimages.cloud's libguestfs build
# pipeline needs (virt-customize / virt-sysprep / virt-sparsify on Linux rootfs).
# "full" adds virt-v2v + ntfs-3g for VMware/Hyper-V → KVM conversions.
ARG VARIANT=slim

LABEL maintainer="kevin@stackops.ch" \
      org.opencontainers.image.title="LibGuestFS Tools Container" \
      org.opencontainers.image.description="Container with libguestfs and qemu image manipulation tools" \
      org.opencontainers.image.authors="Kevin Allioli <kevin@stackops.ch>" \
      org.opencontainers.image.vendor="StackOps" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.url="https://github.com/stackopshq/libguestfs-tools-container" \
      org.opencontainers.image.source="https://github.com/stackopshq/libguestfs-tools-container" \
      org.opencontainers.image.documentation="https://github.com/stackopshq/libguestfs-tools-container/blob/main/README.md" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${COMMIT_SHA}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      cloud.openimages.variant="${VARIANT}"

ENV LIBGUESTFS_BACKEND=direct \
    LIBGUESTFS_DEBUG=0 \
    LIBGUESTFS_TRACE=0 \
    LIBGUESTFS_PROGRESS=1 \
    LIBGUESTFS_VERBOSE=0 \
    LIBGUESTFS_MEMSIZE=4096 \
    LIBGUESTFS_SMP=4

# Single RUN: enable EPEL+CRB, install, conditionally add v2v stack, aggressive cleanup.
#
# Why qemu-kvm-core (not qemu-kvm): the qemu-kvm meta-package pulls
# qemu-kvm-ui-opengl → mesa-dri-drivers → llvm-libs (~165 MB) for graphical
# output we never use in --display none mode.
#
# install_weak_deps=False + nodocs are mandatory for size.
#
# Why the CentOS Kmods SIG kernel (centos-release-kmods-kernel, shipped in
# Rocky "extras"): supermin builds the libguestfs appliance from the kernel
# installed in this container, and the RHEL/Rocky 10 kernel is built with
# CONFIG_BTRFS_FS unset. Guests with a btrfs root (Fedora Cloud 44+) then fail
# in virt-customize with "unknown filesystem type 'btrfs'". The Kmods SIG
# "kernel-latest" build (amd64 + arm64) has btrfs built in. kmod-btrfs for the
# distro kernel was rejected: it tracks the RHEL kABI per minor release and
# regularly lags the Rocky kernel, which would break rebuilds.
# RHEL's libguestfs also leaves btrfs-progs out of the appliance package list,
# so the "btrfs" feature group (subvolume listing, used by inspection to find
# Fedora's root subvolume) stays unavailable; packages-btrfs adds it back.
# The final checks fail the build if the appliance cannot handle btrfs.
#
# Why passt is removed: libguestfs >= 1.58 (Rocky 10.2) requires passt and
# uses it for appliance networking whenever `passt --help` runs. passt then
# sandboxes itself with unshare(CLONE_NEWUSER), which Docker's default seccomp
# profile denies without CAP_SYS_ADMIN, so in a GitHub Actions job container
# every network-enabled virt-customize fails with "passt exited with status 1".
# Without the binary, libguestfs falls back to qemu's built-in user networking
# (-netdev user / SLIRP), as up to 2.0.x. Removed with --nodeps because
# libguestfs has a hard RPM dependency on it.
RUN dnf -y install epel-release centos-release-kmods-kernel && \
    dnf config-manager --set-enabled crb && \
    dnf -y install --setopt=install_weak_deps=False --nodocs \
        kernel-core \
        kernel-modules \
        qemu-kvm-core \
        qemu-img \
        libguestfs \
        libguestfs-tools-c \
        python3-libguestfs \
        e2fsprogs \
        xfsprogs \
        btrfs-progs \
        dosfstools \
        parted \
        gdisk \
        cloud-utils-growpart \
        openssh-clients \
        file \
        kmod \
        curl \
        tar \
        gzip \
        unzip && \
    if [ "${VARIANT}" = "full" ]; then \
        dnf -y install --setopt=install_weak_deps=False --nodocs \
            virt-v2v \
            ntfs-3g ; \
    fi && \
    dnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum /var/log/* /tmp/* /var/tmp/* \
           /usr/share/{doc,man,info}/* \
           /usr/lib/.build-id \
           /root/.cache && \
    find /usr/share/locale -mindepth 1 -maxdepth 1 -type d \
        ! -name 'C' ! -name 'C.utf8' ! -name 'en' ! -name 'en_US' \
        -exec rm -rf {} + && \
    echo btrfs-progs > "$(rpm --eval '%{_libdir}')/guestfs/supermin.d/packages-btrfs" && \
    rpm -e --nodeps passt && \
    ! command -v passt && \
    /usr/libexec/qemu-kvm -netdev help | grep -qx user && \
    test "$(ls /lib/modules | wc -l)" -eq 1 && \
    grep -Eq '^CONFIG_BTRFS_FS=[ym]$' /lib/modules/*/config && \
    mkdir -p /workspace

WORKDIR /workspace

CMD ["/bin/bash"]
