"""
comparison_schemas.py
----------------------
Pydantic schemas for the multi-LLM "council" endpoint.
Mirrors frontend/models/comparison_response.dart — keep both in sync.
"""

from typing import List, Optional
from pydantic import BaseModel


class ProviderAnswerOut(BaseModel):
    provider: str
    model: str
    ok: bool
    answer: str = ""
    error: Optional[str] = None
    latency_ms: int = 0


class ScoreOut(BaseModel):
    answer_index: int
    provider: str
    score: Optional[float] = None
    notes: str = ""


class ComparisonResponse(BaseModel):
    query: str
    mode: str                      # "pick_best" | "synthesize"
    provider_answers: List[ProviderAnswerOut]
    scores: List[ScoreOut]
    winner_provider: Optional[str]
    final_answer: str
    reasoning: str


class ComparisonRequest(BaseModel):
    query: str
    mode: str = "synthesize"       # or "pick_best"
