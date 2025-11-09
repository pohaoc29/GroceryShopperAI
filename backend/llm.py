import os
import httpx
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

# 支援的模型
AVAILABLE_MODELS = {
    "tinyllama": {
        "api_base": "http://localhost:11434/v1",
        "model": "tinyllama-1.1b-chat-v1.0.Q4_K_M",
        "api_key": ""
    },
    "openai": {
        "api_base": "https://api.openai.com/v1",
        "model": "gpt-4o-mini",
        "api_key": os.getenv("OPENAI_API_KEY", "").strip()
    }
}

# Optional Gemini support (configure via env vars)
gemini_api_key = os.getenv("GEMINI_API_KEY", "").strip()
if gemini_api_key:
    genai.configure(api_key=gemini_api_key)
    AVAILABLE_MODELS["gemini"] = {
        "api_key": gemini_api_key,
        "model": os.getenv("GEMINI_MODEL", "gemini-pro")
    }

# 預設模型
DEFAULT_MODEL = os.getenv("LLM_MODEL", "tinyllama")

async def check_tinyllama_available() -> bool:
    """檢查 Ollama 中是否已下載 tinyllama 模型"""
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            r = await client.get("http://localhost:11434/api/tags")
            if r.status_code == 200:
                data = r.json()
                models = data.get("models", [])
                for model in models:
                    model_name = model.get("name", "")
                    if "tinyllama-1.1b-chat-v1.0.Q4_K_M" in model_name or "tinyllama" in model_name:
                        return True
            return False
    except Exception as e:
        print(f"Error checking tinyllama availability: {e}")
        return False

async def chat_completion(messages, temperature: float = 0.2, max_tokens: int = 512, model_name: str = None) -> str:
    """
    Supports multiple models: tinyllama, openai, gemini
    """
    # 選擇模型（使用傳入的模型名稱，或使用預設）
    if model_name is None:
        model_name = DEFAULT_MODEL
    
    if model_name not in AVAILABLE_MODELS:
        raise ValueError(f"Model '{model_name}' not available. Choose from: {list(AVAILABLE_MODELS.keys())}")
    
    config = AVAILABLE_MODELS[model_name]
    provider = model_name

    if provider == "tinyllama":
        # Local Ollama-compatible endpoint
        url = f"{config['api_base']}/chat/completions"
        headers = {"Content-Type": "application/json"}
        if config.get("api_key"):
            headers["Authorization"] = f"Bearer {config['api_key']}"
        payload = {
            "model": config["model"],
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": False
        }
        async with httpx.AsyncClient(timeout=120.0) as client:
            r = await client.post(url, headers=headers, json=payload)
            r.raise_for_status()
            data = r.json()
            return data["choices"][0]["message"]["content"]

    elif provider == "openai":
        # OpenAI API endpoint
        url = f"{config['api_base']}/chat/completions"
        headers = {"Content-Type": "application/json"}
        if config.get("api_key"):
            headers["Authorization"] = f"Bearer {config['api_key']}"
        payload = {
            "model": config["model"],
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": False
        }
        async with httpx.AsyncClient(timeout=120.0) as client:
            r = await client.post(url, headers=headers, json=payload)
            r.raise_for_status()
            data = r.json()
            return data["choices"][0]["message"]["content"]

    elif provider == "gemini":
        # Google Generative AI SDK (official)
        model = genai.GenerativeModel(config["model"])
        
        # Convert OpenAI-style messages to Gemini format
        # Gemini expects [{"role": "user"/"model", "parts": [{"text": "..."}]}]
        gemini_messages = []
        for m in messages:
            role = m.get("role", "user")
            content_text = m.get("content", "")
            # Convert role: "assistant" -> "model", others stay as "user"
            gemini_role = "model" if role == "assistant" else "user"
            gemini_messages.append({
                "role": gemini_role,
                "parts": [{"text": content_text}]
            })
        
        # Use generate_content with permissive settings
        response = model.generate_content(
            gemini_messages,
            generation_config=genai.types.GenerationConfig(
                temperature=temperature,
                max_output_tokens=max_tokens
            )
        )
        
        # Handle blocked responses gracefully
        try:
            if response.text:
                return response.text
        except ValueError:
            pass
        
        # If response was blocked, check candidates
        if response.candidates and len(response.candidates) > 0:
            candidate = response.candidates[0]
            if hasattr(candidate, 'content') and candidate.content and hasattr(candidate.content, 'parts') and len(candidate.content.parts) > 0:
                return candidate.content.parts[0].text
        
        return "[Response was filtered by Gemini safety policies]"

    else:
        # If reached here, unsupported provider
        raise ValueError(f"Unsupported provider: {provider}")
