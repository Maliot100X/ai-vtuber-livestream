#!/bin/bash
pip install edge-tts
echo "✅ edge-tts installed"
edge-tts --list-voices | head -20
echo "..."
echo "Total voices: $(edge-tts --list-voices | wc -l)"
