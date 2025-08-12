#---
# name: nccl
# group: cuda
# depends: [cuda]
# config: config.py
# test: test.sh
#---
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG NCCL_VERSION \
    CUDA_ARCH \
    IS_SBSA \
    FORCE_BUILD=off \
    DISTRO \
    TMP=/tmp/nccl

# Install build tools (only if needed; optimize for source builds)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    devscripts \
    debhelper \
    fakeroot \
    pkg-config \
    git \
    dkms && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy install.sh and build.sh
COPY install.sh build.sh /tmp/nccl/
RUN chmod +x /tmp/nccl/build.sh

# Run the main install script
RUN /tmp/nccl/install.sh
