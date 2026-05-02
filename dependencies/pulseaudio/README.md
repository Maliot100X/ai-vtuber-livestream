# PulseAudio — Virtual Audio Routing

**Website:** https://www.freedesktop.org/wiki/Software/PulseAudio/
**What it does:** Creates a virtual audio sink for routing Chrome audio to FFmpeg

## What We Use It For
- Creates a virtual audio device (`virtual_output`)
- Chrome plays TTS audio to this virtual sink
- FFmpeg captures audio from `virtual_output.monitor`
- No physical audio hardware needed on the server

## Installation
```bash
sudo apt install -y pulseaudio
```

## Setup
```bash
# Start PulseAudio
pulseaudio --start --exit-idle-time=-1

# Create virtual audio sink
pactl load-module module-null-sink \
  sink_name=virtual_output \
  sink_properties=device.description="Virtual_Output"

# Set as default sink
pactl set-default-sink virtual_output

# Verify
pactl list sinks short
# Should show: virtual_output
```

## How It Works
```
Chrome (audio output)
    ↓
PulseAudio virtual_output (null sink)
    ↓
virtual_output.monitor (monitor source)
    ↓
FFmpeg -f pulse -i virtual_output.monitor
    ↓
YouTube RTMP stream
```

## Commands
```bash
# List sinks
pactl list sinks short

# List sink inputs (what's playing)
pactl list sink-inputs short

# List sources (monitors)
pactl list sources short

# Set volume
pactl set-sink-volume virtual_output 100%
```

## Troubleshooting
```bash
# PulseAudio not starting
pulseaudio --kill
pulseaudio --start --exit-idle-time=-1

# No virtual_output sink
pactl load-module module-null-sink sink_name=virtual_output

# Chrome not using virtual sink
PULSE_SINK=virtual_output google-chrome ...
```

## Our Script
See `../../scripts/start_vtuber.sh` for how we set this up automatically.
