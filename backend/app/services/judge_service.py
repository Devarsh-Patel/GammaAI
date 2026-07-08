"""
judge_service.py
-----------------
The "agentic" comparison step.

Takes the raw ProviderAnswer list from multi_llm_service.ask_all_providers()
and asks a JUDGE model to:
  1. Score each answer on accuracy, completeness, and clarity.
  2. Pick the single best answer OR synthesize a new answer that combines
     the strongest points of each (configurable via `mode`).
  3. Return structured JSON so the Flutter UI can render it deterministically
     — never free-text, or the frontend can't parse it reliably.

The judge itself is just another call to one of the provider wrappers
(defaults to Claude, since it tends to be strong at structured evaluation
tasks — swap JUDGE_PROVIDER if you'd rather use another model as referee).

NOTE: mirrors backend/app/models/schemas.py — keep both in sync.
"""

from __future__ import annotations

import json
from typing import List, Literal

from .llm_providers import PROVIDER_FUNCS, ProviderAnswer

JUDGE_PROVIDER = "claude"   # which provider acts as referee
JUDGE_MODEL = "claude-3-5-sonnet-20240620"

JudgeMode = Literal["pick_best", "synthesize"]


def _build_judge_prompt(query: str, answers: List[ProviderAnswer], mode: JudgeMode) -> str:
    ok_answers = [a for a in answers if a.ok]

    numbered = "\n\n".join(
        f"[Answer {i+1} — source: {a.provider} ({a.model})]\n{a.answer}"
        for i, a in enumerate(ok_answers)
    )

    instruction = (
        "Pick the single strongest answer as-is."
        if mode == "pick_best"
        else "Synthesize one new answer that combines the strongest, most "
             "accurate points from the candidates. Do not just pick one "
             "verbatim — merge them into the best possible response."
    )

    return f"""You are an impartial judge comparing answers from multiple AI models
to the same user question. Evaluate them on accuracy, completeness, and
clarity, then follow this instruction: {instruction}

User question:
{query}

Candidate answers:
{numbered}

Respond with ONLY valid JSON (no markdown fences, no preamble) matching
this exact shape:
{{
  "scores": [
    {{"answer_index": 1, "provider": "...", "score": 0-10, "notes": "..."}},
    ...
  ],
  "winner_provider": "provider name of the best individual answer",
  "final_answer": "the best answer text — either the winning answer verbatim
                    (pick_best mode) or the synthesized merge (synthesize mode)",
  "reasoning": "2-4 sentences explaining the verdict"
}}"""


async def judge_answers(
    query: str,
    answers: List[ProviderAnswer],
    mode: JudgeMode = "synthesize",
) -> dict:
    ok_answers = [a for a in answers if a.ok]
    if not ok_answers:
        return {
            "scores": [],
            "winner_provider": None,
            "final_answer": "All providers failed to respond.",
            "reasoning": "No successful answers were available to compare.",
        }

    if len(ok_answers) == 1:
        only = ok_answers[0]
        return {
            "scores": [{"answer_index": 1, "provider": only.provider, "score": None,
                        "notes": "Only provider that returned a successful answer."}],
            "winner_provider": only.provider,
            "final_answer": only.answer,
            "reasoning": "Only one provider succeeded, so no comparison was needed.",
        }

    prompt = _build_judge_prompt(query, ok_answers, mode)
    judge_call = PROVIDER_FUNCS[JUDGE_PROVIDER]
    judge_result = await judge_call(prompt, model=JUDGE_MODEL)

    if not judge_result.ok:
        # Judge itself failed — fall back to the longest answer as a
        # last-resort heuristic rather than crashing the whole request.
        fallback = max(ok_answers, key=lambda a: len(a.answer))
        return {
            "scores": [],
            "winner_provider": fallback.provider,
            "final_answer": fallback.answer,
            "reasoning": f"Judge model failed ({judge_result.error}); "
                         f"fell back to the longest available answer.",
        }

    try:
        # Robust JSON extraction: finds the first { and last }
        content = judge_result.answer
        start = content.find('{')
        end = content.rfind('}')
        if start == -1 or end == -1:
            raise Exception("No JSON object found in response")
        
        cleaned = content[start:end+1]
        parsed = json.loads(cleaned)
        return parsed
    except Exception as e:
        # Judge didn't return clean JSON — still surface something useful.
        fallback = max(ok_answers, key=lambda a: len(a.answer))
        return {
            "scores": [],
            "winner_provider": fallback.provider,
            "final_answer": judge_result.answer or fallback.answer,
            "reasoning": f"Judge response could not be parsed as JSON ({str(e)}); "
                         "showing raw judge output or a fallback answer.",
        }
