#!/bin/bash
set -euo pipefail

echo "Migration des fichiers restants vers la nouvelle architecture multi-repo"

# Chemins
MONOREPO="/home/franck/src/nixos-fabric"
CORE_REPO="/home/franck/src/nixos-fabric-core"
FLEET_REPO="/home/franck/src/nixos-fabric-fleet"
SECRETS_REPO="/home/franck/src/nixos-fabric-secrets"

echo "1. Migration des scripts vers core..."
mkdir -p "$CORE_REPO/scripts"
if [ -d "$MONOREPO/scripts" ]; then
    cp -r "$MONOREPO/scripts"/* "$CORE_REPO/scripts/"
    echo "✓ Scripts migrés vers core"
else
    echo "- Aucun dossier scripts trouvé dans le monorepo"
fi

echo "2. Migration de la documentation vers core..."
mkdir -p "$CORE_REPO/docs"
if [ -d "$MONOREPO/docs" ]; then
    cp -r "$MONOREPO/docs"/* "$CORE_REPO/docs/"
    echo "✓ Documentation migrée vers core"
else
    echo "- Aucun dossier docs trouvé"
fi

echo "3. Migration des configurations de test vers fleet..."
mkdir -p "$FLEET_REPO/tests"
if [ -d "$MONOREPO/tests" ]; then
    # Copier les tests qui ne sont pas déjà migrés
    if [ -d "$MONOREPO/tests/configurations" ]; then
        cp -r "$MONOREPO/tests/configurations" "$FLEET_REPO/tests/"
        echo "✓ Tests de configuration migrés"
    fi
    if [ -d "$MONOREPO/tests/vm" ]; then
        cp -r "$MONOREPO/tests/vm" "$FLEET_REPO/tests/"
        echo "✓ Tests VM migrés"
    fi
else
    echo "- Aucun dossier tests trouvé"
fi

echo "4. Migration des fichiers racine pertinents..."
# Fichiers pertinents pour fleet
for file in colmena.nix sapinet-*.nix; do
    if [ -f "$MONOREPO/$file" ]; then
        cp "$MONOREPO/$file" "$FLEET_REPO/"
        echo "✓ $file migré vers fleet"
    fi
done

echo "5. Nettoyage des fichiers temporaires..."
rm -f "$MONOREPO"/nixos-fabric-*.nix "$MONOREPO"/nixos-fabric-*.sh "$MONOREPO"/nixos-fabric-*.yml "$MONOREPO"/nixos-fabric-*.yaml

echo ""
echo "Migration terminée!"
echo ""
echo "Prochaines étapes:"
echo "1. Vérifier chaque repo: cd <repo> && git status"
echo "2. Commit et push les changements"
echo "3. Mettre à jour les flake.nix si nécessaire"
echo "4. Tester les builds: nix flake check && nix build .#<cible>"
