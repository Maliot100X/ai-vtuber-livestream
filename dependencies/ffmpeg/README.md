# FFmpeg — Video/Audio Capture & Streaming

**Website:** https://ffmpeg.org
**What it does:** Captures screen + audio and streams to YouTube via RTMP

## What We Use It For
- Captures virtual display :99 (x11grab) — the Chrome/VTuber window
- Captures PulseAudio virtual_output.monitor — the TTS audio
- Encodes to H.264 video + AAC audio
- Sends RTMP stream to YouTube Live

## Installation
```bash
sudo apt install -y ffmpeg

# Verify
ffmpeg -version
```

## Our Stream Command
```bash
ffmpeg -re \
  -f x11grab -video_size 1920x1080 -framerate 30 -i :99 \
  -f pulse -i virtual_output.monitor \
  -c:v libx264 -preset veryfast -tune zerolatency \
  -b:v 4500k -maxrate 4500k -bufsize 9000k \
  -pix_fmt yuv420p -g 60 \
  -c:a aac -b:a 128k \
  -f flv "rtmp://a.rtmp.youtube.com/live2/YOUR_STREAM_KEY"
```

## Parameters Explained
- `-re` — Real-time mode (don't stream faster than source)
- `-f x11grab` — Capture X11 display
- `-video_size 1920x1080` — Full HD resolution
- `-framerate 30` — 30 FPS
- `-i :99` — Display number 99
- `-f pulse -i virtual_output.monitor` — Capture PulseAudio virtual sink
- `-c:v libx264` — H.264 video codec
- `-preset veryfast` — Fast encoding (lower quality than slow, but real-time)
- `-tune zerolatency` — Minimize encoding latency
- `-b:v 4500k` — 4.5 Mbps video bitrate
- `-pix_fmt yuv420p` — Compatible pixel format
- `-g 60` — Keyframe every 60 frames (2 seconds at 30fps)
- `-c:a aac -b:a 128k` — AAC audio at 128kbps
- `-f flv` — FLV container for RTMP

## YouTube RTMP URLs
- Primary: `rtmp://a.rtmp.youtube.com/live2/YOUR_STREAM_KEY`
- Backup: `rtmp://b.rtmp.youtube.com/live2/YOUR_STREAM_KEY?backup=1`

## Performance Tuning
```bash
# Lower CPU usage
-preset ultrafast    # Fastest encoding, larger file
-b:v 2500k          # Lower bitrate
-framerate 24       # Lower framerate

# Higher quality
-preset medium      # Better quality, more CPU
-b:v 6000k          # Higher bitrate
```

## Our Script
See `../../scripts/youtube-stream.sh` for our launch script.
