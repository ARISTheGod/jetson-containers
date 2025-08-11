#!/usr/bin/env bash
set -euo pipefail

echo "Installing NCCL ${NCCL_VERSION} for ${DISTRO}/${CUDA_ARCH}"

# 1. Skip Jetson (JetPack already bundles NCCL)
[[ "${CUDA_ARCH}" == "tegra-aarch64" ]] && {
    echo "Jetson detected – skipping NCCL download."
    exit 0
}

# 2. Derive CUDA series (e.g. 12.6, 13.0) from full CUDA_VERSION
CUDA_SERIES="${CUDA_VERSION%.*}"

# 3. Select arch suffix used by NVIDIA repos
case "${CUDA_ARCH}" in
    aarch64|sbsa) ARCH=arm64 ;;
    x86_64)       ARCH=amd64 ;;
    *)            echo "Unknown CUDA_ARCH '${CUDA_ARCH}'" ; exit 1 ;;
esac

DEB_FILE="nccl-local-repo-${DISTRO}-${NCCL_VERSION}-cuda${CUDA_SERIES}_1.0-1_${ARCH}.deb"
BASE_URL="https://developer.download.nvidia.com/compute/machine-learning/repos"
DEB_URL="${BASE_URL}/${DISTRO}/${CUDA_ARCH}/${DEB_FILE}"

echo "• Download URL: ${DEB_URL}"

# 4. Download & install
cd "${TMP}"
wget -q --show-progress --retry 3 --timeout 30 "${DEB_URL}"
dpkg -i "${DEB_FILE}"

# 5. Import key & install libs
REPO_DIR="/var/${DEB_FILE%.deb}"
cp "${REPO_DIR}"/*.gpg /usr/share/keyrings/
apt-get update
apt-get install -y --no-install-recommends libnccl2 libnccl-dev

# 6. Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf "${TMP:?}/"*

echo "NCCL ${NCCL_VERSION} installation complete."
