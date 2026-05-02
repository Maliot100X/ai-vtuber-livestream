# LLM Provider Configuration

## OpenAI
```yaml
openai_llm:
  llm_api_key: 'sk-...'
  model: 'gpt-4o-mini'
  temperature: 1.0
```

## OpenRouter (access to many models)
```yaml
openai_compatible_llm:
  base_url: 'https://openrouter.ai/api/v1'
  llm_api_key: 'sk-or-...'
  model: 'anthropic/claude-3.5-sonnet'
  temperature: 1.0
```

## Groq (fast inference)
```yaml
groq_llm:
  llm_api_key: 'gsk_...'
  model: 'llama-3.3-70b-versatile'
  temperature: 1.0
```

## Together AI
```yaml
openai_compatible_llm:
  base_url: 'https://api.together.xyz/v1'
  llm_api_key: '...'
  model: 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo'
  temperature: 1.0
```

## DeepSeek
```yaml
deepseek_llm:
  llm_api_key: 'sk-...'
  model: 'deepseek-chat'
  temperature: 0.7
```

## Google Gemini
```yaml
gemini_llm:
  llm_api_key: 'AI...'
  model: 'gemini-2.0-flash-exp'
  temperature: 1.0
```

## Anthropic Claude
```yaml
claude_llm:
  base_url: 'https://api.anthropic.com'
  llm_api_key: 'sk-ant-...'
  model: 'claude-3-haiku-20240307'
```

## Ollama (local, free)
```yaml
ollama_llm:
  base_url: 'http://localhost:11434/v1'
  model: 'llama3.2'
  temperature: 1.0
  keep_alive: -1
```

## LM Studio (local, free)
```yaml
lmstudio_llm:
  base_url: 'http://localhost:1234/v1'
  model: 'your-model-name'
  temperature: 1.0
```

## Tips
- **Fastest:** Groq > Gemini Flash > DeepSeek
- **Cheapest:** Ollama (free, local) > DeepSeek > Groq
- **Best quality:** Claude 3.5 Sonnet > GPT-4o > Gemini Pro
- **Best for VTubers:** Fast models with good personality (Groq Llama, Gemini Flash)
