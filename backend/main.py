"""API FastAPI. Lancer : uvicorn main:app --host 0.0.0.0 --port 8000"""
import os
import shutil

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from pydantic import BaseModel
from starlette.background import BackgroundTask

import downloader
from downloader import DownloadError

app = FastAPI(title="Video Downloader API")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


class UrlIn(BaseModel):
    url: str


@app.post("/analyze")
def analyze(body: UrlIn):
    try:
        return downloader.analyze(body.url)
    except DownloadError as e:
        raise HTTPException(400, str(e))


@app.get("/download")
def download(url: str, height: int | None = None):
    try:
        tmp, path = downloader.download(url, height)
    except DownloadError as e:
        raise HTTPException(400, str(e))
    # Le fichier temporaire est supprimé dès l'envoi terminé
    return FileResponse(
        path, media_type="video/mp4", filename=os.path.basename(path),
        background=BackgroundTask(shutil.rmtree, tmp, ignore_errors=True),
    )


@app.post("/tiktok/no-watermark")
def tiktok_no_watermark(body: UrlIn):
    try:
        return downloader.direct_url(body.url)
    except DownloadError as e:
        raise HTTPException(400, str(e))


@app.get("/health")
def health():
    return {"ok": True}
