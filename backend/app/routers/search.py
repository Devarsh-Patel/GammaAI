from fastapi import APIRouter, HTTPException
from app.models.search_schemas import (
    SearchRequest, SearchResponse, PlannerOutput,
    SubTask, SearchResultItem, SynthesizedAnswer
)
from app.services.llm_providers import ask_agent_llm
from app.services.search_service import perform_web_search
from app.routers.history import add_to_history
import json

router = APIRouter()

@router.post("/search", response_model=SearchResponse)
async def search(request: SearchRequest):
    query = request.query.strip()
    if not query:
        raise HTTPException(status_code=400, detail="Query must not be empty.")

    print(f"\n[1/3] Planning search for: '{query}'")
    add_to_history(query, "search")

    # 1. Plan
    plan_prompt = f"Plan a search for: {query}. Break it into 3 sub-tasks. Return ONLY JSON: {{\"sub_tasks\": [\"desc1\", \"desc2\", \"desc3\"]}}"
    plan_resp = await ask_agent_llm(plan_prompt)
    if not plan_resp.ok:
        print(f"!!! Planning failed: {plan_resp.error}")
        raise HTTPException(status_code=500, detail=f"Planning failed: {plan_resp.error}")

    try:
        clean_json = plan_resp.answer.replace("```json", "").replace("```", "").strip()
        plan_data = json.loads(clean_json)
        sub_tasks = [SubTask(id=i+1, description=d) for i, d in enumerate(plan_data["sub_tasks"])]
    except:
        sub_tasks = [SubTask(id=1, description=f"Search for {query}")]

    plan = PlannerOutput(original_query=query, sub_tasks=sub_tasks)
    print(f"Found {len(sub_tasks)} sub-tasks.")

    # 2. Real Web Search
    print(f"[2/3] Performing web search for sub-tasks...")
    search_results = []
    all_sources = []
    
    for i, st in enumerate(sub_tasks):
        print(f"  - Searching ({i+1}/{len(sub_tasks)}): {st.description}")
        findings = await perform_web_search(st.description)
        raw_text = "\n".join([f"{f['title']}: {f['snippet']}" for f in findings])
        links = [f['link'] for f in findings]
        all_sources.extend(links)
        
        search_results.append(SearchResultItem(
            sub_task_id=st.id,
            sub_task_description=st.description,
            raw_findings=raw_text or "No findings found.",
            sources=links
        ))

    # 3. Synthesize
    print(f"[3/3] Synthesizing final answer...")
    context = "\n---\n".join([r.raw_findings for r in search_results])
    synth_prompt = f"Using this search context:\n{context}\n\nSynthesize a comprehensive answer for the user's question: '{query}'"
    synth_resp = await ask_agent_llm(synth_prompt)

    final = SynthesizedAnswer(
        answer=synth_resp.answer if synth_resp.ok else f"Synthesis failed: {synth_resp.error}",
        sources=list(set(all_sources)) # Unique sources
    )
    print("Search complete!\n")

    return SearchResponse(
        query=query,
        plan=plan,
        search_results=search_results,
        final=final
    )
