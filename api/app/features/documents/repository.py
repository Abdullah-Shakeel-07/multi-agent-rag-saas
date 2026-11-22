"""
Document & knowledge-base database operations (synchronous).
"""

from typing import Dict, Any, List, Optional

from app.core.database import db, generate_id
from app.core.pagination import PaginationParams, make_paginated_result


# ---------------------------------------------------------------------------
# Knowledge bases
# ---------------------------------------------------------------------------

def create_knowledge_base(company_id: str, name: str = "Default KB") -> Dict[str, Any]:
    return db.table("knowledge_bases").insert(
        {"kb_id": generate_id(), "company_id": company_id, "name": name, "file_count": 0}
    ).execute().data[0]


def get_knowledge_base_by_company(company_id: str) -> Optional[Dict[str, Any]]:
    res = db.table("knowledge_bases").select("*").eq("company_id", company_id).execute()
    return res.data[0] if res.data else None


def get_or_create_knowledge_base(company_id: str) -> Dict[str, Any]:
    kb = get_knowledge_base_by_company(company_id)
    return kb if kb else create_knowledge_base(company_id)


def fetch_all_knowledge_bases_by_company(company_id: str) -> List[Dict[str, Any]]:
    return db.table("knowledge_bases").select("*").eq("company_id", company_id).execute().data or []


# ---------------------------------------------------------------------------
# Documents
