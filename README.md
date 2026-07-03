# 🔄 zsh-sync

> **Multi-device ZSH history backup & sync system**

Automatically backup and synchronize your ZSH command history across multiple macOS devices using Git/GitHub with intelligent conflict-free device management.

**Author:** Gopesh Chaudhary

---

## Why zsh-sync?

Your ZSH history is your most valuable reference—commands you've run, patterns you've used, automations you've built. But it's:

- 🚫 **Lost** on device restart or OS upgrade
- 🚫 **Isolated** to a single machine
- 🚫 **Unversioned** and unrecoverable if deleted
- 🚫 **Fragmented** across multiple Macs

**zsh-sync** solves all of this with intelligent multi-device synchronization.

---

## ✨ Key Features

### Backup & Sync
- 💾 **Incremental Backups** - Only new commands since last backup
- 🔗 **Git Integration** - Full version control with GitHub
- 📦 **Smart Chunking** - Split 29MB+ histories into manageable 20MB chunks
- ✅ **Hash Validation** - SHA256 integrity on all chunks

### Multi-Device
- 🔄 **Auto-Sync Mode (SYNCALL)** - Automatically merge histories from all devices
- 🔒 **Isolated Mode (NOSYNC)** - Keep device separate while contributing to others
- 🚫 **Zero Conflicts** - Device-specific directories prevent collisions
- ⚡ **Concurrent Backups** - Multiple devices backup simultaneously

### Reliability
- 🛡️ **Corruption Detection** - Command-count based validation
- 🔙 **Auto-Rollback** - Previous backups kept for recovery
- 📍 **Backup Markers** - Track boundaries in ZSH history
- 🧹 **Auto-Cleanup** - Keeps repository lean

---

## 🚀 Quick Start

### 1. Setup (2 minutes)

```bash
# Create repo
mkdir -p ~/zsh-sync && cd ~/zsh-sync
git init

# Copy script
curl -O https://raw.githubusercontent.com/briskgopesh/zsh-sync/main/src/chunk-backup.sh
chmod +x chunk-backup.sh

# Configure
echo 'export SYNC_MODE=SYNCALL' >> ~/.zshrc
source ~/.zshrc
```

### 2. First Backup

```bash
# Full backup of entire history
./chunk-backup.sh --reset
# Type: YES
```

### 3. Push to GitHub

```bash
# Create private repo on GitHub, then:
git remote add origin git@github.com:USERNAME/zsh-sync.git
git branch -M main
git add .
git commit -m "Initial backup"
git push -u origin main
```

### 4. Automatic Daily Backups

```bash
# Runs automatically when you open terminal
# (add to ~/.zshrc):
export SYNC_MODE=SYNCALL
```

---

## 📋 Configuration

### SYNCALL Mode (Primary Device)
```bash
export SYNC_MODE=SYNCALL
```
- Automatically pulls history from all other devices
- Always has combined history
- Use on your main Mac
- ~5-10s backup time

### NOSYNC Mode (Secondary Device)
```bash
export SYNC_MODE=NOSYNC
```
- Keeps device isolated
- Doesn't auto-merge
- Other devices can pull your history
- Use on personal/backup Macs
- ~1-2s backup time

---

## 🔄 Multi-Device Example

### Setup Two Macs

**Mac 1 (Work):**
```bash
export SYNC_MODE=SYNCALL
```

**Mac 2 (Personal):**
```bash
export SYNC_MODE=NOSYNC
```

### Result: Automatic Sync

```
Mac 1 (SYNCALL):
  ✓ Pulls Mac 2's commands automatically
  ✓ Has combined history from both
  ✓ One command to back up: ./chunk-backup.sh

Mac 2 (NOSYNC):
  ✓ Backs up own commands only
  ✓ Stays isolated (as intended)
  ✓ But Mac 1 syncs with it anyway!

Workflow:
  Mac 2 back up → Mac 1 pulls → Both in sync ✓
```

---

## 📖 Commands

