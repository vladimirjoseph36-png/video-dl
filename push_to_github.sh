#!/bin/sh
# Usage : ./push_to_github.sh https://github.com/VOTRE_PSEUDO/video-dl.git
set -e
[ -z "$1" ] && echo "Donnez l'URL du dépôt GitHub." && exit 1
git init
git add .
git commit -m "Première version : backend FastAPI + app Flutter"
git branch -M main
git remote add origin "$1"
git push -u origin main
