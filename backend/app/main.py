from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import compare, voice, search, history
import os
from dotenv import load_dotenv

# Load API keys from the kotlin/new.properties file
properties_path = os.path.join(os.path.dirname(__file__), "../../kotlin/new.properties")
load_dotenv(dotenv_path=properties_path)

app = FastAPI(title="GammaAI Backend")

# Allow Flutter app to connect from different platforms
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(compare.router)
app.include_router(voice.router)
app.include_router(search.router)
app.include_router(history.router)

@app.get("/health")
async def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