```bash
# Backup current device
./chunk-backup.sh

# Force backup (skip checks)
./chunk-backup.sh --force

# Full reset (capture all history)
./chunk-backup.sh --reset

# Clean old backup folders
./chunk-backup.sh --cleanup

# Check config
jq '.[].chunks | {timestamp, command_count}' config.json
```

---

## 📊 What You Get

### Single Device
```
Input:  ~/.zsh_history = 29 MB, 275,585 commands
Output: 2 chunks (15MB + 14MB) in Git
Result: ✓ Full backup with version control
```

### Two Devices (SYNCALL + NOSYNC)
```
Work Mac:    300,000 commands
Personal:    200,000 commands

After sync:
Work Mac:    500,000+ commands (combined + unique)
Personal:    200,000 commands (isolated, as configured)
```

---

## 🛡️ Safety

- ✅ **Private Repo** - Keep on GitHub private
- ✅ **Hash Verified** - Every chunk checked on backup
- ✅ **Auto Backup** - Previous state kept safe
- ✅ **Git History** - Full audit trail of all backups
- ✅ **No Data Loss** - Recover from any backup

---

## 🐛 Troubleshooting

### Config update failed?
```bash
git checkout HEAD -- config.json
./chunk-backup.sh
```

### History not fully backed up?
```bash
./chunk-backup.sh --reset
# Type: YES
```

### Git push fails?
```bash
git remote -v
# Verify remote is set correctly
```

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more.

---

## 📚 Documentation

- **[SYNC_MODES.md](docs/SYNC_MODES.md)** - Deep dive on SYNCALL/NOSYNC
- **[MULTI_DEVICE.md](docs/MULTI_DEVICE.md)** - Multi-device setup guide
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Technical details
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues

---

## ⚡ Performance

| Operation | Time |
|-----------|------|
| Fresh backup (29MB) | 3-5s |
| Incremental (10 cmds) | <1s |
| SYNCALL merge | 5-10s |
| Git push | 2-5s |

---

## 💾 Storage

- Single device: ~30 MB
- Two devices: ~60-70 MB
- Three devices: ~90-110 MB
- GitHub: Free tier supports 100 GB

---

## 🔐 Best Practices

1. **Keep repo private** on GitHub
2. **Use SSH key** (not HTTPS)
3. **Review history** before committing sensitive data
4. **Rotate SSH keys** every 6 months
5. **Backup to GitHub** as primary recovery method

---

## 🤝 Contributing

Found a bug? Have an idea? We'd love your help!

1. Fork the repo
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for more.

---

## 📄 License

MIT License - Use freely, modify as needed.

```
Copyright (c) 2026 Gopesh Chaudhary

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without not limited to the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

## 🎯 Roadmap

- [ ] Automated GitHub Actions for CI
- [ ] Homebrew formula for easy install
- [ ] Web dashboard for backup visualization
- [ ] Encryption support for sensitive histories
- [ ] CLI tool for easy management
- [ ] History search/grep integration
- [ ] MacOS App Store release (future)

---

## 💬 Questions?

- 📖 Check the [docs](docs/) folder
- 🐛 Open an [issue](https://github.com/briskgopesh/zsh-sync/issues)
- 💬 Start a [discussion](https://github.com/briskgopesh/zsh-sync/discussions)

---

## 🙏 Acknowledgments

Built with:
- ❤️ Care for preserving valuable command history
- 🔧 Bash scripting best practices
- 🎯 User-first design principles
- 📚 Open-source philosophy

---

## 🌟 Show Your Support

If zsh-sync helps you, please:
- ⭐ Star the repository
- 📢 Share with friends
- 🐛 Report bugs
- 💡 Suggest features

---

## 📞 Connect

**Author:** Gopesh Chaudhary
- GitHub: [@briskgopesh](https://github.com/briskgopesh)
- Email: briskgopesh@proton.me

---

**Made with ❤️ for the ZSH community**

*Save your command history. Sync across devices. Never lose a command again.*
