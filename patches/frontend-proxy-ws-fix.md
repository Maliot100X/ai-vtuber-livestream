# Frontend Proxy WebSocket Fix

## Problem
The default Open-LLM-VTuber frontend connects to `/client-ws` which is for interactive browser clients.
For live streaming (YouTube), we need to connect to `/proxy-ws` which receives broadcast responses.

## The Fix
```bash
cd ~/Open-LLM-VTuber
FRONTEND_JS=$(ls frontend/assets/main-*.js)

# 1. Replace client-ws with proxy-ws
sed -i 's|/client-ws|/proxy-ws|g' "$FRONTEND_JS"

# 2. Update URLs to your server IP
sed -i 's|wss://localhost:12394|wss://YOUR_SERVER_IP:12394|g' "$FRONTEND_JS"
sed -i 's|https://localhost:12394|https://YOUR_SERVER_IP:12394|g' "$FRONTEND_JS"
```

## What This Does
- `/client-ws` → Interactive client (voice input, screen share)
- `/proxy-ws` → Broadcast client (receives AI responses for streaming)

The AI server broadcasts responses to ALL connected `/proxy-ws` clients.
Chrome on display :99 connects as a proxy client and displays the responses.
FFmpeg captures Chrome's display and streams to YouTube.

## Verify
```bash
# Check the patched JS
grep -o 'proxy-ws' ~/Open-LLM-VTuber/frontend/assets/main-*.js
# Should show: proxy-ws (1 or more matches)

# Check no client-ws remains
grep -o 'client-ws' ~/Open-LLM-VTuber/frontend/assets/main-*.js
# Should show nothing (0 matches)
```
