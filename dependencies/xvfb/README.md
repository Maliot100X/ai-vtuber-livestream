# Xvfb — Virtual X11 Display

**Website:** https://www.x.org/
**What it does:** Creates a virtual X11 display for headless rendering

## What We Use It For
- Provides display `:99` for Chrome to render on
- No physical monitor needed on the server
- FFmpeg captures this display via x11grab
- Chrome renders the Live2D avatar on this virtual screen

## Installation
```bash
sudo apt install -y xvfb
```

## Setup
```bash
# Start virtual display (1920x1080, 24-bit color)
Xvfb :99 -screen 0 1920x1080x24 &

# Set display for subsequent commands
export DISPLAY=:99

# Verify
xdpyinfo -display :99 | head -5
```

## How It Works
```
Xvfb :99 (virtual display)
    ↓
Chrome --window-size=1920,1080 (renders on :99)
    ↓
FFmpeg -f x11grab -i :99 (captures the display)
    ↓
YouTube RTMP stream
```

## Parameters
- `:99` — Display number (avoids conflicts with real displays)
- `-screen 0 1920x1080x24` — Screen 0, 1920x1080 resolution, 24-bit color

## Commands
```bash
# Check if running
ps aux | grep Xvfb

# Check display
echo $DISPLAY

# Take screenshot (for debugging)
DISPLAY=:99 import -window root /tmp/screenshot.png
```

## Our Script
See `../../scripts/start_vtuber.sh` for how we start Xvfb automatically.
