#!/bin/bash
sudo apt install -y pulseaudio
pulseaudio --start --exit-idle-time=-1
pactl load-module module-null-sink sink_name=virtual_output sink_properties=device.description="Virtual_Output"
pactl set-default-sink virtual_output
echo "✅ PulseAudio installed with virtual_output sink"
pactl list sinks short
