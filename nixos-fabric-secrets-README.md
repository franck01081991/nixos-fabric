# Nixos-Fabric Secrets

Repository privé pour les secrets chiffrés de l'infrastructure Nixos-Fabric.

## Structure

- `secrets/` - Fichiers secrets chiffrés avec SOPS
  - `production.yaml` - Secrets pour l'environnement de production
  - `staging.yaml` - Secrets pour l'environnement de staging

## Utilisation

### Chiffrement de nouveaux secrets

1. Installer SOPS et age:
   ```bash
   nix-shell -p sops age
   ```

2. Créer une clé age (si ce n'est pas déjà fait):
   ```bash
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

3. Ajouter la clé publique au .sops.yaml

4. Chiffrer un fichier:
   ```bash
   sops --encrypt --age $(cat ~/.config/sops/age/keys.txt | grep "public key" | awk '{print $3}') secrets/production.yaml
   ```

### Intégration avec le repo fleet

Le repo fleet utilise ce repo comme input:

```nix
# Dans fleet/flake.nix
inputs.secrets.url = "git+ssh://git@github.com/franck01081991/nixos-fabric-secrets.git";

# Puis dans les configurations
sops.secrets = import inputs.secrets + "/secrets/production.yaml";
```

## Sécurité

- **Ne jamais commiter de secrets en clair**
- Toujours utiliser SOPS pour chiffrer
- Les clés privées age doivent être stockées en sécurité
- Rotater les secrets régulièrement

## Ajouter un nouvel environnement

1. Créer un nouveau fichier:
   ```bash
   cp secrets/production.yaml secrets/new-env.yaml
   ```

2. Chiffrer avec SOPS:
   ```bash
   sops --encrypt --age $(cat ~/.config/sops/age/keys.txt | grep "public key" | awk '{print $3}') secrets/new-env.yaml
   ```

3. Mettre à jour .sops.yaml si nécessaire
