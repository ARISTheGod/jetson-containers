#!/usr/bin/env bash
set -euo pipefail

echo "Building NCCL v${NCCL_VERSION} from source on Jetson..."

# Verify CUDA is installed
if [ ! -d "/usr/local/cuda" ]; then
    echo "Error: CUDA_HOME not found at /usr/local/cuda. Please ensure CUDA is installed."
    exit 1
fi

# Create a temporary directory for the build
TMP_DIR=$(mktemp -d)
cd "${TMP_DIR}"

# Clone the specific NCCL release tag
echo "Cloning NCCL repository tag v${NCCL_VERSION}-1..."
git clone --branch "v${NCCL_VERSION}-1" --depth 1 https://github.com/NVIDIA/nccl.git
cd nccl

# Build NCCL from source code
echo "Compiling NCCL source..."
make -j$(nproc) src.build CUDA_HOME=/usr/local/cuda

# Build the .deb packages from the compiled source
echo "Building Debian packages..."
make -j$(nproc) pkg.debian.build

# Install the generated Debian packages directly
echo "Installing generated .deb packages using dpkg..."
dpkg -i build/pkg/deb/libnccl2_*.deb
dpkg -i build/pkg/deb/libnccl-dev_*.deb

# Also run 'make install' to place files in /usr/local for maximum compatibility
echo "Running 'make install' to place libraries in /usr/local..."
make install PREFIX=/usr/local

# Clean up temporary build files
echo "Cleaning up..."
rm -rf "${TMP_DIR}"
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "NCCL ${NCCL_VERSION} has been successfully built from source, packaged, and installed."
