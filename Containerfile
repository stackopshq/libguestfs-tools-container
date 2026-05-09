# syntax: oci
# Base: Rocky Linux 10 UBI (non-init).
# The libguestfs appliance boots its own kernel/init inside a child VM —
# the host container needs no systemd-as-pid1, so we use :10-ubi (not :10-ubi-init).
# Digest pinned for reproducibility; bumped by Renovate (see renovate.json).
FROM quay.io/rockylinux/rockylinux:10-ubi@sha256:505425723e64988f3b2cbf640cdb576597f5e427bc9716a516a6673e49464eb6

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
RUN dnf -y install epel-release && \
    dnf config-manager --set-enabled crb && \
    dnf -y install --setopt=install_weak_deps=False --nodocs \
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
    mkdir -p /workspace

WORKDIR /workspace

CMD ["/bin/bash"]
