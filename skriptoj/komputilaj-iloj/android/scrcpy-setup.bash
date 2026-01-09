#!/bin/bash

set -euo pipefail

# Variables
VERSION="3.3.4"
INSTALL_DIR="$HOME/opt/scrcpyv${VERSION}"
BASHRC_DIR="$HOME"
ARCHIVE="scrcpy-linux-x86_64-v${VERSION}.tar.gz"
URL="https://github.com/Genymobile/scrcpy/releases/download/v${VERSION}/${ARCHIVE}"
RUN_NOW=false

# Optionnel: --run pour lancer scrcpy après installation
if [[ "${1:-}" == "--run" ]]; then
    RUN_NOW=true
fi

echo "=== Vérification des dépendances ==="
if ! command -v tar >/dev/null 2>&1; then
    echo "tar manquant" >&2; exit 1
fi
if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
    echo "wget ou curl requis" >&2; exit 1
fi
if ! command -v grep >/dev/null 2>&1; then
    echo "grep requis" >&2; exit 1
fi

echo "=== Téléchargement de scrcpy v${VERSION} ==="
mkdir -p "$INSTALL_DIR"
cd "$(mktemp -d)" || exit 1

if command -v wget >/dev/null 2>&1; then
    wget -O "$ARCHIVE" "$URL"
else
    curl -L -o "$ARCHIVE" "$URL"
fi

if [[ ! -f "$ARCHIVE" ]]; then
    echo "Échec du téléchargement" >&2; exit 1
fi

echo "=== Extraction dans $INSTALL_DIR ==="
tar -xf "$ARCHIVE" -C "$INSTALL_DIR"

# Rechercher le binaire scrcpy
SCRCPY_BIN="$(find "$INSTALL_DIR" -type f -name scrcpy -perm /u=x,g=x,o=x 2>/dev/null | head -n1 || true)"
if [[ -z "$SCRCPY_BIN" ]]; then
    # Peut-être que le binaire s'appelle scrcpy (sans exéc permission) ; chercher sans permission
    SCRCPY_BIN="$(find "$INSTALL_DIR" -type f -name scrcpy 2>/dev/null | head -n1 || true)"
fi

if [[ -z "$SCRCPY_BIN" ]]; then
    echo "Binaire scrcpy introuvable après extraction" >&2
    # Lister l'arborescence pour debug
    echo "Contenu de $INSTALL_DIR:"
    find "$INSTALL_DIR" -maxdepth 3 -ls || true
    exit 1
fi

echo "=== Rendre $SCRCPY_BIN exécutable ==="
chmod +x "$SCRCPY_BIN"

BIN_DIR="$(dirname "$SCRCPY_BIN")"
BASHRC_FILE="$BASHRC_DIR/.bashrc"

echo "=== Ajout de $BIN_DIR au PATH (dans $BASHRC_FILE) si nécessaire ==="
# Utiliser grep -F pour littéral
if ! grep -Fq "$BIN_DIR" "$BASHRC_FILE" 2>/dev/null; then
    echo "" >> "$BASHRC_FILE"
    echo "# scrcpy ajouté par install script" >> "$BASHRC_FILE"
    echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$BASHRC_FILE"
    echo "→ Ligne ajoutée dans $BASHRC_FILE"
else
    echo "→ Le PATH contient déjà $BIN_DIR"
fi

echo "=== Rechargement du PATH pour la session actuelle ==="
export PATH="$PATH:$BIN_DIR"

echo "=== Nettoyage ==="
rm -f "$ARCHIVE"
cd - >/dev/null 2>&1 || true

echo "=== Installation terminée ==="
echo "Tu peux maintenant lancer : scrcpy (ou relancer ton shell pour charger ~/.bashrc)"

if [[ "$RUN_NOW" == "true" ]]; then
    echo "Lancement de scrcpy en arrière-plan..."
    nohup "$SCRCPY_BIN" >/dev/null 2>&1 & disown
    echo "scrcpy lancé."
fi