# Bidirectional Synchronization Strategy

This document explains the bidirectional synchronization system between local host configurations (`hosts/`) and external submodules (`external/`).

## 🎯 Purpose

The synchronization system ensures that:
1. Changes in local configurations are automatically pushed to external submodules
2. Changes in external submodules are automatically pulled to local configurations
3. Both configurations stay in sync at all times
4. Developers can work in either location with confidence

## 📦 Architecture

```
nixos-fabric/
├── hosts/                     # Local configurations (working directory)
│   ├── rtr-sapinet/           # Local spine config
│   └── rtr-noisy/             # Local hybrid config
├── external/                  # External submodules (Git repositories)
│   ├── rtr-sapinet-config/    # External spine config
│   └── rtr-noisy-config/      # External hybrid config
└── scripts/sync-bidirectional.sh  # Synchronization script
```

## 🔄 Synchronization Modes

### 1. Automatic Synchronization (via Git Hooks)

The system uses Git hooks to automate synchronization:

- **pre-commit hook**: When you commit local changes, they're automatically pushed to external submodules
- **post-merge hook**: When you pull changes, external changes are automatically pulled to local configs

### 2. Manual Synchronization (via Script)

For more control, use the synchronization script:

```bash
# Pull changes from external to local
./scripts/sync-bidirectional.sh from-external

# Push changes from local to external
./scripts/sync-bidirectional.sh to-external

# Smart sync (both directions, based on timestamps)
./scripts/sync-bidirectional.sh both

# Check synchronization status
./scripts/sync-bidirectional.sh status
```

## 🚀 Workflow Examples

### Scenario 1: Developing in Local Configurations

```bash
# 1. Modify local configuration
nano hosts/rtr-sapinet/role-variables.nix

# 2. Commit changes (automatically syncs to external)
git add hosts/rtr-sapinet
git commit -m "feat: Update spine role configuration"
# → pre-commit hook runs: syncs to external/rtr-sapinet-config

# 3. Push everything
git push origin master
cd external/rtr-sapinet-config && git push origin master
```

### Scenario 2: Developing in External Configurations

```bash
# 1. Modify external configuration
nano external/rtr-noisy-config/variables.nix

# 2. Commit and push external changes
cd external/rtr-noisy-config
git add .
git commit -m "fix: Update BGP configuration"
git push origin master
cd ../..

# 3. Pull changes (automatically syncs to local)
git pull origin master
# → post-merge hook runs: syncs to hosts/rtr-noisy
```

### Scenario 3: Team Collaboration

```bash
# Team member 1 works on spine:
# - Modifies hosts/rtr-sapinet/
# - Commits → auto-syncs to external
# - Pushes both repos

# Team member 2 pulls changes:
# - git pull → auto-syncs from external to local
# - Now has latest changes in both locations
```

## 📖 Best Practices

### 1. Always Check Status Before Committing
```bash
./scripts/sync-bidirectional.sh status
```

### 2. Use Smart Sync for Complex Changes
```bash
./scripts/sync-bidirectional.sh both
```

### 3. Commit Related Changes Together
- If you modify both local and external, use `both` mode
- Keep related changes in the same commit

### 4. Handle Conflicts Manually
- If both versions have changed, Git will show conflicts
- Resolve conflicts, then commit

## 🔧 Troubleshooting

### "Out of sync" errors
```bash
# Check which files are different
./scripts/sync-bidirectional.sh status

# Force sync in the desired direction
./scripts/sync-bidirectional.sh from-external  # or to-external
```

### Hooks not working
```bash
# Make sure hooks are executable
chmod +x .git/hooks/pre-commit .git/hooks/post-merge

# Check hook permissions
ls -la .git/hooks/
```

### Permission errors
```bash
# Make sure script is executable
chmod +x scripts/sync-bidirectional.sh
```

## 🛡️ Security Notes

1. **Hooks are local**: Git hooks are not versioned, so each developer needs to set them up
2. **Review before push**: Always review what the hook is committing
3. **Backup important changes**: Before major sync operations

## 📚 Advanced Usage

### Disable Hooks Temporarily
```bash
# Skip pre-commit hook
SKIP=pre-commit git commit -m "message"

# Or move hooks temporarily
mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled
```

### Custom Synchronization
```bash
# Sync only specific files
cp hosts/rtr-sapinet/role-variables.nix external/rtr-sapinet-config/

# Sync with backup
cp -b hosts/rtr-noisy/*.nix external/rtr-noisy-config/
```

## 🎯 Benefits of This System

1. **Flexibility**: Work in local or external configs
2. **Automation**: No manual sync needed in most cases
3. **Safety**: Check status before committing
4. **Collaboration**: Team members stay in sync
5. **Backup**: External repos serve as backup
6. **Deployment**: External repos can be deployed independently

This synchronization strategy provides the best of both worlds: the convenience of local development with the robustness of external version control.