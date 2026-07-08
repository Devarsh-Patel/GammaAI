"""
routers/compare.py
-------------------
Exposes POST /compare — the new endpoint GammaAI's Flutter app calls to get
a multi-LLM "council" answer instead of (or alongside) the existing
/search planner+search+synthesize pipeline.

Wire this into your existing FastAPI app with:
    from app.routers.compare import router as compare_router
    app.include_router(compare_router)
"""

from fastapi import APIRouter, HTTPException

from app.models.comparison_schemas import (
    ComparisonRequest,
    ComparisonResponse,
    ProviderAnswerOut,
    ScoreOut,
)
from app.services.multi_llm_service import ask_all_providers
from app.services.judge_service import judge_answers
from app.routers.history import add_to_history

router = APIRouter()


@router.post("/compare", response_model=ComparisonResponse)
async def compare(request: ComparisonRequest) -> ComparisonResponse:
    query = request.query.strip()
    if not query:
        raise HTTPException(status_code=400, detail="Query must not be empty.")

    add_to_history(query, "compare")

    if request.mode not in ("pick_best", "synthesize"):
        raise HTTPException(status_code=400, detail="mode must be 'pick_best' or 'synthesize'.")

    try:
        provider_answers = await ask_all_providers(query, image_b64=request.image_b64)
    except RuntimeError as e:
        raise HTTPException(status_code=500, detail=str(e))

    verdict = await judge_answers(query, provider_answers, mode=request.mode)

    return ComparisonResponse(
        query=query,
        mode=request.mode,
        provider_answers=[
            ProviderAnswerOut(
                provider=a.provider,
                model=a.model,
                ok=a.ok,
                answer=a.answer,
                error=a.error,
                latency_ms=a.latency_ms,
            )
            for a in provider_answers
        ],
        scores=[
            ScoreOut(**s) for s in verdict.get("scores", [])
        ],
        winner_provider=verdict.get("winner_provider"),
        final_answer=verdict.get("final_answer", ""),
        reasoning=verdict.get("reasoning", ""),
    )
