from fastapi import APIRouter, UploadFile, File, Response
from app.services.voice_service import transcribe_audio, text_to_speech
from pydantic import BaseModel

router = APIRouter()

class TTSRequest(BaseModel):
    text: str

@router.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    audio_bytes = await file.read()
    text = await transcribe_audio(audio_bytes)
    return {"text": text}

@router.post("/speak")
async def speak(request: TTSRequest):
    audio_content = await text_to_speech(request.text)
    return Response(content=audio_content, media_type="audio/mpeg")
