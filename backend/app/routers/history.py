from fastapi import APIRouter
from app.models.history_schemas import HistoryListResponse, HistoryItem
from datetime import datetime
import uuid

router = APIRouter()

# In-memory storage for demonstration. 
# In a real app, this would be a database like SQLite or MongoDB.
search_history = []

@router.get("/history", response_model=HistoryListResponse)
async def get_history():
    return HistoryListResponse(history=search_history)

def add_to_history(query: str, type: str):
    item = HistoryItem(
        id=str(uuid.uuid4()),
        query=query,
        timestamp=datetime.now(),
        type=type
    )
    search_history.insert(0, item) # Newest first
    return item
