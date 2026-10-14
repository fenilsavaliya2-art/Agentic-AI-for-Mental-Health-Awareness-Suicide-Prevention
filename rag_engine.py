"""
RAG Engine — Retrieval-Augmented Generation for Mental Health AI
Uses FAISS + sentence-transformers for semantic similarity retrieval.
"""

import os
import json
import pickle
from pathlib import Path
from typing import List, Dict, Any

from knowledge_base import MENTAL_HEALTH_DOCUMENTS

# ── Optional heavy imports (graceful fallback if not installed yet) ───────────
try:
    import numpy as np
    from sentence_transformers import SentenceTransformer
    import faiss
    RAG_AVAILABLE = True
except ImportError:
    RAG_AVAILABLE = False


INDEX_PATH = Path(__file__).parent / "data" / "faiss_index.pkl"
EMBED_MODEL_NAME = "all-MiniLM-L6-v2"   # lightweight, fast, good quality

_index = None
_model = None
_docs  = None


def _build_index():
    """Build FAISS index from knowledge-base documents."""
    global _index, _model, _docs

    if not RAG_AVAILABLE:
        return False

    _model = SentenceTransformer(EMBED_MODEL_NAME)
    _docs  = MENTAL_HEALTH_DOCUMENTS

    texts = [f"{d['title']} {d['content']}" for d in _docs]
    embeddings = _model.encode(texts, convert_to_numpy=True, show_progress_bar=False)
    embeddings = embeddings.astype("float32")

    dim    = embeddings.shape[1]
    _index = faiss.IndexFlatL2(dim)
    _index.add(embeddings)

    INDEX_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(INDEX_PATH, "wb") as f:
        pickle.dump({"index": _index, "docs": _docs, "model_name": EMBED_MODEL_NAME}, f)

    return True


def _load_index():
    """Load pre-built FAISS index if available, otherwise build fresh."""
    global _index, _model, _docs

    if not RAG_AVAILABLE:
        return False

    if INDEX_PATH.exists():
        with open(INDEX_PATH, "rb") as f:
            data   = pickle.load(f)
        _index = data["index"]
        _docs  = data["docs"]
        _model = SentenceTransformer(EMBED_MODEL_NAME)
        return True

    return _build_index()


def retrieve_context(query: str, top_k: int = 3) -> List[Dict[str, Any]]:
    """
    Retrieve top-k most relevant documents for a given query.
    Falls back to keyword search if FAISS is unavailable.
    """
    global _index, _model, _docs

    if _index is None:
        _load_index()

    if RAG_AVAILABLE and _index is not None:
        query_vec = _model.encode([query], convert_to_numpy=True).astype("float32")
        distances, indices = _index.search(query_vec, top_k)
        results = []
        for idx, dist in zip(indices[0], distances[0]):
            if idx >= 0:
                doc = dict(_docs[idx])
                doc["relevance_score"] = float(1 / (1 + dist))
                results.append(doc)
        return results

    # ── Keyword fallback ─────────────────────────────────────────────────────
    query_lower = query.lower()
    scored = []
    for doc in MENTAL_HEALTH_DOCUMENTS:
        text  = f"{doc['title']} {doc['content']}".lower()
        score = sum(1 for word in query_lower.split() if word in text)
        if score > 0:
            d = dict(doc)
            d["relevance_score"] = score / max(len(query_lower.split()), 1)
            scored.append(d)

    scored.sort(key=lambda x: x["relevance_score"], reverse=True)
    return scored[:top_k]


def format_context_for_prompt(docs: List[Dict[str, Any]]) -> str:
    """Format retrieved documents into a structured context block for the LLM."""
    if not docs:
        return "No specific context retrieved. Respond from general mental health knowledge."

    lines = ["RETRIEVED KNOWLEDGE BASE CONTEXT:"]
    for i, doc in enumerate(docs, 1):
        lines.append(f"\n[Source {i}] {doc['title']} (category: {doc['category']})")
        lines.append(doc["content"])
    return "\n".join(lines)


def initialize_rag():
    """Call at startup to warm up the RAG index."""
    success = _load_index()
    status  = "FAISS semantic search ready" if (RAG_AVAILABLE and success) else "Keyword fallback mode"
    return status
