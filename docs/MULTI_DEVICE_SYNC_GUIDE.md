# 🔄 Multi-Device Sync System

Restore and sync ZSH history between multiple laptops!

## Use Cases

### Case 1: Restore Laptop A's History to Laptop B
```
Laptop A: 275,564 commands
Laptop B: 150,000 commands

After restore:
Laptop B: 275,564 commands (same as A) ✓
```

### Case 2: Merge Both Histories
```
Laptop A: 275,564 commands
Laptop B: 150,000 commands (different commands)

After merge:
Both: 350,000 commands (combined, deduped) ✓
```

### Case 3: Keep Both Laptops in Sync
```
Laptop A: Backup → 300,000 commands
Laptop B: Pull → 300,000 commands ✓
Laptop B: Add 50 new → 300,050 commands
Laptop B: Backup
Laptop A: Pull → 300,050 commands ✓
(Continuous sync)
```

---

## Three Sync Strategies

### Strategy 1: REPLACE
```
Restore Device A's history TO Device B
(B's history completely replaced by A's)

Before:
  A: 275,564 commands
  B: 150,000 commands (lost!)

After:
  A: 275,564 commands
  B: 275,564 commands (identical) ✓
```

Use when: B's history is corrupted/wrong

### Strategy 2: MERGE
```
Combine A's + B's histories
(All unique commands from both devices)

Before:
  A: commands 1-275,564
  B: commands 150,000-300,000 (different!)

After (both):
  A: commands 1-300,000 (unique combined) ✓
  B: commands 1-300,000 (unique combined) ✓
```

Use when: Both have different unique commands

### Strategy 3: MERGE WITH TIMESTAMPS
```
Combine keeping chronological order
(Preserve when each command was executed)

Before:
  A: timestamp-sorted commands
  B: timestamp-sorted commands (overlapping)

After (both):
  Merged by timestamp, deduped ✓
  Full command history preserved
  Proper chronological order
```

Use when: Want complete history with timing

---

## Commands

### List All Devices
```bash
chunk-list-devices

Output:
Devices in backup repository:

1. C1A873F7-E8F2-5512-9457-44841C008C2B
   Hostname: gopeshchaudhary-mac (current)
   Chunks: 2
   Size: 29 MB
   Commands: 275,564
   Last backup: 2026-07-04T14:30:00Z

2. E2B984G8-F1A3-5612-9568-55942D119C3D
   Hostname: personal-mbp
   Chunks: 3
   Size: 50 MB
   Commands: 450,000
   Last backup: 2026-07-04T15:30:00Z
```

### Check Current Device
```bash
chunk-status

ZSH Chunk Backup Status:
  Laptop: C1A873F7-...
  Hostname: gopeshchaudhary-mac
  Chunks: 2
  Size: 29 MB
  Commands: 275,564
```

### Restore From Another Device (REPLACE)
```bash
# Restore Laptop B's history to current (Laptop A)
chunk-restore --device E2B984G8-F1A3-5612-9568-55942D119C3D

Are you sure? This will REPLACE your history.
Current commands: 275,564
New commands: 450,000
Difference: +174,436 commands

Restore? (type 'YES' to confirm): YES

✓ Validating device E2B984G8-...
✓ Extracting 450,000 commands
✓ Restoring to ~/.zsh_history
✓ Backup: ~/.zsh_history.backup.20260704_143000

Result:
  Before: 275,564 commands
  After: 450,000 commands (from Laptop B) ✓
```

### Merge From Another Device (COMBINE)
```bash
# Merge Laptop B's history WITH current (Laptop A)
chunk-restore --device E2B984G8-F1A3 --merge

Merge strategy?
1) REPLACE   - B's history replaces A's
2) MERGE     - Combine both, deduplicate
3) MERGE_TS  - Combine with timestamps

Choose (1-3): 2

✓ Validating device E2B984G8-...
✓ Extracting 450,000 commands
✓ Your commands: 275,564
✓ Other device: 450,000
✓ Merging... (deduplicating)
✓ Backup: ~/.zsh_history.backup.20260704_143000

Result:
  Device A (before): 275,564 commands
  Device B (before): 450,000 commands
  After merge: 520,314 commands (unique combined) ✓
```

