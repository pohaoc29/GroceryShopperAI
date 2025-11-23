import os
import sqlite3
import json
import asyncio
from sqlalchemy import select

from db import SessionLocal, GroceryItem
from llm import get_embedding

EMBED_DB_PATH = os.path.join(os.path.dirname(__file__), "embeddings.sqlite")

# Create table
CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS grocery_item_embeddings (
    grocery_item_id INTEGER PRIMARY KEY,
    embedding TEXT NOT NULL
);
"""

async def generate_and_store_embeddings():

    print("Generating embeddings into", EMBED_DB_PATH)

    conn = sqlite3.connect(EMBED_DB_PATH)
    conn.execute(CREATE_TABLE_SQL)
    conn.commit()

    # Read the embeddings if exists -> skip
    existing = set(
        row[0] for row in conn.execute("SELECT grocery_item_id FROM grocery_item_embeddings")
    )
    print(f"Found {len(existing)} existing vectors, skipping them")

    # Read all grocery items from mysql
    async with SessionLocal() as session:
        res = await session.execute(select(GroceryItem))
        items = res.scalars().all()

    for g in items:
        if g.id in existing:
            continue

        text = f"{g.title} | {g.sub_category}"
        emb = await get_embedding(text)

        conn.execute(
            "INSERT INTO grocery_item_embeddings (grocery_item_id, embedding) VALUES (?, ?)",
            (g.id, json.dumps(emb)),
        )
        conn.commit()
        print(f"Saved embedding for ID={g.id}: {g.title}")

    conn.close()
    print("Embedding generation complete")


if __name__ == "__main__":
    asyncio.run(generate_and_store_embeddings())
