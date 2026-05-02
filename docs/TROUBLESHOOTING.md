# Troubleshooting Guide

## Common Issues

### 1. Chrome not rendering the VTuber
**Symptoms:** Black screen or no avatar visible

**Fix:**
```bash
# Check Xvfb is running
ps aux | grep Xvfb

# Check DISPLAY is set
echo $DISPLAY  # Should be :99

# Restart Chrome
pkill -f chrome
export DISPLAY=:99
google-chrome --no-sandbox --kiosk --window-size=1920,1080 "https://YOUR_IP:12394/"
```

### 2. No audio in YouTube stream
**Symptoms:** Stream has video but no sound

**Fix:**
```bash
# Check PulseAudio is running
pulseaudio --check && echo "Running" || echo "Not running"

# Check virtual sink exists
pactl list sinks short | grep virtual_output

# If missing, create it
pactl load-module module-null-sink sink_name=virtual_output

# Check Chrome audio is going to the sink
pactl list sink-inputs short
```

### 3. YouTube chat not appearing
**Symptoms:** VTuber doesn't respond to chat

**Fix:**
```bash
# Check YOUTUBE_VIDEO_ID is set correctly
echo $YOUTUBE_VIDEO_ID

# Test chat bridge manually
python3 scripts/youtube_chat_bridge.py

# Make sure the video is actually live (not a past stream)
```

### 4. AI not responding / LLM errors
**Symptoms:** Chat appears but no response

**Fix:**
```bash
# Check VTuber server logs
tail -50 ~/Open-LLM-VTuber/logs/debug_*.log

# Test LLM API directly
curl -X POST "$LLM_BASE_URL/chat/completions" \
  -H "Authorization: Bearer $LLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"'$LLM_MODEL'","messages":[{"role":"user","content":"hello"}]}'

# Check conf.yaml has correct API settings
cat ~/Open-LLM-VTuber/conf.yaml | grep -A5 "openai_compatible_llm"
```

### 5. FFmpeg stream dying
**Symptoms:** YouTube stream goes offline

**Fix:**
```bash
# Check FFmpeg process
ps aux | grep ffmpeg

# Check FFmpeg logs
tail -50 /tmp/ffmpeg-stream.log

# Common: YouTube stream key expired — get a new one from YouTube Studio
# Restart FFmpeg with new key
pkill -f "ffmpeg.*youtube"
ffmpeg -re \
  -f x11grab -video_size 1920x1080 -framerate 30 -i :99 \
  -f pulse -i virtual_output.monitor \
  -c:v libx264 -preset veryfast -tune zerolatency \
  -b:v 4500k -maxrate 4500k -bufsize 9000k \
  -pix_fmt yuv420p -g 60 \
  -c:a aac -b:a 128k \
  -f flv "rtmp://a.rtmp.youtube.com/live2/NEW_STREAM_KEY"
```

### 6. WebSocket connection failed
**Symptoms:** "Failed to connect to VTuber proxy"

**Fix:**
```bash
# Check VTuber server is running
curl -k https://localhost:12394/ 2>/dev/null && echo "Server OK"

# Check ports
ss -tlnp | grep -E '12393|12394'

# Restart VTuber server
cd ~/Open-LLM-VTuber && source .venv/bin/activate && python main.py
```

### 7. Frontend showing wrong WebSocket URL
**Symptoms:** Chrome connects but doesn't receive AI responses

**Fix:** The default frontend uses `/client-ws` instead of `/proxy-ws`:
```bash
cd ~/Open-LLM-VTuber
FRONTEND_JS=$(ls frontend/assets/main-*.js)
# Replace client-ws with proxy-ws
sed -i 's|/client-ws|/proxy-ws|g' "$FRONTEND_JS"
# Restart Chrome
pkill -f chrome
```

## Performance Tuning

### Reduce latency
- Use a faster LLM (Grok, Gemini Flash)
- Use `faster_first_response: True` in conf.yaml
- Use `segment_method: 'pysbd'` for sentence splitting
- Choose a TTS engine close to your server location

### Reduce CPU usage
- Lower FFmpeg bitrate: `-b:v 2500k`
- Lower framerate: `-framerate 24`
- Use `ultrafast` preset: `-preset ultrafast`
