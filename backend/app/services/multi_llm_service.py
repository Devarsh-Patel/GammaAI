"""
multi_llm_service.py
---------------------
Orchestration layer: fires every configured provider CONCURRENTLY
(asyncio.gather) so the total wait time is roughly the slowest single
provider, not the sum of all four.

Only providers with an API key set in the environment are actually called —
missing keys are skipped up front rather than producing four "not set"
errors that clutter the comparison.
"""

from __future__ import annotations

import asyncio
import os
from typing import List

from .llm_providers import PROVIDER_FUNCS, ProviderAnswer

# Which env var gates which provider.
_REQUIRED_KEY = {
    "claude": "ANTHROPIC_API_KEY",
    "openai": "OPENAI_API_KEY",
    "gemini": "GOOGLE_API_KEY",
    "grok": "XAI_API_KEY",
}


def configured_providers() -> List[str]:
    return [name for name, env_var in _REQUIRED_KEY.items() if os.getenv(env_var)]


async def ask_all_providers(prompt: str, image_b64: Optional[str] = None) -> List[ProviderAnswer]:
    """Runs every provider that has a key configured, in parallel."""
    active = configured_providers()
    if not active:
        raise RuntimeError(
            "No provider API keys are set. Set at least one of: "
            + ", ".join(_REQUIRED_KEY.values())
        )

    tasks = [PROVIDER_FUNCS[name](prompt, image_b64=image_b64) for name in active]
    results = await asyncio.gather(*tasks)
    return list(results)
