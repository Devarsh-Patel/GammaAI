import os
import httpx
from typing import Optional

async def transcribe_audio(audio_bytes: bytes) -> str:
    key = os.getenv("OPENAI_API_KEY")
    if not key:
        return "Error: OPENAI_API_KEY not set"

    try:
        async with httpx.AsyncClient() as client:
            files = {"file": ("audio.mp3", audio_bytes, "audio/mpeg")}
            data = {"model": "whisper-1"}
            resp = await client.post(
                "https://api.openai.com/v1/audio/transcriptions",
                headers={"Authorization": f"Bearer {key}"},
                files=files,
                data=data
            )
            resp.raise_for_status()
            return resp.json().get("text", "")
    except Exception as e:
        return f"Transcription error: {str(e)}"

async def text_to_speech(text: str) -> bytes:
    key = os.getenv("OPENAI_API_KEY")
    if not key:
        raise Exception("OPENAI_API_KEY not set")

    async with httpx.AsyncClient() as client:
        resp = await client.post(
            "https://api.openai.com/v1/audio/speech",
            headers={"Authorization": f"Bearer {key}"},
            json={
                "model": "tts-1",
                "input": text,
                "voice": "alloy",
            }
        )
        resp.raise_for_status()
        return resp.content
