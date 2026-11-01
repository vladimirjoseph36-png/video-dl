# Video Downloader (Flutter + FastAPI + yt-dlp)

Usage éducatif / personnel. Respectez les conditions d'utilisation des plateformes et le droit d'auteur.

## 1. Backend
Prérequis : Python 3.10+, `ffmpeg` installé (fusion audio/vidéo).
```
cd backend
python -m venv venv && source venv/bin/activate   # Windows : venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
curl -X POST localhost:8000/analyze -H "Content-Type: application/json" -d '{"url":"https://..."}'
```
Mettez `yt-dlp` à jour régulièrement : `pip install -U yt-dlp` (les sites changent souvent).

## 2. Application Flutter
```
cd app
flutter create .          # génère les dossiers android/ et ios/ sans toucher à lib/
flutter pub get
```
Modifiez `lib/config.dart` (IP de votre PC ou URL du serveur).

**Android** – `android/app/src/main/AndroidManifest.xml`, avant `<application>` :
`<uses-permission android:name="android.permission.INTERNET"/>`, et dans la balise
`<application ...>` ajoutez `android:usesCleartextTraffic="true"` (test en http uniquement).

**iOS** – `ios/Runner/Info.plist` :
```
<key>NSPhotoLibraryAddUsageDescription</key><string>Enregistrer les vidéos téléchargées</string>
<key>NSPhotoLibraryUsageDescription</key><string>Enregistrer les vidéos téléchargées</string>
```
(En http, ajoutez aussi une exception ATS ; en production utilisez https.)

Compiler : `flutter build apk` (Android) · `flutter build ios` (Mac + Xcode requis).

## Limites
- TikTok : le « sans filigrane » dépend de yt-dlp et casse parfois après une mise à jour de TikTok.
- Le fichier est téléchargé/fusionné dans un dossier temporaire du serveur, puis supprimé après envoi.
- Les logos incrustés dans l'image nécessiteraient du video inpainting (non inclus).
- Publication Google Play / App Store : très probablement refusée. Préférez l'APK direct.
- Un serveur public se fait vite bloquer par YouTube (IP) : idéal en usage personnel / réseau local.
