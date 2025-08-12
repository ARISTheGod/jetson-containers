#!/usr/bin/env bash
set -euo pipefail

echo "Testing NCCL installation..."

# Primary Test: Verify that the essential library and header files were installed.
echo "Verifying essential library and header files in /usr/local/..."
if [ ! -f "/usr/local/lib/libnccl.so" ]; then
    echo "Error: NCCL shared library (libnccl.so) not found in /usr/local/lib."
    exit 1
fi
echo "OK: Found /usr/local/lib/libnccl.so"

if [ ! -f "/usr/local/include/nccl.h" ]; then
    echo "Error: NCCL header file (nccl.h) not found in /usr/local/include."
    exit 1
fi
echo "OK: Found /usr/local/include/nccl.h"

# Secondary Test: Check for dpkg registration as a non-critical verification.
echo "Performing secondary check for dpkg package registration..."
if ! dpkg -l | grep -q libnccl2; then
    echo "Warning: Package 'libnccl2' was not found in the dpkg database."
    echo "This is acceptable since the core library files were found in /usr/local."
else
    echo "OK: Package 'libnccl2' is registered with dpkg."
    INSTALLED_VERSION=$(dpkg -s libnccl2 | grep Version | cut -d ' ' -f2 | cut -d '+' -f1)
    if [[ "${INSTALLED_VERSION}" != "${NCCL_VERSION}" ]]; then
        echo "Error: dpkg version (${INSTALLED_VERSION}) does not match expected version (${NCCL_VERSION})."
        exit 1
    fi
    echo "OK: dpkg version (${INSTALLED_VERSION}) matches expected version."
fi

echo "NCCL installation verified successfully."
