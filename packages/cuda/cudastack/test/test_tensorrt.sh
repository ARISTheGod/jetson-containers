#!/usr/bin/env bash

/usr/src/tensorrt/bin/trtexec --help

python3 -c "import tensorrt; print('TensorRT version:', tensorrt.__version__)" || echo "Note: Python TensorRT bindings not installed (this is normal for Ollama containers)"