#!/bin/bash
sudo apt install -y xvfb
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99
echo "✅ Xvfb installed and running on :99"
echo "DISPLAY=$DISPLAY"
