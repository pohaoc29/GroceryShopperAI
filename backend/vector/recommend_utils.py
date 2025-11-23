from sqlalchemy import select

from db import GroceryItem
from vector.vector_search import search_similar_items

async def get_relevant_grocery_items(session, product_name: str, limit: int = 10):
    """
    embedding-based grocery item matcher
    Returns SQLAlchemy GroceryItem objects
    """

    scored = await search_similar_items(product_name, top_k=limit)

    if not scored:
        return []

    ids = [gid for gid, _ in scored]

    res = await session.execute(
        select(GroceryItem).where(GroceryItem.id.in_(ids))
    )
    items = res.scalars().all()

    # Sort by embedding
    id_to_item = {item.id: item for item in items}
    sorted_items = [id_to_item[i] for i in ids if i in id_to_item]

    return sorted_items