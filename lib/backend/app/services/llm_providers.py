"""
llm_providers.py
----------------
SERVICE LAYER — one thin async wrapper per LLM provider.

Design goals:
  * Every provider function has the SAME signature and return shape, so the
    orchestrator (multi_llm_service.py) can call them uniformly and run them
    concurrently with asyncio.gather().
  * Each wrapper NEVER raises on a provider failure — it catches everything
    and returns a ProviderAnswer with ok=False and an error message. One
    provider being down (bad key, rate limit, timeout) should never take
    down the whole comparison.
  * API keys are read from environment variables. Never hardcode keys.

Env vars expected:
  ANTHROPIC_API_KEY
  OPENAI_API_KEY
  GOOGLE_API_KEY      (Gemini)
  XAI_API_KEY         (Grok)
"""

from __future__ import annotations

import os
import time
from dataclasses import dataclass, field
from typing import Optional

import httpx

REQUEST_TIMEOUT = httpx.Timeout(45.0, connect=10.0)


@dataclass
class ProviderAnswer:
    provider: str            # "claude" | "openai" | "gemini" | "grok"
    model: str                # exact model string used
    ok: bool
    answer: str = ""
    error: Optional[str] = None
    latency_ms: int = 0


def _now_ms() -> int:
    return int(time.time() * 1000)


# --------------------------------------------------------------------------
# Claude (Anthropic)
# --------------------------------------------------------------------------
async def ask_claude(prompt: str, model: str = "claude-sonnet-4-6") -> ProviderAnswer:
    key = os.getenv("ANTHROPIC_API_KEY")
    if not key:
        return ProviderAnswer("claude", model, False, error="ANTHROPIC_API_KEY not set")

    started = _now_ms()
    try:
        async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT) as client:
            resp = await client.post(
                "https://api.anthropic.com/v1/messages",
                headers={
                    "x-api-key": key,
                    "anthropic-version": "2023-06-01",
                    "content-type": "application/json",
                },
                json={
                    "model": model,
                    "max_tokens": 1024,
                    "messages": [{"role": "user", "content": prompt}],
                },
            )
        resp.raise_for_status()
        data = resp.json()
        text = "".join(
            block.get("text", "") for block in data.get("content", [])
            if block.get("type") == "text"
        )
        return ProviderAnswer("claude", model, True, answer=text.strip(),
                               latency_ms=_now_ms() - started)
    except Exception as e:
        return ProviderAnswer("claude", model, False, error=str(e),
                               latency_ms=_now_ms() - started)


# --------------------------------------------------------------------------
# OpenAI (ChatGPT)
# --------------------------------------------------------------------------
async def ask_openai(prompt: str, model: str = "gpt-4o") -> ProviderAnswer:
    key = os.getenv("OPENAI_API_KEY")
    if not key:
        return ProviderAnswer("openai", model, False, error="OPENAI_API_KEY not set")

    started = _now_ms()
    try:
        async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT) as client:
            resp = await client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": model,
                    "messages": [{"role": "user", "content": prompt}],
                    "max_tokens": 1024,
                },
            )
        resp.raise_for_status()
        data = resp.json()
        text = data["choices"][0]["message"]["content"]
        return ProviderAnswer("openai", model, True, answer=text.strip(),
                               latency_ms=_now_ms() - started)
    except Exception as e:
        return ProviderAnswer("openai", model, False, error=str(e),
                               latency_ms=_now_ms() - started)


# --------------------------------------------------------------------------
# Google Gemini
# --------------------------------------------------------------------------
async def ask_gemini(prompt: str, model: str = "gemini-2.0-flash") -> ProviderAnswer:
    key = os.getenv("GOOGLE_API_KEY")
    if not key:
        return ProviderAnswer("gemini", model, False, error="GOOGLE_API_KEY not set")

    started = _now_ms()
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"{model}:generateContent?key={key}"
    )
    try:
        async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT) as client:
            resp = await client.post(
                url,
                json={"contents": [{"parts": [{"text": prompt}]}]},
            )
        resp.raise_for_status()
        data = resp.json()
        text = data["candidates"][0]["content"]["parts"][0]["text"]
        return ProviderAnswer("gemini", model, True, answer=text.strip(),
                               latency_ms=_now_ms() - started)
    except Exception as e:
        return ProviderAnswer("gemini", model, False, error=str(e),
                               latency_ms=_now_ms() - started)


# --------------------------------------------------------------------------
# Grok (xAI) — OpenAI-compatible chat completions endpoint
# --------------------------------------------------------------------------
async def ask_grok(prompt: str, model: str = "grok-4") -> ProviderAnswer:
    key = os.getenv("XAI_API_KEY")
    if not key:
        return ProviderAnswer("grok", model, False, error="XAI_API_KEY not set")

    started = _now_ms()
    try:
        async with httpx.AsyncClient(timeout=REQUEST_TIMEOUT) as client:
            resp = await client.post(
                "https://api.x.ai/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": model,
                    "messages": [{"role": "user", "content": prompt}],
                    "max_tokens": 1024,
                },
            )
        resp.raise_for_status()
        data = resp.json()
        text = data["choices"][0]["message"]["content"]
        return ProviderAnswer("grok", model, True, answer=text.strip(),
                               latency_ms=_now_ms() - started)
    except Exception as e:
        return ProviderAnswer("grok", model, False, error=str(e),
                               latency_ms=_now_ms() - started)


# Registry so the orchestrator can loop instead of hardcoding 4 calls.
PROVIDER_FUNCS = {
    "claude": ask_claude,
    "openai": ask_openai,
    "gemini": ask_gemini,
    "grok": ask_grok,
}
