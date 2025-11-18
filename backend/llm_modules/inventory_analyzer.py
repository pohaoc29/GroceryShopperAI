import json
from typing import List, Dict, Any

from llm import chat_completion
from llm_modules.llm_utils import format_chat_history, extract_json

async def analyze_inventory(inventory_items, low_stock_items, healthy_items, grocery_items, chat_history: List[Dict[str, str]] | None = None, model_name: str = "openai") -> Dict[str, Any]:
    """
    LLM Inventory Analyzer
    Analyze current inventory and generate restock suggestions.
    - inventory_items: list of dicts from DB
    """
    
    chat_text = format_chat_history(chat_history) if chat_history else ""
    
    system_prompt = """
    You are an Inventory Analyst.

    BACKEND HAS ALREADY CLASSIFIED THE INVENTORY.
    You MUST NOT:
    - recalculate stock levels
    - reassign items
    - add or remove items
    - change stock numbers

    Your job is ONLY:
    1. Echo the same "low_stock" and "healthy" lists exactly as provided.
    2. Generate a helpful narrative.
    3. Output STRICT JSON with this structure:

    {
        "narrative": "<text>",
        "low_stock": [...],
        "healthy": [...]
    }

    IMPORTANT:
    - Your output must include "low_stock" and "healthy" EXACTLY matching the provided lists.
    - JSON ONLY. No explanation outside JSON.
    """
    
    user_payload = {
        "inventory_items": inventory_items,
        "low_stock": low_stock_items,
        "healthy": healthy_items,
        "grocery_items": grocery_items,
        "chat_history": chat_text
    }
    
    raw = await chat_completion([
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": json.dumps(user_payload, indent=2)},
    ], model_name=model_name)
    
    parsed = extract_json(raw)
    
    # Add helpful CTA
    final_narrative = parsed.get("narrative", "Inventory analysis generated.")
    final_narrative += " If you need a restock plan, type '@gro restock'."

    
    return {
        "narrative": final_narrative,
        "low_stock": parsed.get("low_stock", low_stock_items),
        "healthy": parsed.get("healthy", healthy_items),
    }