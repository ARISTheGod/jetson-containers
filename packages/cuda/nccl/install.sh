#!/usr/bin/env bash
set -euo pipefail

echo "Starting NCCL ${NCCL_VERSION} installation for ${DISTRO}/${CUDA_ARCH}"

if [ -z "${DISTRO:-}" ]; then
    echo "Error: DISTRO not set. Please ensure it is provided via build arguments."
    exit 1
fi

# On Jetson (tegra-aarch64) or if FORCE_BUILD is on, build from source.
# Otherwise, download the pre-built packages for x86/sbsa.
if [[ "${FORCE_BUILD:-off}" == "on" ]] || [[ "${CUDA_ARCH}" == "tegra-aarch64" ]]; then
    /tmp/nccl/build.sh
else
    echo "Downloading NCCL package for ${CUDA_ARCH}..."
    CUDA_SERIES="${CUDA_VERSION%.*}"
    
    case "${CUDA_ARCH}" in
        aarch64|sbsa) ARCH=arm64 ; SUBDIR=sbsa ;;
        x86_64)       ARCH=amd64 ; SUBDIR=x86_64 ;;
        *)            echo "Unknown CUDA_ARCH '${CUDA_ARCH}'"; exit 1 ;;
    esac

    DEB_FILE="nccl-local-repo-${DISTRO}-${NCCL_VERSION}-cuda${CUDA_SERIES}_1.0-1_${ARCH}.deb"
    BASE_URL="https://developer.download.nvidia.com/compute/machine-learning/repos"
    DEB_URL="${BASE_URL}/${DISTRO}/${SUBDIR}/${DEB_FILE}"
    
    echo "Download URL: ${DEB_URL}"
    cd "/tmp"
    wget -q --show-progress --retry=3 --timeout=30 "${DEB_URL}"
    dpkg -i "${DEB_FILE}"
    
    REPO_DIR="/var/${DEB_FILE%.deb}"
    cp "${REPO_DIR}"/*.gpg /usr/share/keyrings/
    
    apt-get update
    apt-get install -y --no-install-recommends libnccl2 libnccl-dev
    echo "NCCL ${NCCL_VERSION} package installation complete."
fi

# General cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*
echo "NCCL installation process finished."
