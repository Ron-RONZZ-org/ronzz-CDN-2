#!/bin/bash
set -e

TB_VERSION="102.15.1"
TB_LANG="fr"
TB_ARCH="linux-x86_64"
TB_TAR="thunderbird-${TB_VERSION}.tar.bz2"
TB_URL="https://archive.mozilla.org/pub/thunderbird/releases/${TB_VERSION}/${TB_ARCH}/${TB_LANG}/${TB_TAR}"
INSTALL_DIR="/opt/thunderbird-102"
BIN_LINK="/usr/local/bin/thunderbird102"

echo "=============================================="
echo "  Installation de Thunderbird ${TB_VERSION}"
echo "=============================================="

echo "=== Vérification des dépendances ==="
command -v wget >/dev/null || { echo "wget manquant"; exit 1; }
command -v tar >/dev/null || { echo "tar manquant"; exit 1; }

echo "=== Fermeture de Thunderbird si en cours ==="
pkill thunderbird 2>/dev/null || true

echo "=== Sauvegarde du profil Thunderbird ==="
if [ -d "$HOME/.thunderbird" ]; then
    BACKUP_DIR="$HOME/.thunderbird.backup.$(date +%F-%H%M%S)"
    cp -r "$HOME/.thunderbird" "$BACKUP_DIR"
    echo "Sauvegarde créée : $BACKUP_DIR"
else
    echo "Aucun profil Thunderbird trouvé"
fi

echo "=== Suppression de Thunderbird (paquet système) ==="
sudo apt remove -y thunderbird || true
sudo apt autoremove -y

echo "=== Nettoyage ancienne installation manuelle ==="
if [ -d "$INSTALL_DIR" ]; then
    sudo rm -rf "$INSTALL_DIR"
fi

echo "=== Téléchargement de Thunderbird ${TB_VERSION} ==="
wget -q --show-progress "$TB_URL"

echo "=== Extraction dans /opt ==="
sudo tar -xjf "$TB_TAR" -C /opt/
sudo mv /opt/thunderbird "$INSTALL_DIR"

echo "=== Création du lien symbolique ==="
sudo ln -sf "$INSTALL_DIR/thunderbird" "$BIN_LINK"
sudo ln -sf /opt/thunderbird-102/thunderbird /usr/bin/thunderbird

echo "=== Nettoyage archive ==="
rm -f "$TB_TAR"

echo "=== Installation terminée ==="
echo
echo "Lancer Thunderbird avec :"
echo "  thunderbird102 --allow-downgrade"
echo
echo "IMPORTANT :"
echo "- Désactive les mises à jour automatiques dans Thunderbird"
echo "- Ne pas réinstaller Thunderbird via apt"
echo

echo "=== Lancement automatique ==="
"$BIN_LINK" --allow-downgrade &

exit 0

