# websocket-client — Python WebSocket Client

**GitHub:** https://github.com/websocket-client/websocket-client
**What it does:** WebSocket client library for Python

## What We Use It For
- Connecting to VTuber's proxy WebSocket (port 12394)
- Sending YouTube chat messages to the VTuber
- Receiving AI responses from the VTuber

## Installation
```bash
pip install websocket-client
```

## Usage
```python
import websocket
import json

# Connect to VTuber proxy
ws = websocket.create_connection("ws://localhost:12393/proxy-ws")

# Send a chat message
payload = json.dumps({"type": "text-input", "text": "User: Hello!"})
ws.send(payload)

# With WebSocketApp (threaded)
def on_message(ws, message):
    print(f"Received: {message}")

ws = websocket.WebSocketApp(
    "ws://localhost:12393/proxy-ws",
    on_message=on_message
)
ws.run_forever()
```

## Our Scripts Using This
All chat bridge scripts use this to connect to the VTuber proxy.
