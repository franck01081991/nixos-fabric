# Guide de gestion des secrets avec sops-nix

## Introduction

Ce guide explique comment utiliser sops-nix pour gérer les secrets de manière sécurisée dans le projet nixos-fabric.

## Prérequis

1. Installer sops et age:
   ```bash
   nix-shell -p sops age
   ```

2. Générer une clé age:
   ```bash
   age-keygen -o age.key
   ```

## Configuration

### 1. Configurer les clés age

Ajoutez votre clé publique age dans la configuration:

```nix
# Dans votre configuration NixOS (par exemple hosts/rtr-sapinet/default.nix)
network-fabric.secrets = {
  enable = true;
  age = {
    enable = true;
    publicKey = "age1...your-public-key...";
    privateKey = "AGE-SECRET-KEY-1...your-private-key...";
  };
  wireguard = {
    enable = true;
    rtr-sapinet = {
      privateKey = "";  # Sera rempli par sops
      publicKey = "";   # Sera rempli par sops
    };
    rtr-noisy = {
      privateKey = "";  # Sera rempli par sops
      publicKey = "";   # Sera rempli par sops
    };
  };
};
```

### 2. Chiffrer les secrets

Créez un fichier de secrets chiffré:

```bash
# Créer un fichier de secrets initial
cat > secrets/wireguard.yaml <<EOF
wireguard:
    rtr-sapinet:
        private_key: "your-rtr-sapinet-private-key"
        public_key: "your-rtr-sapinet-public-key"
    rtr-noisy:
        private_key: "your-rtr-noisy-private-key"
        public_key: "your-rtr-noisy-public-key"
EOF

# Chiffrer le fichier avec sops
sops --age age1...your-public-key... --encrypt --in-place secrets/wireguard.yaml

# Renommer le fichier
mv secrets/wireguard.yaml secrets/wireguard.sops.yaml
```

### 3. Utiliser les secrets dans la configuration

Le module `modules/secrets.nix` s'occupe automatiquement de déchiffrer les secrets et de les injecter dans la configuration WireGuard.

## Déploiement

### 1. Préparer les secrets

Avant de déployer, assurez-vous que:
- Le fichier `secrets/wireguard.sops.yaml` existe et est chiffré
- Votre clé privée age est disponible sur la machine de déploiement

### 2. Déployer avec les secrets

```bash
# Sur la machine cible
sudo nixos-rebuild switch
```

Le système sops-nix déchiffrera automatiquement les secrets et les injectera dans la configuration.

## Rotation des clés

### 1. Générer de nouvelles clés WireGuard

```bash
# Sur chaque machine
wg genkey | sudo tee /etc/wireguard/${HOSTNAME}.key | wg pubkey | sudo tee /etc/wireguard/${HOSTNAME}.pub
```

### 2. Mettre à jour les secrets

```bash
# Déchiffrer le fichier
sops --age age1...your-public-key... --decrypt secrets/wireguard.sops.yaml > secrets/wireguard.tmp.yaml

# Mettre à jour avec les nouvelles clés
# (éditez le fichier temporaire)

# Rechiffrer
sops --age age1...your-public-key... --encrypt --in-place secrets/wireguard.tmp.yaml

# Remplacer l'ancien fichier
mv secrets/wireguard.tmp.yaml secrets/wireguard.sops.yaml
```

### 3. Redéployer

```bash
sudo nixos-rebuild switch
```

## Bonnes pratiques

1. **Ne jamais commiter de clés privées en clair** dans git
2. **Utiliser des clés age différentes** pour différents environnements (dev, prod)
3. **Limiter l'accès** aux clés privées age
4. **Rotater les clés** régulièrement
5. **Sauvegarder les clés** de manière sécurisée

## Dépannage

### Erreur: "Failed to decrypt sops file"

Vérifiez que:
- Votre clé privée age est correcte
- Le fichier sops est bien chiffré avec la bonne clé
- Les permissions sur le fichier de clés sont correctes (600)

### Erreur: "Secret not found"

Vérifiez que:
- Le chemin vers le fichier sops est correct
- La structure du fichier YAML est valide
- Les clés sont bien définies dans le fichier

## Exemple complet

Voir le fichier `secrets/wireguard.sops.yaml.example` pour un exemple de structure de fichier de secrets chiffré.
