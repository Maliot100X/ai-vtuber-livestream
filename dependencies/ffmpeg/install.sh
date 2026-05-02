#!/bin/bash
# Install FFmpeg
sudo apt install -y ffmpeg
echo "✅ FFmpeg installed: $(ffmpeg -version | head -1)"
