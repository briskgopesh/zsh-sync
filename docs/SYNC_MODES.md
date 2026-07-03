# 🔄 SYNC_MODE Configuration Guide

Automatic multi-device sync with configurable behavior!

## Overview

Two sync modes:
- **SYNCALL**: Auto-merge all other devices' histories into this device
- **NOSYNC**: Keep this device isolated, don't auto-merge

---

## Mode 1: SYNCALL (Recommended for Primary Mac)

```bash
SYNC_MODE=SYNCALL ./chunk-backup.sh
```

### Behavior

Every backup automatically:
1. Pulls histories from all other devices
2. Merges them together with deduplication
3. Updates own history with all commands
4. Backs up combined history

### Example

```
Laptop A (SYNCALL):
  Own: 300,000 commands
  Pull Laptop B: 200,000 commands
  Pull Laptop C: 150,000 commands
  
  Merge all:
  Result: 550,000+ unique commands ✓
  
  Backup: 550,000 commands
```

### Use Cases

- Primary work Mac
- Mac you use most often
- Central device for all histories

### Output

```
▶ Step 1: Checking backup status
Sync Mode: SYNCALL (auto-merge all devices)

▶ Auto-syncing from other devices
  Syncing from: personal-mbp (E2B984G8-...)
    Commands: 200,000
  Syncing from: server (ABC123...)
    Commands: 150,000
  ✓ Synced: 350,000 commands from other devices

▶ Step 2: Extracting new commands
New commands: 50 commands
```

---

## Mode 2: NOSYNC (Recommended for Secondary/Backup Macs)

```bash
SYNC_MODE=NOSYNC ./chunk-backup.sh
```

### Behavior

Every backup:
1. Backs up ONLY own history
2. Does NOT merge from other devices
3. Stays isolated

### Example

```
Laptop B (NOSYNC):
  Own: 200,000 commands
  
  Backup: 200,000 commands (isolated)
  
  Other devices can pull this, but B stays isolated
```

### Use Cases

- Secondary personal Mac
- Backup Mac (rarely used)
- Isolated environment
- Test/temporary device

### Output

```
▶ Step 1: Checking backup status
Sync Mode: NOSYNC (keep isolated)

(No auto-sync step)

▶ Step 2: Extracting new commands
New commands: 45 commands

ℹ This device keeps history isolated (NOSYNC mode)
```

---

## Configuration

### Set for Current Session

```bash
SYNC_MODE=SYNCALL ./chunk-backup.sh
```

### Set Permanently

Add to your shell config (`~/.zshrc`, `~/.bashrc`):

```bash
# Add this line:
export SYNC_MODE=SYNCALL

# Or for isolated device:
export SYNC_MODE=NOSYNC
```

Then every backup uses that mode by default.

### Check Config Storage

Sync mode is stored in config.json:

```json
{
  "C1A873F7-...": {
    "hostname": "work-mac",
    "sync_mode": "SYNCALL",
    "chunks": {...}
  },
  "E2B984G8-...": {
    "hostname": "personal-mbp",
    "sync_mode": "NOSYNC",
    "chunks": {...}
  }
}
```

---

## Real-World Scenarios

### Scenario 1: One SYNCALL, One NOSYNC

```
Mac 1 (Work):    SYNCALL
Mac 2 (Personal): NOSYNC

Mac 1 backup:
  Pull Mac 2's 200K commands
  Merge with own 300K
  Result: 450K commands ✓

Mac 2 backup:
  Keep own 200K commands
  Don't auto-merge
  Result: 200K commands (isolated) ✓

Then later, Mac 2 can pull from Mac 1:
  chunk-restore --device MAC1_UUID --merge
  Now Mac 2 has: 450K commands
```

### Scenario 2: Two SYNCALL Devices

```
Mac A (Work):      SYNCALL
Mac B (Personal):  SYNCALL

Mac A backup (10:00):
  Has own: 300K
  Pull Mac B: 200K
  Merge: 450K
  Backup: 450K ✓

Mac B backup (10:05):
  Has own: 200K
  Pull Mac A's newest: 450K
  Merge: 480K unique
  Backup: 480K ✓

Mac A sync:
  git pull
  Pull Mac B's newest: 480K
  Merge: 490K unique
  
Result: Both eventually have all 490K+ commands ✓
```

### Scenario 3: Three Devices (Mixed Modes)

```
Mac Work (SYNCALL):     300K commands
Mac Personal (SYNCALL): 200K commands
Mac Backup (NOSYNC):    100K commands

Sync flow:

1. Mac Work backup:
   Pull Personal: 200K
   Pull Backup: 100K
   Merge: 500K ✓

2. Mac Personal backup:
   Pull Work: 500K
   Own: 200K
   Merge: 620K ✓

3. Mac Backup backup:
   Keep: 100K (isolated, no pull)
   Result: 100K (isolated)

4. Mac Work pulls latest:
   Gets Mac Personal's: 620K
   Merge with own: 640K

Result:
  Mac Work:     640K commands (has everything)
  Mac Personal: 620K commands (has everything)
  Mac Backup:   100K commands (isolated, as intended)
```

---

## Default Behavior

If you don't set SYNC_MODE:

```bash
./chunk-backup.sh
# Uses: SYNC_MODE=SYNCALL (default)
```

To change default, edit script line:

```bash
SYNC_MODE="${SYNC_MODE:-SYNCALL}"  # Change SYNCALL to NOSYNC here
```

---

## Commands with SYNC_MODE

