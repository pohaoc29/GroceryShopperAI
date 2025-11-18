import json
from typing import List, Dict, Any

from llm import chat_completion
from llm_modules.llm_utils import extract_json


async def generate_restock_plan(low_stock_items, grocery_items, model_name:str = "openai"):
    """
    Inventory-based retock
    Generate AI-powered weekly restock plan using inventory + grocery catalog.
    """
    
    system_prompt = """
    You are an AI Procurement Planner for a restaurant.

    BACKEND HAS ALREADY IDENTIFIED low_stock ITEMS.
    You MUST NOT:
    - add new items
    - remove items
    - change stock numbers
    - invent products not provided in grocery_items

    Your job:
    1. Echo the low_stock list as-is.
    2. For EACH low-stock item, generate a recommended purchase plan.
    3. Use grocery_items for price references.
    4. Output STRICT JSON ONLY:

    {
        "goal": "",
        "summary": "<text>",
        "narrative": "<text>",
        "items": [
            {
                "name": "<low_stock product name>",
                "quantity": <int>,
                "price_estimate": <float>,
                "notes": "<reason>"
            }
        ],
        "low_stock": [... echo ...]
    }

    RULES:
    - "items" must NOT be empty.
    - One entry per low-stock item.
    - Price must come from grocery_items.
    """
    
    
    user_payload = {
        "low_stock": low_stock_items,
        "grocery_items": grocery_items
    }
    
    raw = await chat_completion(
        [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": json.dumps(user_payload, indent=2)}
        ], 
        model_name=model_name,
    )
    
    
    parsed = extract_json(raw)

    return {
        "goal": "",
        "summary": parsed.get("summary", "Generated restock plan."),
        "narrative": parsed.get("narrative", "Here is your restock summary."),
        "items": parsed.get("items", []),
        "low_stock": parsed.get("low_stock", low_stock_items),
    }