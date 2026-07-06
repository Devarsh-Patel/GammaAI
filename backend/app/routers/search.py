from fastapi import APIRouter, HTTPException
from app.models.search_schemas import (
    SearchRequest, SearchResponse, PlannerOutput,
    SubTask, SearchResultItem, SynthesizedAnswer
)
from app.services.llm_providers import ask_claude
import json

router = APIRouter()

@router.post("/search", response_model=SearchResponse)
async def search(request: SearchRequest):
    query = request.query.strip()
    if not query:
        raise HTTPException(status_code=400, detail="Query must not be empty.")

    # 1. Plan
    plan_prompt = f"Plan a search for: {query}. Break it into 3 sub-tasks. Return ONLY JSON: {{\"sub_tasks\": [\"desc1\", \"desc2\", \"desc3\"]}}"
    plan_resp = await ask_claude(plan_prompt)
    if not plan_resp.ok:
        raise HTTPException(status_code=500, detail="Planning failed")

    try:
        plan_data = json.loads(plan_resp.answer)
        sub_tasks = [SubTask(id=i+1, description=d) for i, d in enumerate(plan_data["sub_tasks"])]
    except:
        sub_tasks = [SubTask(id=1, description=f"Search for {query}")]

    plan = PlannerOutput(original_query=query, sub_tasks=sub_tasks)

    # 2. Search (Mocking with LLM findings)
    search_results = []
    all_sources = ["https://en.wikipedia.org", "https://news.google.com"]
    for st in sub_tasks:
        search_results.append(SearchResultItem(
            sub_task_id=st.id,
            sub_task_description=st.description,
            raw_findings=f"Findings for {st.description}...",
            sources=all_sources
        ))

    # 3. Synthesize
    synth_prompt = f"Synthesize an answer for '{query}' based on these findings: {[r.raw_findings for r in search_results]}"
    synth_resp = await ask_claude(synth_prompt)

    final = SynthesizedAnswer(
        answer=synth_resp.answer if synth_resp.ok else "Synthesis failed",
        sources=all_sources
    )

    return SearchResponse(
        query=query,
        plan=plan,
        search_results=search_results,
        final=final
    )