```bash
# Use SYNCALL
SYNC_MODE=SYNCALL ./chunk-backup.sh

# Use NOSYNC
SYNC_MODE=NOSYNC ./chunk-backup.sh

# Force mode
SYNC_MODE=SYNCALL ./chunk-backup.sh --force

# Reset (respects mode)
SYNC_MODE=NOSYNC ./chunk-backup.sh --reset
```

---

## Viewing Sync Status

```bash
# Check all devices and their modes
cat config.json | jq '.[] | {hostname, sync_mode, command_count}'

Output:
{
  "hostname": "work-mac",
  "sync_mode": "SYNCALL",
  "command_count": 300000
}
{
  "hostname": "personal-mbp",
  "sync_mode": "NOSYNC",
  "command_count": 200000
}
```

---

## Changing Sync Mode

Device can change its mode anytime:

```bash
# Was NOSYNC, now switch to SYNCALL
SYNC_MODE=SYNCALL ./chunk-backup.sh

# Config.json updated automatically
# Next backup uses new mode
```

---

## FAQ

### Q: Can I run NOSYNC on all devices?
**A:** Yes, but then no auto-sync happens. You'd need to manually merge with `chunk-restore --merge` if desired.

### Q: What if one device is SYNCALL and another is NOSYNC?
**A:** 
- SYNCALL device pulls NOSYNC device's history ✓
- NOSYNC device doesn't pull automatically
- NOSYNC device stays isolated unless manually merged

### Q: Should my primary Mac be SYNCALL?
**A:** Yes! It ensures you always have all histories from all devices.

### Q: What about backup conflicts?
**A:** None! Each device has separate chunks in `chunks/DEVICE_UUID/`. Different directories = no conflicts.

### Q: How many commands is safe?
**A:** Tested up to 500K+ commands. System handles it fine. Just slower merging.

### Q: Does SYNCALL slow down backups?
**A:** Yes, slightly. It needs to:
1. Read all other devices' chunks
2. Merge and deduplicate
3. Then split and backup

For 500K commands: ~5-10 seconds instead of ~2-5 seconds.

Use NOSYNC on slower devices to keep them fast.

### Q: Can I switch modes later?
**A:** Yes! 
```bash
# Was SYNCALL, now nosync
SYNC_MODE=NOSYNC ./chunk-backup.sh
# Mode updated in config.json
```

---

## Best Practices

### Setup 1: Work + Personal (Recommended)

```bash
# On Work Mac
SYNC_MODE=SYNCALL ./chunk-backup.sh
export SYNC_MODE=SYNCALL  # In ~/.zshrc

# On Personal Mac
SYNC_MODE=NOSYNC ./chunk-backup.sh
export SYNC_MODE=NOSYNC  # In ~/.zshrc

# Work Mac gets all histories
# Personal Mac stays isolated but can be pulled
```

### Setup 2: All in Sync

```bash
# All Macs
SYNC_MODE=SYNCALL ./chunk-backup.sh
export SYNC_MODE=SYNCALL  # In ~/.zshrc

# All devices eventually have all commands
# Good for teams or power users
```

### Setup 3: Central Hub

```bash
# On NAS/Server (Primary)
SYNC_MODE=SYNCALL ./chunk-backup.sh

# On Mac 1 (Secondary)
SYNC_MODE=NOSYNC ./chunk-backup.sh

# On Mac 2 (Secondary)
SYNC_MODE=NOSYNC ./chunk-backup.sh

# Server has everything
# Individual Macs stay isolated
```

---

## Storage Efficiency

```
NOSYNC (4 Macs):
  Mac 1: 25 MB
  Mac 2: 30 MB
  Mac 3: 28 MB
  Mac 4: 35 MB
  ─────────────
  Total: 118 MB

SYNCALL (1 primary, 3 secondary):
  Primary: 95 MB (all histories combined)
  Secondary 1: 25 MB (isolated)
  Secondary 2: 30 MB (isolated)
  Secondary 3: 28 MB (isolated)
  ─────────────
  Total: 178 MB (more stored)

Trade-off: More storage vs always-synced history
```

---

## Summary

| Aspect | SYNCALL | NOSYNC |
|--------|---------|--------|
| Auto-merge | Yes, always | No |
| Other devices' commands | Included | Excluded |
| Storage size | Larger | Smaller |
| Backup speed | Slower | Faster |
| Conflicts | None | None |
| Use case | Primary | Secondary |
| Manual merge | Can do | Can do |

---

## Implementation Details

### Auto-sync happens in Step 1.5

```bash
▶ Step 1: Checking backup status
  (shows last backup)

▶ Step 1.5: Auto-syncing (if SYNCALL)
  ✓ Synced from other devices

▶ Step 2: Extracting new commands
  (continues normally)
```

### Each device's chunks isolated

```
chunks/
├── C1A873F7-.../ (Device 1's chunks)
│   ├── chunk_aa
│   └── chunk_ab
└── E2B984G8-.../ (Device 2's chunks)
    ├── chunk_aa
    └── chunk_ab
```

### Single config.json tracks all

```json
{
  "C1A873F7-...": {sync_mode: "SYNCALL", ...},
  "E2B984G8-...": {sync_mode: "NOSYNC", ...}
}
```

---

## Next Steps

1. Set SYNC_MODE in your shell config:
   ```bash
   export SYNC_MODE=SYNCALL  # Or NOSYNC
   ```

2. Run backup:
   ```bash
   ./chunk-backup.sh
   ```

3. Check config to verify mode is saved:
   ```bash
   jq '.[].sync_mode' config.json
   ```

Done! Now your backups respect sync mode! 🎉
