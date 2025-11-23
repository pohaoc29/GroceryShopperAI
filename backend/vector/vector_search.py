import numpy as np

from llm import get_embedding
from vector.vector_cache import get_cached_embeddings


async def embed_query(text: str):
    """LLM embedding for the search query"""
    return np.array(await get_embedding(text), dtype=np.float32)

def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    if np.linalg.norm(a) == 0 or np.linalg.norm(b) == 0:
        return 0.0
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))

async def search_similar_items(query: str, top_k: int = 10):
    """Return top-k matched grocery items by cosine similarity."""
    q_emb = await embed_query(query)
    all_vectors = get_cached_embeddings()

    scored = []
    for gid, vector in all_vectors:
        score = cosine_similarity(q_emb, vector)
        scored.append((gid, score))

    scored.sort(key=lambda x: x[1], reverse=True)

    return scored[:top_k]