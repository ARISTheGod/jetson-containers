#!/usr/bin/env bash
set -e

: "${OLLAMA_VERSION:?OLLAMA_VERSION must be set}"

OLLAMA_HOME="${OLLAMA_HOME:-/opt/ollama}"
REPO_URL="https://github.com/ollama/ollama"

mkdir -p "${OLLAMA_HOME}"

if git ls-remote --tags "${REPO_URL}" "refs/tags/v${OLLAMA_VERSION}" >/dev/null 2>&1; then
  git clone --depth=1 --branch "v${OLLAMA_VERSION}" "${REPO_URL}" "${OLLAMA_HOME}"
else
  git clone --depth=1 "${REPO_URL}" "${OLLAMA_HOME}"
fi

cd "${OLLAMA_HOME}"

find . -name cpu_linux.go -exec sed -i 's/strconv.ParseInt(\([^,]*\), 10, 64)/func(s string) (int64, error) { if s == "max" { return 0, nil }; return strconv.ParseInt(s, 10, 64) }(\1)/g' {} +

cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CUDA_COMPILER="${CMAKE_CUDA_COMPILER}" \
  -DCMAKE_CUDA_ARCHITECTURES="${CUDA_ARCHITECTURES}" \
  -DGGML_CUDA_ARCHITECTURES="${CUDA_ARCHITECTURES}"

cmake --build build -j"$(nproc)"

go build -v -o "${OLLAMA_HOME}/ollama" .

ln -sf "${OLLAMA_HOME}/ollama" /usr/local/bin/ollama
if [ $? -ne 0 ]; then
  echo "Warning: Failed to create symlink /usr/local/bin/ollama" >&2
fi
ln -sf /usr/local/bin/ollama /usr/bin/ollama
if [ $? -ne 0 ]; then
  echo "Warning: Failed to create symlink /usr/bin/ollama" >&2
fi
ln -sf /usr/local/bin/ollama /bin/ollama
if [ $? -ne 0 ]; then
  echo "Warning: Failed to create symlink /bin/ollama" >&2
fi

echo "/usr/local/lib/ollama" > /etc/ld.so.conf.d/ollama.conf
ldconfig

uv pip install --no-cache-dir ollama


