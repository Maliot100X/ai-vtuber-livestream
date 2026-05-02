# edge-tts — Free Microsoft Edge Text-to-Speech

**GitHub:** https://github.com/rany2/edge-tts
**What it does:** Free high-quality TTS using Microsoft Edge's online TTS service

## What We Use It For
- Primary TTS engine for the VTuber
- Converts AI response text to speech audio
- Supports 300+ voices in 70+ languages
- No API key required (uses Microsoft Edge's free service)

## Installation
```bash
pip install edge-tts
```

## Available Voices
```bash
# List all voices
edge-tts --list-voices

# Popular English voices
edge-tts --list-voices | grep "en-US"
# en-US-AvaMultilingualNeural (our default)
# en-US-GuyNeural
# en-US-JennyNeural
# en-US-AnaNeural

# Test a voice
edge-tts --voice en-US-AvaMultilingualNeural --text "Hello world!" --write-media test.mp3
```

## Configuration in conf.yaml
```yaml
tts_config:
  tts_model: 'edge_tts'
  edge_tts:
    voice: 'en-US-AvaMultilingualNeural'
```

## Our Choice
We use `en-US-AvaMultilingualNeural` — natural sounding female voice with multilingual support.
