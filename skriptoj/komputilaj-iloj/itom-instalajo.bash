#!/bin/bash

set -euo pipefail

# Script pour compiler et installer itom sur Ubuntu/Debian
# Basé sur: https://itom-project.github.io/latest/docs/02_installation/build_debian.html
# Système cible: Linux Mint 22.1 (Ubuntu 24.04 noble)

# Variables
ITOM_VERSION="${ITOM_VERSION:-5.0.0}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/opt/itom}"
BUILD_DIR="${BUILD_DIR:-$(mktemp -d)}"
ITOM_REPO="https://github.com/itom-project/itom.git"
PLUGINS_REPO="https://github.com/itom-project/plugins.git"
DESIGNERPLUGINS_REPO="https://github.com/itom-project/designerPlugins.git"
NUM_JOBS="${NUM_JOBS:-$(nproc)}"

echo "=== Installation de itom ==="
echo "Version: ${ITOM_VERSION}"
echo "Répertoire d'installation: ${INSTALL_DIR}"
echo "Répertoire de build: ${BUILD_DIR}"
echo "Nombre de jobs pour la compilation: ${NUM_JOBS}"
echo ""

# Vérification des droits sudo
if ! sudo -v; then
    echo "Erreur: Ce script nécessite les droits sudo" >&2
    exit 1
fi

echo "=== Installation des dépendances système ==="
sudo apt-get update

# Dépendances principales
DEPENDENCIES=(
    # Outils de build
    build-essential
    cmake
    git
    pkg-config
    
    # Qt5
    qtbase5-dev
    qttools5-dev
    qttools5-dev-tools
    libqt5svg5-dev
    libqt5opengl5-dev
    qtdeclarative5-dev
    
    # Python 3
    python3-dev
    python3-numpy
    python3-pip
    
    # Bibliothèques scientifiques
    libopencv-dev
    libpcl-dev
    libvtk9-dev
    
    # Autres dépendances
    libhdf5-dev
    libfftw3-dev
    libgsl-dev
    libeigen3-dev
    
    # Documentation (optionnel)
    doxygen
    graphviz
    python3-sphinx
)

echo "Installation des paquets: ${DEPENDENCIES[*]}"
sudo apt-get install -y "${DEPENDENCIES[@]}" || {
    echo "Avertissement: Certains paquets n'ont pas pu être installés."
    echo "Le build pourrait échouer. Continuons quand même..."
}

echo ""
echo "=== Installation des dépendances Python ==="
pip3 install --user numpy scipy matplotlib

echo ""
echo "=== Clonage des dépôts itom ==="
cd "$BUILD_DIR"

echo "Clonage de itom..."
if [[ ! -d "itom" ]]; then
    git clone --branch "v${ITOM_VERSION}" "$ITOM_REPO" || {
        echo "Version ${ITOM_VERSION} introuvable, clonage de la branche principale..."
        git clone "$ITOM_REPO"
    }
fi

echo "Clonage de plugins..."
if [[ ! -d "plugins" ]]; then
    git clone --branch "v${ITOM_VERSION}" "$PLUGINS_REPO" || {
        echo "Version ${ITOM_VERSION} introuvable pour plugins, clonage de la branche principale..."
        git clone "$PLUGINS_REPO"
    }
fi

echo "Clonage de designerPlugins..."
if [[ ! -d "designerPlugins" ]]; then
    git clone --branch "v${ITOM_VERSION}" "$DESIGNERPLUGINS_REPO" || {
        echo "Version ${ITOM_VERSION} introuvable pour designerPlugins, clonage de la branche principale..."
        git clone "$DESIGNERPLUGINS_REPO"
    }
fi

echo ""
echo "=== Configuration et compilation de itom ==="
mkdir -p "$BUILD_DIR/itom-build"
cd "$BUILD_DIR/itom-build"

cmake "$BUILD_DIR/itom" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DBUILD_QTVERSION=Qt5 \
    -DBUILD_WITH_PCL=ON \
    -DBUILD_WITH_OPENCV=ON \
    -DPYTHON_EXECUTABLE=$(which python3) \
    || {
        echo "Erreur lors de la configuration CMake" >&2
        echo "Contenu du CMakeError.log:" >&2
        [[ -f CMakeFiles/CMakeError.log ]] && cat CMakeFiles/CMakeError.log >&2
        exit 1
    }

