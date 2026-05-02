# sherpa-onnx — Local Speech Recognition

**GitHub:** https://github.com/k2-fsa/sherpa-onnx
**What it does:** Local speech-to-text (ASR) engine, runs on CPU

## What We Use It For
- Speech recognition for voice input (if using microphone)
- Runs locally on CPU (no API calls needed)
- Supports multiple languages (Chinese, English, Japanese, Korean, Cantonese)
- Used with SenseVoice model for best results

## Installation
```bash
pip install sherpa-onnx
```

## Models
The SenseVoice model is auto-downloaded on first run:
```
models/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/
├── model.int8.onnx
└── tokens.txt
```

## Configuration in conf.yaml
```yaml
asr_config:
  asr_model: 'sherpa_onnx_asr'
  sherpa_onnx_asr:
    model_type: 'sense_voice'
    sense_voice: './models/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/model.int8.onnx'
    tokens: './models/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/tokens.txt'
    num_threads: 4
    use_itn: True
    provider: 'cpu'
```

## Alternative ASR Options
- `faster_whisper` — Uses Whisper models (needs more CPU/GPU)
- `whisper_cpp` — C++ Whisper implementation
- `fun_asr` — Alibaba's FunASR
- `groq_whisper_asr` — Groq's cloud Whisper API

## Notes
- For YouTube chat-only streaming, ASR is not needed
- ASR is only used for voice input (microphone)
- sherpa-onnx is lightweight and runs well on CPU