### Merge with Timestamps (CHRONOLOGICAL)
```bash
chunk-restore --device E2B984G8-F1A3 --merge --timestamps

✓ Validating device E2B984G8-...
✓ Extracting 450,000 commands
✓ Your commands: 275,564
✓ Other device: 450,000
✓ Merging by timestamp... (preserving order)
✓ Deduplicating...

Result:
  A + B merged in chronological order ✓
  All unique commands preserved ✓
  Timestamps respected ✓
```

### Compare Devices
```bash
chunk-compare C1A873F7-... E2B984G8-...

Comparing devices:

Device A (gopeshchaudhary-mac):
  Commands: 275,564
  Size: 29 MB
  Last backup: 2026-07-04T14:30:00Z

Device B (personal-mbp):
  Commands: 450,000
  Size: 50 MB
  Last backup: 2026-07-04T15:30:00Z

Differences:
  Device A only: 50,000 commands
  Device B only: 225,000 commands
  Common: 200,000 commands
  Combined unique: 475,000 commands

Recommendation: MERGE
(Both have unique commands worth keeping)
```

---

## Real-World Scenario: Two Macs

### Setup
```
Mac 1 (Work):
  - 300,000 commands
  - Latest backup: 2026-07-04T10:00:00Z

Mac 2 (Personal):
  - 200,000 commands  
  - Latest backup: 2026-07-04T09:00:00Z

Goal: Keep both in sync
```

### Step 1: Check Current State
```bash
# On Mac 1
chunk-list-devices

Devices:
1. Work Mac (current)
   Commands: 300,000
   Last: 2026-07-04T10:00:00Z

2. Personal Mac
   Commands: 200,000
   Last: 2026-07-04T09:00:00Z
```

### Step 2: Compare
```bash
chunk-compare WORK_UUID PERSONAL_UUID

Results:
  Work only: 100,000 commands
  Personal only: 50,000 commands
  Common: 150,000 commands
  
→ Both have unique commands!
→ MERGE is better than REPLACE
```

### Step 3a: Merge on Mac 1
```bash
# On Mac 1, pull Personal Mac's history
chunk-restore --device PERSONAL_UUID --merge --timestamps

✓ Merged: 300,000 + 200,000 = 325,000 unique commands

# Backup merged result
chunk-backup.sh

✓ Pushed to GitHub with 325,000 commands
```

### Step 3b: Sync to Mac 2
```bash
# On Mac 2
git pull origin master

chunk-restore --device WORK_UUID --merge --timestamps

✓ Merged: 200,000 + 325,000 = 335,000 unique commands

# Backup merged result
chunk-backup.sh

✓ Pushed to GitHub with 335,000 commands
```

### Step 3c: Sync Back to Mac 1
```bash
# On Mac 1
git pull origin master

chunk-restore --device PERSONAL_UUID --merge --timestamps

✓ Now both have 335,000 commands ✓
```

### Result: Both Macs in Sync
```
Before:
  Mac 1: 300,000 commands
  Mac 2: 200,000 commands

After:
  Mac 1: 335,000 commands ✓
  Mac 2: 335,000 commands ✓
  (All unique commands from both)
```

---

## Sync Strategies Explained

### Replace (SIMPLE)
```bash
chunk-restore --device OTHER_UUID

Use when:
  • Other device has "correct" history
  • Your history is corrupted
  • You want exact copy
  
Result: Your history = Other's history
```

### Merge (INTELLIGENT)
```bash
chunk-restore --device OTHER_UUID --merge

Use when:
  • Both have unique valuable commands
  • Want to keep all unique commands
  • Don't care about timestamps
  
Result: Your history = Combined unique commands
```

### Merge with Timestamps (BEST)
```bash
chunk-restore --device OTHER_UUID --merge --timestamps

Use when:
  • Want complete history with timing
  • Commands need chronological order
  • Merging multiple devices
  
Result: All commands merged by timestamp, deduped
```

---

## Advanced Sync Scenarios

### Scenario 1: Restore Specific Time Range
```bash
# Restore Mac B's commands from last 7 days
chunk-restore --device MAC_B_UUID --since "7 days ago"

Use case: Only get recent commands from another Mac
```

### Scenario 2: Selective Merge
```bash
# Merge only commands after a certain date
chunk-restore --device MAC_B_UUID --merge --since "2026-07-01"

Use case: Don't want very old commands
```

