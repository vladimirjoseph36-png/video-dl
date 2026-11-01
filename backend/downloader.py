"""
Logique d'extraction et de téléchargement (yt-dlp).

AVERTISSEMENT : application à but éducatif uniquement. Le téléchargement de
vidéos peut violer les conditions d'utilisation des plateformes (YouTube,
Facebook, TikTok) et les droits d'auteur. L'utilisateur est responsable de
son usage.
"""
import ipaddress
import os
import re
import shutil
import socket
import tempfile
from urllib.parse import urljoin, urlparse

import requests
import yt_dlp
from bs4 import BeautifulSoup

MAX_FILESIZE = 1_000_000_000  # 1 Go max par téléchargement


class DownloadError(Exception):
    """Erreur lisible renvoyée à l'utilisateur."""


def validate_url(url: str) -> str:
    """Valide l'URL et bloque les adresses internes (protection SSRF)."""
    if not url or len(url) > 2048:
        raise DownloadError("URL invalide.")
    p = urlparse(url.strip())
    if p.scheme not in ("http", "https") or not p.hostname:
        raise DownloadError("URL invalide : utilisez un lien http(s).")
    try:
        infos = socket.getaddrinfo(p.hostname, None)
    except socket.gaierror:
        raise DownloadError("Domaine introuvable.")
    for info in infos:
        ip = ipaddress.ip_address(info[4][0])
        if ip.is_private or ip.is_loopback or ip.is_link_local or ip.is_reserved:
            raise DownloadError("Adresse non autorisée.")
    return url.strip()


BASE_OPTS = {
    "quiet": True,
    "no_warnings": True,
    "noplaylist": True,
    "socket_timeout": 20,
}


def analyze(url: str) -> dict:
    """Renvoie titre, miniature et qualités disponibles."""
    url = validate_url(url)
    try:
        with yt_dlp.YoutubeDL(BASE_OPTS) as ydl:
            info = ydl.extract_info(url, download=False)
    except yt_dlp.utils.DownloadError:
        # Site non supporté : on tente l'analyse HTML de secours
        return fallback_html(url)
    heights = sorted(
        {f["height"] for f in info.get("formats", [])
         if f.get("height") and f.get("vcodec") != "none"},
        reverse=True,
    )
    return {
        "title": info.get("title", "Vidéo"),
        "thumbnail": info.get("thumbnail"),
        "duration": info.get("duration"),
        "site": info.get("extractor_key"),
        "heights": heights,
        "media_url": url,
    }


def fallback_html(url: str) -> dict:
    """Secours : cherche <video>, <source> ou des liens .mp4/.m3u8 dans la page."""
    try:
        r = requests.get(url, timeout=15, headers={"User-Agent": "Mozilla/5.0"})
        r.raise_for_status()
    except requests.RequestException:
        raise DownloadError("Impossible de lire la page.")
    soup = BeautifulSoup(r.text, "html.parser")
    found = [t.get("src") for t in soup.select("video[src], source[src]")]
    found += re.findall(r'https?://[^\s"\'<>]+\.(?:mp4|m3u8)[^\s"\'<>]*', r.text)
    for cand in found:
        if not cand:
            continue
        media = urljoin(url, cand)
        try:
            validate_url(media)
        except DownloadError:
            continue
        title = soup.title.string.strip() if soup.title and soup.title.string else "Vidéo"
        return {"title": title, "thumbnail": None, "duration": None,
                "site": "Générique", "heights": [], "media_url": media}
    raise DownloadError("Site non supporté ou aucune vidéo trouvée.")


def direct_url(url: str) -> dict:
    """Lien direct de la meilleure qualité (TikTok : source sans filigrane)."""
    url = validate_url(url)
    opts = {**BASE_OPTS, "format": "best[ext=mp4]/best"}
    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            info = ydl.extract_info(url, download=False)
    except yt_dlp.utils.DownloadError:
        raise DownloadError("Extraction impossible. Mettez à jour yt-dlp.")
    return {"title": info.get("title"), "url": info.get("url"),
            "headers": info.get("http_headers", {})}


def download(url: str, height: int | None = None):
    """Télécharge dans un dossier temporaire. Retourne (dossier, fichier)."""
    url = validate_url(url)
    if height:
        fmt = f"bv*[height<={height}]+ba/b[height<={height}]/b"
    else:
        fmt = "bv*+ba/b"
    tmp = tempfile.mkdtemp(prefix="vd_")
    opts = {
        **BASE_OPTS,
        "format": fmt,
        "format_sort": ["res", "ext:mp4:m4a"],  # préfère mp4 (galerie iOS/Android)
        "merge_output_format": "mp4",
        "outtmpl": os.path.join(tmp, "%(title).80s.%(ext)s"),
        "max_filesize": MAX_FILESIZE,
    }
    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            ydl.download([url])
    except Exception:
        shutil.rmtree(tmp, ignore_errors=True)
        raise DownloadError("Échec du téléchargement (site non supporté ou vidéo privée).")
    files = os.listdir(tmp)
    if not files:
        shutil.rmtree(tmp, ignore_errors=True)
        raise DownloadError("Aucun fichier produit (taille limite dépassée ?).")
    return tmp, os.path.join(tmp, files[0])
