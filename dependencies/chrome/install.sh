#!/bin/bash
# Install Google Chrome
set -e
wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i /tmp/chrome.deb || sudo apt-get install -f -y
rm -f /tmp/chrome.deb
echo "✅ Chrome installed: $(google-chrome --version)"
