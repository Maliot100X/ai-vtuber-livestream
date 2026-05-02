# Architecture Deep Dive

## System Overview

This system runs on a single AWS EC2 instance and creates an AI VTuber that:
1. Reads YouTube live chat in real-time
2. Sends chat messages to an LLM for response generation
3. Converts the response to speech using TTS
4. Renders a Live2D anime avatar with lip-sync
5. Streams everything to YouTube via RTMP

## Components

### 1. Xvfb (Virtual Display)
- Provides a virtual X11 display (`:99`) for headless rendering
- Chrome renders the Live2D avatar on this display
- FFmpeg captures the display via `x11grab`

### 2. PulseAudio (Virtual Audio Sink)
- Creates a virtual audio device (`virtual_output`)
- Chrome outputs TTS audio to this sink
- FFmpeg captures audio from `virtual_output.monitor`
- No physical audio hardware needed

### 3. Open-LLM-VTuber (Core Server)
- Python web server on port 12393
- Proxy WebSocket on port 12394
- Manages Live2D model, TTS, ASR, and LLM connections
- Two WebSocket types:
  - `/client-ws` → For interactive browser clients (voice input)
  - `/proxy-ws` → For broadcast clients (YouTube stream)

### 4. Chrome (Headless Browser)
- Connects to the VTuber proxy on `/proxy-ws`
- Renders the Live2D anime character
- Plays TTS audio through PulseAudio virtual sink
- Runs in kiosk mode at 1920x1080

### 5. YouTube Chat Bridge
- Python script using `chat-downloader` library
- Reads live chat from YouTube stream
- Sends each message to VTuber via proxy WebSocket
- VTuber processes and responds

### 6. FFmpeg (Stream Encoder)
- Captures video from Xvfb display `:99` (x11grab)
- Captures audio from PulseAudio `virtual_output.monitor`
- Encodes to H.264 video + AAC audio
- Sends RTMP stream to YouTube Live

## Network Flow

```
YouTube Chat → Chat Bridge → ws://localhost:12393/proxy-ws → VTuber Server
                                                                    │
                                              ┌─────────────────────┤
                                              ▼                     ▼
                                        LLM API              Edge TTS
                                              │                     │
                                              ▼                     ▼
                                        Response Text         Audio Stream
                                              │                     │
                                              └──────────┬──────────┘
                                                         ▼
                                               Broadcast to proxy-ws
                                                         │
                                              ┌──────────┴──────────┐
                                              ▼                     ▼
                                        Chrome (:99)         FFmpeg
                                        (Live2D + Audio)    (x11grab + pulse)
                                                                │
                                                                ▼
                                                         YouTube RTMP
```

## Port Map

| Port | Service | Protocol |
|------|---------|----------|
| 12393 | VTuber HTTP Server | HTTPS |
| 12394 | VTuber Proxy WS | WSS |
| 22 | SSH | TCP |

## Audio Pipeline

```
Edge TTS → Python audio buffer → WebSocket → Chrome → PulseAudio virtual_output
                                                                      │
                                                        virtual_output.monitor
                                                                      │
                                                              FFmpeg -f pulse
                                                                      │
                                                              AAC encoding → RTMP
```