### Scenario 3: Export for Review
```bash
# Export device's history to text file
chunk-export --device MAC_B_UUID > mac-b-history.txt

# Review before merging
wc -l mac-b-history.txt
head -50 mac-b-history.txt

# Then manually import if desired
chunk-import --from mac-b-history.txt
```

### Scenario 4: Deduplicate
```bash
# Remove exact duplicates within a device
chunk-deduplicate

Before: 275,564 commands
After: 265,230 commands (removed 10,334 duplicates) ✓
```

---

## Full Workflow: Three Macs

### Initial State
```
Mac Work:     300,000 commands
Mac Personal: 200,000 commands
Mac Server:   150,000 commands
```

### Step 1: Sync Mac Work
```bash
# Mac Work merges Personal (not Server yet)
chunk-restore --device PERSONAL_UUID --merge --timestamps
# 300K + 200K = 425K unique
chunk-backup.sh
# Pushed
```

### Step 2: Sync Mac Personal
```bash
# Mac Personal pulls Work's merged
git pull
chunk-restore --device WORK_UUID --merge --timestamps
# 200K + 425K = 490K unique
chunk-backup.sh
```

### Step 3: Sync Mac Work Again
```bash
# Mac Work pulls Personal's merged
git pull
chunk-restore --device PERSONAL_UUID --merge --timestamps
# 425K + 490K = 510K unique
chunk-backup.sh
```

### Step 4: Now Sync Mac Server
```bash
# Mac Server pulls everyone's
git pull
chunk-restore --device WORK_UUID --merge --timestamps
# 150K + 510K = 545K unique (approximately)
chunk-backup.sh
```

### Final State
```
Mac Work:     545,000 commands ✓
Mac Personal: 545,000 commands ✓
Mac Server:   545,000 commands ✓

ALL IN SYNC! 🎉
```

---

## Best Practices

### Daily Sync
```bash
# Before work
git pull origin master
chunk-restore --device OTHER_DEVICE --merge --timestamps

# Do your work
(many commands)

# End of day
chunk-backup.sh
(pushes updated history)
```

### Weekly Full Sync
```bash
# Check all devices
chunk-list-devices

# Merge each into one "master" device
for device in DEVICE_LIST; do
    chunk-restore --device $device --merge --timestamps
done

chunk-backup.sh
(now have everything)
```

### Before Important Work
```bash
# Ensure you have full history
git pull origin master
chunk-status
(verify you have latest)

# Merge from another device just in case
chunk-restore --device BACKUP_DEVICE --merge --timestamps
chunk-backup.sh
```

---

## Commands Summary

```bash
# List all devices
chunk-list-devices

# Current status
chunk-status

# Restore (replace)
chunk-restore --device UUID

# Restore (merge)
chunk-restore --device UUID --merge

# Restore (merge with timestamps)
chunk-restore --device UUID --merge --timestamps

# Restore (specific time range)
chunk-restore --device UUID --since "7 days ago"

# Compare devices
chunk-compare UUID1 UUID2

# Export history
chunk-export --device UUID > history.txt

# Import history
chunk-import --from history.txt

# Deduplicate
chunk-deduplicate

# Backup
chunk-backup.sh
```

---

## Safety Features

✅ **Backup before merge** - Previous history saved
✅ **Validation** - Check chunks before restore
✅ **Deduplication** - Remove duplicates automatically
✅ **Timestamps** - Preserve command ordering
✅ **Confirmation** - Ask before replacing
✅ **Rollback** - Can restore from backup
✅ **Logging** - All syncs logged

---

## Next Steps

This requires these new scripts:

✅ **chunk-restore-multi-device.sh** - Device selection + merge
✅ **chunk-sync.sh** - Automated continuous sync
✅ **chunk-list-devices.sh** - List all devices
✅ **chunk-compare.sh** - Compare device histories
✅ **chunk-deduplicate.sh** - Remove duplicates
✅ **chunk-export.sh** - Export history to file
✅ **chunk-import.sh** - Import from file

---

## TL;DR

```
1 Mac:  Each has own history
2 Macs: Can merge/sync histories between them
3+ Macs: Can keep all in sync by merging sequentially

Perfect for keeping work & personal macs in sync! 🎉
```

Would you like me to build the full multi-device sync system?
