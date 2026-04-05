#!/usr/bin/env bash
set -x

echo "TESTING OLLAMA"

#ollama --version

# stop ollama if its running
OLLAMA_PID=$(ps -ef | grep 'ollama serve' | grep -v grep | awk '{ print $2 }')

if [ -z "${OLLAMA_PID}" ]; then
    echo "ollama is not running"
else
    echo "stopping ollama (PID ${OLLAMA_PID})"
    kill ${OLLAMA_PID} || true
    sleep 2
fi

# start ollama using the cuda_v12 runner
OLLAMA_LLM_LIBRARY=cuda_v${CUDA_VERSION_MAJOR} OLLAMA_DEBUG=1 /bin/ollama serve &
sleep 5 # wait for server to start

OLLAMA_PID=$(ps -ef | grep 'ollama serve' | grep -v grep | awk '{ print $2 }')

if [ -z "${OLLAMA_PID}" ]; then
    echo "ollama binary not running. exiting"
    exit 1
fi

# run the test
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
python3 $SCRIPT_DIR/test.py
