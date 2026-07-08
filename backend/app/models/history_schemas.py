from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class HistoryItem(BaseModel):
    id: str
    query: str
    timestamp: datetime
    type: str # "search" or "compare"

class HistoryListResponse(BaseModel):
    history: List[HistoryItem]
