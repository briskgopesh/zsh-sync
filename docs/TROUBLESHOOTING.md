# 🐛 Troubleshooting Guide

## Common Issues & Solutions

### Issue 1: Config Update Failed

**Error Message:**
```
✗ Failed to update config.json
```

**Cause:** jq syntax error or corrupted config.json

**Solution:**
```bash
# Restore from git
git checkout HEAD -- config.json

# Or recreate it
echo "{}" > config.json

# Try backup again
./chunk-backup.sh
```

---

### Issue 2: Git Push Fails

**Error Message:**
```
✗ Push failed
```

**Causes & Solutions:**

```bash
# 1. Check remote is configured
git remote -v
# Should show: origin  git@github.com:username/zsh-sync.git

# 2. If not set:
git remote add origin git@github.com:USERNAME/zsh-sync.git

# 3. Verify SSH key works
ssh -T git@github.com
# Should say: authenticated as USERNAME

# 4. If SSH not working, check key:
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
# Add public key to GitHub Settings

# 5. Try again
./chunk-backup.sh
```

---

### Issue 3: History Not Backing Up Full Size

**Symptom:**
```
Total Size: 850B (should be 29MB)
Total Commands: 24 (should be 275K)
```

**Cause:** Only incremental backups are captured

**Solution:**
```bash
# Do a full reset to capture entire history
./chunk-backup.sh --reset

# Type: YES

# Verify size
du -sh chunks/YOUR_UUID/
# Should show: 29M (not 850B!)
```

---

### Issue 4: Laptop UUID Not Detected

**Symptom:**
```
Laptop:
Hostname:
```

**Solution:**
```bash
# Verify system has UUID
system_profiler SPHardwareDataType | grep UUID

# If empty, use alternate method:
ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $(NF-1)}'

# Manually set if needed:
export LAPTOP_ID="your-uuid-here"
./chunk-backup.sh
```

---

### Issue 5: No Space on Disk

**Symptom:**
```
✗ Failed to split chunks
```

**Solution:**
```bash
# Clean old backups
./chunk-backup.sh --cleanup

# Check disk space
df -h
# Free up space if <5GB available

# Try backup again
./chunk-backup.sh
```

---

### Issue 6: ZSH History File Corrupted

**Symptom:**
```
Merged: 0 commands
```

**Solution:**
```bash
# Restore from backup
cat chunks/YOUR_UUID/chunk_* > ~/.zsh_history

# Reload shell
exec zsh

# Or restore from GitHub
git pull origin main
cat chunks/YOUR_UUID/chunk_* > ~/.zsh_history
exec zsh
```

---

### Issue 7: SYNC_MODE Not Working

**Symptom:**
```
Mode: (blank or wrong mode)
```

**Solution:**
```bash
# Set environment variable
export SYNC_MODE=SYNCALL
# or
export SYNC_MODE=NOSYNC

# Add to ~/.zshrc for persistence
echo 'export SYNC_MODE=SYNCALL' >> ~/.zshrc
source ~/.zshrc

# Verify it's set
echo $SYNC_MODE

# Try backup
./chunk-backup.sh
```

---

### Issue 8: "No such file or directory"

**Cause:** Script not finding directories or files

**Solution:**
```bash
# Verify directory exists
ls -la ~/zsh-sync/

# Create if missing
mkdir -p ~/zsh-sync/{src,docs,examples,chunks,logs}

# Make script executable
chmod +x chunk-backup.sh

# Try again
./chunk-backup.sh
```

---

### Issue 9: jq Command Not Found

**Error:**
```
jq: command not found
```

**Solution:**
```bash
# Install jq
brew install jq

# Verify installation
jq --version

# Try backup again
./chunk-backup.sh
```

---

### Issue 10: Permission Denied

**Error:**
```
Permission denied: ./chunk-backup.sh
```

**Solution:**
```bash
# Make script executable
chmod +x chunk-backup.sh

# Verify
ls -la chunk-backup.sh
# Should show: -rwxr-xr-x

# Try again
./chunk-backup.sh
```

---

## 🔍 Debug Mode

### Enable Verbose Output

```bash
# Run with bash debug mode
bash -x ./chunk-backup.sh 2>&1 | tee debug.log

# View log
cat debug.log
```

### Check System Requirements

```bash
# Verify ZSH
echo $SHELL
# Should output: /bin/zsh

# Verify Git
git --version

# Verify jq
jq --version

# Verify backup directory
ls -la ~/zsh-sync/
```

### Check Config

```bash
# View config structure
cat config.json | jq .

# Check device UUID
jq 'keys[0]' config.json

# Check chunk info
jq '.[].chunks' config.json
```

---

## 📋 Pre-Troubleshooting Checklist

Before contacting support:

- [ ] ZSH shell confirmed: `echo $SHELL` = `/bin/zsh`
- [ ] Git installed: `git --version`
- [ ] jq installed: `jq --version`
- [ ] Script executable: `chmod +x chunk-backup.sh`
- [ ] Directory exists: `ls -la ~/zsh-sync/`
- [ ] SSH key works: `ssh -T git@github.com`
- [ ] Disk space: `df -h` (>5GB available)
- [ ] Run debug mode: `bash -x ./chunk-backup.sh`

---

## 💬 Getting Help

If troubleshooting doesn't work:

1. **Check logs:**
   ```bash
   tail -100 logs/backup-*.log
   ```

2. **Run debug:**
   ```bash
   bash -x ./chunk-backup.sh 2>&1 | tee debug.log
   ```

3. **Open issue on GitHub:**
   - Include error message
   - Include debug log
   - Include macOS version
   - Include ZSH version

4. **Include system info:**
   ```bash
   system_profiler SPSoftwareDataType | grep "System Version"
   zsh --version
   git --version
   jq --version
   ```

---

## ✅ Verification

After fixing issue, verify everything works:

```bash
# Run backup
./chunk-backup.sh

# Check status
jq '.[].chunks | {timestamp, command_count}' config.json

# Verify git
git log --oneline | head -5

# Check disk usage
du -sh ~/zsh-sync/chunks/
```

If everything shows:
- ✅ Backup completed
- ✅ Config updated
- ✅ Git committed
- ✅ Size reasonable

**You're all set!** 🎉

---

**Still having issues?** Open an issue on GitHub with debug output.
