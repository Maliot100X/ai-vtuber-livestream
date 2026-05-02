#!/bin/bash
# Install Open-LLM-VTuber
set -e
cd ~
git clone https://github.com/Open-LLM-VTuber/Open-LLM-VTuber.git
cd Open-LLM-VTuber
git submodule update --init --recursive
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install chat-downloader websocket-client edge-tts loguru requests sherpa-onnx
echo "✅ Open-LLM-VTuber installed at ~/Open-LLM-VTuber"
