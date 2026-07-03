# Contributing to zsh-sync

Thank you for your interest in contributing! We'd love your help to make zsh-sync even better.

## 🚀 Ways to Contribute

### Report Bugs
Found a bug? Please open an [issue](https://github.com/briskgopesh/zsh-sync/issues) with:
- Clear description of the problem
- Steps to reproduce
- Expected vs actual behavior
- Your setup (macOS version, ZSH version, etc.)

### Suggest Features
Have an idea? Start a [discussion](https://github.com/briskgopesh/zsh-sync/discussions) or open an issue with:
- Use case and motivation
- How it would work
- Potential implementation approach

### Improve Documentation
Found unclear docs? Submit a PR to fix:
- Typos and grammar
- Unclear explanations
- Missing examples
- Better organization

### Fix Code
Ready to code? Follow this workflow:

## 📋 Contribution Workflow

### 1. Fork & Clone
```bash
# Fork on GitHub, then:
git clone https://github.com/YOUR_USERNAME/zsh-sync.git
cd zsh-sync
git remote add upstream https://github.com/briskgopesh/zsh-sync.git
```

### 2. Create Feature Branch
```bash
git checkout -b feature/amazing-idea
```

### 3. Make Changes
- Write clean, readable code
- Follow existing code style
- Add comments for complex logic
- Test your changes thoroughly

### 4. Commit with Clear Messages
```bash
git commit -m "Add amazing feature

- Describe what changed
- Explain why it's needed
- Reference related issues (#123)"
```

### 5. Push & Open PR
```bash
git push origin feature/amazing-idea
```
Then open a Pull Request on GitHub with:
- Clear title
- Description of changes
- Motivation/use case
- Tested on which macOS/ZSH versions

## 🎯 Code Guidelines

### Shell Script Best Practices
- Use `#!/bin/bash` and `set -o pipefail`
- Quote variables: `"$variable"` not `$variable`
- Use meaningful variable names
- Add comments for non-obvious logic
- Test edge cases

### Documentation
- Use Markdown with clear headings
- Include code examples
- Add troubleshooting sections
- Keep lines <100 characters

### Testing
Before submitting:
```bash
# Test on your machine
./chunk-backup.sh

# Try all modes
SYNC_MODE=SYNCALL ./chunk-backup.sh
SYNC_MODE=NOSYNC ./chunk-backup.sh

# Test --force and --reset
./chunk-backup.sh --force
./chunk-backup.sh --reset

# Verify git integration
git log
git status
```

## 📚 Project Structure

```
zsh-sync/
├── src/
│   └── chunk-backup.sh        # Main script
│   └── chunk-validate.sh      # Integrity check script
│   └── chunk-restore.sh       # Recovery script
├── docs/
│   ├── SYNC_MODES.md
│   ├── MULTI_DEVICE.md
│   ├── TROUBLESHOOTING.md
│   └── ARCHITECTURE.md
├── examples/
│   └── .zshrc-example
└── README.md
```

## 🔄 Review Process

1. **Automated checks** - GitHub Actions validates shell script
2. **Code review** - Maintainer reviews changes
3. **Testing** - Verified on multiple macOS/ZSH versions
4. **Merge** - PR merged when approved

## 📝 Commit Message Guidelines

```
[scope] Concise description (50 chars max)

More detailed explanation if needed.
- Explain what changed and why
- Reference issues: Fixes #123
- Reference PRs: See #456

Signed-off-by: Your Name <your.email@example.com>
```

### Scopes
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Formatting
- `test:` - Adding tests
- `refactor:` - Code restructuring

## ❓ Questions?

- 📖 Check [README.md](README.md) and [docs/](docs/)
- 💬 Open a [discussion](https://github.com/briskgopesh/zsh-sync/discussions)
- 📧 Contact maintainer at briskgopesh@proton.me

## 🙏 Thank You!

Your contributions make zsh-sync better for everyone. We appreciate you!

---

**Code of Conduct:** Be respectful, inclusive, and professional. This is a safe space for all contributors.
