import httpx
import os
from typing import List, Dict

async def perform_web_search(query: str) -> List[Dict]:
    """
    Actually hits the web using Serper.dev API or AIsa Multi-Search.
    """
    # 1. Try AIsa Search first if key is available
    aisa_key = os.getenv("AISA_API_KEY")
    if aisa_key and "YOUR_ACTUAL_KEY" not in aisa_key:
        url = "https://api.aisa.one/apis/v1/search" # Example endpoint for AIsa search
        headers = {
            'Authorization': f'Bearer {aisa_key}',
            'Content-Type': 'application/json'
        }
        try:
            async with httpx.AsyncClient() as client:
                # Assuming AIsa search payload format
                response = await client.post(url, headers=headers, json={"query": query})
                if response.status_code == 200:
                    data = response.json()
                    results = []
                    # Transform AIsa search results to our unified format
                    for item in data.get("results", []):
                        results.append({
                            "title": item.get("title", "No Title"),
                            "snippet": item.get("snippet", item.get("content", "")),
                            "link": item.get("url", item.get("link", ""))
                        })
                    if results:
                        return results[:5]
        except Exception as e:
            print(f"AIsa Search failed, falling back to Serper: {e}")

    # 2. Fallback to Serper.dev
    api_key = os.getenv("SERPER_API_KEY")
    if not api_key or "YOUR_ACTUAL_KEY" in api_key or "your_google_search_key_here" in api_key:
        return [{"title": "No Search Key", "snippet": "Please set SERPER_API_KEY in kotlin/new.properties", "link": "https://serper.dev"}]

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
