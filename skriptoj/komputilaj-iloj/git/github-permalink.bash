#!/bin/bash

# Usage: ./permalink.sh path/to/file
# Exemple: ./permalink.sh src/main.py

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-file>"
    exit 1
fi

INPUT_PATH="$1"

# Trouve la racine du dépôt Git
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$REPO_ROOT" ]; then
    echo "Erreur : ce script doit être exécuté dans un dépôt Git."
    exit 1
fi

# Convertit le chemin fourni en chemin relatif à la racine du dépôt
ABS_PATH=$(realpath "$INPUT_PATH")
REL_PATH=$(realpath --relative-to="$REPO_ROOT" "$ABS_PATH")

# Vérifie que le fichier existe réellement
if [ ! -f "$ABS_PATH" ]; then
    echo "Erreur : fichier introuvable ($INPUT_PATH)"
    exit 1
fi

# Récupère le dernier commit qui a modifié ce fichier
SHA=$(git log -n 1 --pretty=format:%H -- "$REL_PATH")

if [ -z "$SHA" ]; then
    echo "Erreur : impossible de trouver un commit pour ce fichier."
    exit 1
fi

# Récupère l'URL du dépôt (format HTTPS)
REPO_URL=$(git config --get remote.origin.url | sed 's/.git$//')

# Convertit les URLs SSH en HTTPS si nécessaire
if [[ "$REPO_URL" =~ ^git@github.com:(.*)$ ]]; then
    REPO_URL="https://github.com/${BASH_REMATCH[1]}"
fi

# Construit le permalien
echo "${REPO_URL}/blob/${SHA}/${REL_PATH}"