echo ""
echo "=== Compilation (cela peut prendre plusieurs minutes) ==="
make -j"$NUM_JOBS" || {
    echo "Erreur lors de la compilation" >&2
    echo "Essai avec un seul job..." >&2
    make || exit 1
}

echo ""
echo "=== Installation ==="
make install || {
    echo "Erreur lors de l'installation" >&2
    exit 1
}

echo ""
echo "=== Configuration des plugins ==="
mkdir -p "$BUILD_DIR/plugins-build"
cd "$BUILD_DIR/plugins-build"

cmake "$BUILD_DIR/plugins" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$INSTALL_DIR" \
    -DITOM_SDK_DIR="$INSTALL_DIR" \
    || {
        echo "Avertissement: Configuration des plugins échouée"
        echo "Continuons sans les plugins..."
    }

if [[ -f Makefile ]]; then
    echo "Compilation des plugins..."
    make -j"$NUM_JOBS" || echo "Avertissement: Certains plugins n'ont pas pu être compilés"
    make install || echo "Avertissement: Installation des plugins échouée"
fi

echo ""
echo "=== Configuration des designerPlugins ==="
mkdir -p "$BUILD_DIR/designerPlugins-build"
cd "$BUILD_DIR/designerPlugins-build"

cmake "$BUILD_DIR/designerPlugins" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$INSTALL_DIR" \
    -DITOM_SDK_DIR="$INSTALL_DIR" \
    || {
        echo "Avertissement: Configuration des designerPlugins échouée"
        echo "Continuons sans les designerPlugins..."
    }

if [[ -f Makefile ]]; then
    echo "Compilation des designerPlugins..."
    make -j"$NUM_JOBS" || echo "Avertissement: Certains designerPlugins n'ont pas pu être compilés"
    make install || echo "Avertissement: Installation des designerPlugins échouée"
fi

echo ""
echo "=== Ajout au PATH ==="
BASHRC_FILE="$HOME/.bashrc"
ITOM_BIN_DIR="$INSTALL_DIR/bin"

if [[ -d "$ITOM_BIN_DIR" ]]; then
    if ! grep -Fq "$ITOM_BIN_DIR" "$BASHRC_FILE" 2>/dev/null; then
        echo "" >> "$BASHRC_FILE"
        echo "# itom ajouté par install script" >> "$BASHRC_FILE"
        echo "export PATH=\"\${PATH:+\$PATH:}$ITOM_BIN_DIR\"" >> "$BASHRC_FILE"
        echo "export LD_LIBRARY_PATH=\"\${LD_LIBRARY_PATH:+\$LD_LIBRARY_PATH:}$INSTALL_DIR/lib\"" >> "$BASHRC_FILE"
        echo "→ Variables d'environnement ajoutées dans $BASHRC_FILE"
    else
        echo "→ Le PATH contient déjà $ITOM_BIN_DIR"
    fi
    
    # Exporter pour la session actuelle
    export PATH="${PATH:+$PATH:}$ITOM_BIN_DIR"
    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$INSTALL_DIR/lib"
fi

echo ""
echo "=== Nettoyage ==="
read -p "Supprimer le répertoire de build $BUILD_DIR ? [o/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[OoYy]$ ]]; then
    rm -rf "$BUILD_DIR"
    echo "→ Répertoire de build supprimé"
else
    echo "→ Répertoire de build conservé: $BUILD_DIR"
fi

echo ""
echo "=== Installation terminée ==="
echo "itom a été installé dans: $INSTALL_DIR"
echo ""
echo "Pour utiliser itom:"
echo "  1. Recharge ton shell: source ~/.bashrc"
echo "  2. Lance itom: itom (ou qitom selon la version)"
echo ""
echo "Si itom ne démarre pas, vérifie:"
echo "  - Les variables d'environnement: echo \$PATH et echo \$LD_LIBRARY_PATH"
echo "  - Les logs dans $INSTALL_DIR"
echo "  - La présence de l'exécutable: ls -la $ITOM_BIN_DIR"
