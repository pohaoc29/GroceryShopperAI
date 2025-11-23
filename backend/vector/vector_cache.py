import os
import json
import sqlite3
import numpy as np

EMBED_DB_PATH = "/tmp/embeddings.sqlite"

_cached_vectors = None


def load_embeddings_into_memory():
    global _cached_vectors
    if _cached_vectors is not None:
        return _cached_vectors

    if not os.path.exists(EMBED_DB_PATH):
        print(f"[vector_cache] ERROR: {EMBED_DB_PATH} not found!")
        _cached_vectors = []
        return _cached_vectors

    print(f"[vector_cache] Loading embeddings from {EMBED_DB_PATH} ...")

    conn = sqlite3.connect(EMBED_DB_PATH)
    rows = conn.execute("SELECT grocery_item_id, embedding FROM grocery_item_embeddings").fetchall()
    conn.close()

    vectors = []
    for gid, emb in rows:
        arr = np.array(json.loads(emb), dtype=np.float32)
        vectors.append((gid, arr))

    _cached_vectors = vectors
    print(f"[vector_cache] Loaded {len(vectors)} vectors into memory")

    return _cached_vectors


def get_cached_embeddings():
    return load_embeddings_into_memory()