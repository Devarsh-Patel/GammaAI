from typing import List, Optional
from pydantic import BaseModel, Field

class SubTask(BaseModel):
    id: int
    description: str

class PlannerOutput(BaseModel):
    original_query: str
    sub_tasks: List[SubTask]

class SearchResultItem(BaseModel):
    sub_task_id: int
    sub_task_description: str
    raw_findings: str
    sources: List[str]

class SynthesizedAnswer(BaseModel):
    answer: str
    sources: List[str]

class SearchResponse(BaseModel):
    query: str
    plan: PlannerOutput
    search_results: List[SearchResultItem]
    final: SynthesizedAnswer

class SearchRequest(BaseModel):
    query: str
