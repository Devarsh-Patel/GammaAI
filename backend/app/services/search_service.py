import httpx
import os
from typing import List, Dict

async def perform_web_search(query: str) -> List[Dict]:
    """
    Actually hits the web using Serper.dev API.
    Get a free key at https://serper.dev
    """
    api_key = os.getenv("SERPER_API_KEY")
    if not api_key:
        # Fallback to a mock if no key is provided
        return [{"title": "No Search Key", "snippet": "Please set SERPER_API_KEY in .env", "link": "https://serper.dev"}]

    url = "https://google.serper.dev/search"
    headers = {
        'X-API-KEY': api_key,
        'Content-Type': 'application/json'
    }
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(url, headers=headers, json={"q": query})
            response.raise_for_status()
            data = response.json()
            
            results = []
            for item in data.get("organic", [])[:5]:
                results.append({
                    "title": item.get("title"),
                    "snippet": item.get("snippet"),
                    "link": item.get("link")
                })
            return results
    except Exception as e:
        print(f"Search failed: {e}")
        return []
