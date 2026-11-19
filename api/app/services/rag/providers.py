"""
LLM, embedding, and API key management.

Consolidates provider initialization — creates LLM instances, embedding
functions, and validates that required API keys are present.
"""

from typing import Dict, List

from langchain_cohere import CohereEmbeddings
from langchain_groq import ChatGroq

from app.core.config import settings


# ---------------------------------------------------------------------------
# Model mapping
# ---------------------------------------------------------------------------

GROQ_MODEL_MAP: Dict[str, str] = {
    "Llama-instant": "llama-3.1-8b-instant",
    "Llama-large": "llama-3.3-70b-versatile",
    "GPT-OSS-120B": "openai/gpt-oss-120b",
    "GPT-OSS-20B": "openai/gpt-oss-20b",
    "Groq": "llama-3.1-8b-instant",  # legacy alias
}

GROQ_MODELS = set(GROQ_MODEL_MAP.keys())

ALL_MODELS: List[str] = [
    "Llama-instant", "Llama-large", "GPT-OSS-120B", "GPT-OSS-20B",
    "GPT-4o-mini", "GPT-4o", "GPT-4.1", "GPT-4.1-mini",
]


def get_available_models() -> List[str]:
    return list(ALL_MODELS)


# ---------------------------------------------------------------------------
# API key helpers — thin wrappers kept for readability in callers
# ---------------------------------------------------------------------------

def _require(value, name: str) -> str:
    if not value:
        raise ValueError(f"{name} API key is not set in environment variables.")
    return value


def get_groq_api_key() -> str:
    return settings.groq_api_key or ""

def get_openai_api_key() -> str:
    return settings.openai_api_key or ""


def get_pinecone_api_key() -> str:
    return settings.pinecone_api_key or ""
