# GroceryShopperAI – AI Event Architecture (For Frontend Integration)

This document explains **how the AI modules communicate with the Flutter frontend**, what events you will receive, and how you should render them.

The backend has moved from a *plain text LLM bot* to a **structured AI Copilot system**, where each AI action returns machine-readable JSON payloads.

This document is for frontend developers.

---

# Overview: How AI Responses Work

Unlike normal REST API endpoints, the AI features (inventory analysis, menu suggestions, restock planning, procurement plan, etc.) are **triggered through chat commands**, not via HTTP routes.

### Flow:

1. User sends a chat message (via POST `/api/rooms/{room_id}/messages`)
2. Backend detects special commands:
   - `@gro analyze`
   - `@gro menu`
   - `@gro restock`
   - `@gro plan`
3. Backend runs the corresponding AI module
4. Backend sends a **WebSocket event** to the frontend:
   - Type: `ai_event`
   - Contains a narrative + structured payload
5. Frontend renders the result as a visual card or component

➡ You **do not** call REST endpoints for AI features  
➡ You only listen for WebSocket messages

---

# AI Commands

Users trigger AI functionality directly in the chat input box:

@gro analyze
@gro menu
@gro restock
@gro plan


These commands activate server-side AI logic.

---

# WebSocket Event Format

When an AI command is executed, the backend sends:

```json
{
  "type": "ai_event",
  "event": "inventory_analysis",   // or "menu", "restock_plan", "procurement_plan"
  "room_id": 12,
  "narrative": "Natural-language explanation for the user.",
  "payload": { ... structured data ... }
}
```

You will always receive:

| Field | Description |
|------|---------------|
|type | Always "ai_event"|
|event | The AI feature: "inventory_analysis", "menu", "restock_plan", "procurement_plan"|
|room_id | Which chat room the event belongs to|
|narrative | A human-readable explanation|
|payload | JSON object with details (items, warnings, menus, etc.)|

# Event Types & Payload Examples
### 1. Inventory Analysis (```@gro analyze```)

```json
{
  "type": "ai_event",
  "event": "inventory_analysis",
  "narrative": "You are low on tomatoes and olive oil.",
  "payload": {
    "low_stock": [
      {"product": "Tomatoes", "stock": 3, "safety_stock": 10},
      {"product": "Olive Oil", "stock": 1, "safety_stock": 5}
    ],
    "healthy": [
      {"product": "Cheese", "stock": 20}
    ]
  }
}
```

### 2. Menu Recommendation (```@gro menu```)

```json
{
  "type": "ai_event",
  "event": "menu",
  "narrative": "Here are some dishes you can make today.",
  "payload": {
    "dishes": [
      {
        "name": "Tomato Pasta",
        "ingredients": ["Tomatoes", "Olive Oil", "Pasta"],
        "missing": ["Pasta"]
      }
    ]
  }
}
```

### 3. Restock Plan (```@gro restock```)
```json
{
  "type": "ai_event",
  "event": "restock_plan",
  "narrative": "Weekly restock plan generated.",
  "payload": {
    "items_to_buy": [
      {"product": "Tomatoes", "qty": 20, "best_price": 1.29, "supplier": "Walmart"}
    ]
  }
}
```

### 4. Procurement Plan (Chat-based) (```@gro plan```)
```json
{
  "type": "ai_event",
  "event": "procurement_plan",
  "narrative": "Here's the consolidated purchase plan based on the chat:",
  "payload": {
    "summary": "...",
    "items": [
      {"name": "Tomatoes", "qty": 10},
      {"name": "Chicken Breast", "qty": 5}
    ],
    "timeline": ["Buy today", "Prepare before 6 PM"]
  }
}
```


## Frontend Responsibilities
### ✔ Listen on WebSocket
You will receive both:
* regular chat messages (```type: "message"```)
* AI events (```type: "ai_event"```)

### ✔ If ```type === "ai_event"``` → Render a custom UI component

Example:
* A card with warnings & suggestions
* Menu preview cards
* Supplier comparison table
* Timeline or list items
* Highlighted narrative section*

### ✔ Do NOT treat AI results as plain chat messages

---

## What You Do NOT Need to Implement

* No new REST API endpoints required for AI
* No need to send structured JSON to backend
* No need to call backend AI modules manually
* No need to parse LLM output (backend already sanitizes JSON)

---
## Summary

* All AI functionality is now event-based, not REST-based.
* AI commands are triggered using ```@gro ...``` messages.
* The backend pushes structured JSON via WebSocket for rendering.
* Frontend only needs to listen for ```ai_event``` and display UI cards.