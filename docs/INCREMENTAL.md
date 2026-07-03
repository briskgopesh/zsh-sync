# 🚀 Incremental Backup System - Smart Merging

Complete system that only backs up **NEW** commands, protects against corruption, and marks backup boundaries with timestamps.

## 🎯 How It Works

### Backup Flow

```
History File (.zsh_history)
├─ Old Commands (already backed up)
│  └─ [Marked with timestamp]
│     └─ : 1688409600:0;# [CHUNK_BACKUP_MARKER: 2026-07-03T20:09:42Z]
│
└─ NEW Commands (since last backup) ← Only these get backed up!
   └─ command 1
   └─ command 2
   └─ command 3
```

### On Each Backup

```
1. Check last backup timestamp
2. Find marker in ~/.zsh_history
3. Extract ONLY commands after marker
4. Merge with existing chunks from repo
5. Split merged history into chunks
6. Add NEW marker with current timestamp
7. Push to GitHub
```

## ✨ Key Features

✅ **Incremental** - Only new commands since last backup
✅ **Protected** - Detects and recovers from corruption
✅ **Marked** - Knows exactly what was backed up
✅ **Smart Merging** - Never loses old history
✅ **Efficient** - Smaller backups, faster operations

## 🚀 Quick Start

### 1. Replace Your Backup Script

```bash
cp chunk-backup-incremental.sh ~/zsh-chunks/chunk-backup.sh
chmod +x ~/zsh-chunks/chunk-backup.sh
```

### 2. Run First Incremental Backup

```bash
cd ~/zsh-chunks
./chunk-backup.sh
```

**First time output:**
```
▶ Step 1: Checking last backup
First backup - will backup entire history

▶ Step 2: Extracting new commands
New commands: 54321 lines, 114 MB
✓ Extracted new commands

▶ Step 3: Merging with existing chunks
No existing chunks - this is first backup
✓ Prepared for chunking

▶ Step 4: Splitting into chunks
Chunks: 6
Size: 114 MB
✓ Split complete

▶ Step 7: Marking backup point
✓ Added backup marker to ~/.zsh_history

✅ COMPLETE
Type: Incremental Backup
New Commands: 54321
Chunks: 6
Total Size: 114 MB
```

### 3. Second Backup (Shows Incremental)

Run backup again after typing some new commands:

```bash
./chunk-backup.sh
```

**Second time output:**
```
▶ Step 1: Checking last backup
Last backup: 2026-07-03T20:09:42Z
Previous size: 114 MB
Current size: 115 MB

▶ Step 2: Extracting new commands
New commands: 45 lines, 2 KB  ← ONLY new commands!
✓ Extracted new commands

▶ Step 3: Merging with existing chunks
Recovering old history from existing chunks...
New commands: 45 lines, 2 KB
Total merged size: 114 MB
✓ Merged

▶ Step 4: Splitting into chunks
Chunks: 6  (unchanged - still fits in same chunks)
Size: 114 MB
✓ Split complete

▶ Step 7: Marking backup point
✓ Added backup marker to ~/.zsh_history

✅ COMPLETE
Type: Incremental Backup
New Commands: 45
Chunks: 6
Total Size: 114 MB
```

## 🛡️ Corruption Protection

### Scenario: History Gets Smaller

```bash
./chunk-backup.sh

▶ Step 1: Checking last backup
Last backup: 2026-07-03T20:09:42Z
Previous size: 114 MB
Current size: 50 MB  ← Huge drop!

⚠ WARNING: History shrunk by >50%!
This might indicate corruption or accidental deletion.

Restore old history from backup? (y/n): y

▶ Restoring from backup
Restored: 114 MB
✓ Restored from chunks

✅ Continues with incremental backup
```

**What happens:**
1. Script detects history got much smaller
2. Offers to restore from chunks
3. If you accept, restores your full history
4. Then continues with incremental backup
5. Your history is safe! ✅

## 📍 Understanding Markers

### Marker Format

```bash
: 1688409600:0;# [CHUNK_BACKUP_MARKER: 2026-07-03T20:09:42Z]
^ ^ ^            ^ Special marker line
| | |            └─ ISO timestamp of backup
| | └─ 0 (placeholder)
| └─ Unix timestamp
└─ ZSH history format
```

### View Markers in Your History

```bash
grep "CHUNK_BACKUP_MARKER" ~/.zsh_history

Output:
: 1688409600:0;# [CHUNK_BACKUP_MARKER: 2026-07-03T20:09:42Z]
: 1688413200:0;# [CHUNK_BACKUP_MARKER: 2026-07-03T21:00:00Z]
: 1688416800:0;# [CHUNK_BACKUP_MARKER: 2026-07-03T22:00:00Z]
```

### Reading Markers

```
Last marker is the most recent backup
Everything after it is NEW commands
Everything before it was already backed up
```

## 📊 Example Workflow

### Day 1: Initial Backup

```bash
Day 1 - 9:00 AM
$ ./chunk-backup.sh

▶ Step 1: Checking last backup
First backup - will backup entire history

... (backs up everything) ...

✅ COMPLETE
New Commands: 54321
Chunks: 6
Total Size: 114 MB

# Marker added: [CHUNK_BACKUP_MARKER: 2026-07-03T09:00:00Z]
```

### Day 1: More Commands

```bash
Day 1 - 10:00 AM
$ ./chunk-backup.sh

▶ Step 1: Checking last backup
Last backup: 2026-07-03T09:00:00Z
Previous size: 114 MB
Current size: 115 MB

▶ Step 2: Extracting new commands
New commands: 23 lines, 1 KB  ← Only stuff since 9am
✓ Extracted new commands

... (merges new with old) ...

✅ COMPLETE
New Commands: 23
Chunks: 6
Total Size: 115 MB

# Marker updated: [CHUNK_BACKUP_MARKER: 2026-07-03T10:00:00Z]
```

### Day 2: Even More Commands

```bash
Day 2 - 9:00 AM
$ ./chunk-backup.sh

▶ Step 1: Checking last backup
Last backup: 2026-07-03T10:00:00Z
Previous size: 115 MB
Current size: 120 MB

▶ Step 2: Extracting new commands
New commands: 567 lines, 45 KB  ← Commands from yesterday + today
✓ Extracted new commands

... (merges all together) ...

✅ COMPLETE
New Commands: 567
Chunks: 6
Total Size: 120 MB

# Marker updated: [CHUNK_BACKUP_MARKER: 2026-07-04T09:00:00Z]
```

## 🔄 What Gets Backed Up Each Time?

```
Backup 1 (Day 1, 9:00 AM):
└─ ALL history (54,321 commands)
   └─ Creates marker at 9:00 AM

Backup 2 (Day 1, 10:00 AM):
└─ ONLY new commands since 9:00 AM (23 commands)
   └─ Updates marker to 10:00 AM

Backup 3 (Day 2, 9:00 AM):
└─ ONLY new commands since 10:00 AM yesterday (567 commands)
   └─ Updates marker to Day 2, 9:00 AM

Result: All 54,911 commands safely stored! ✅
```

## 💾 Restore Strategy

### No Corruption Needed

```bash
./chunk-restore.sh

# Merges all chunks (which include all historical commands)
# Into your ~/.zsh_history

# Clean restore of everything!
```

### If You Accidentally Deleted History

```bash
./chunk-backup.sh

⚠ WARNING: History shrunk by >50%!
Restore old history from backup? (y/n): y

# Script automatically restores from chunks
# History is safe! ✅
```

## 📈 Performance Benefits

### Before (Full Backup Every Time)

```
Backup 1: 114 MB upload (all commands)
Backup 2: 114 MB upload (all commands)
Backup 3: 114 MB upload (all commands)
─────────────────────────────
Total: 342 MB uploaded
```

### After (Incremental)

```
Backup 1: 114 MB upload (all commands)
Backup 2:   1 MB upload (23 new commands)
Backup 3:  45 KB upload (567 new commands)
─────────────────────────────
Total: 115 MB uploaded  ← 3x less data!
```

## ⚙️ Customization

### Change Corruption Threshold

Edit the script, find:
```bash
if [[ $current_history_size -lt $((last_total_size / 2)) ]]; then
                                        ^^^ Change this
```

Options:
```bash
/ 2    = 50% shrinkage triggers warning
/ 3    = 67% shrinkage triggers warning
/ 10   = 90% shrinkage triggers warning
```

### No Automatic Restore

Remove the restore prompt:
```bash
# Comment out these lines:
# read -p "Restore old history from backup? (y/n): " restore_choice
# if [[ "$restore_choice" == "y" ]]; then
```

## 🔍 Monitoring

### See What Was Backed Up

```bash
# View all markers
grep "CHUNK_BACKUP_MARKER" ~/.zsh_history

# See size history
cat ~/zsh-chunks/logs/*.log | grep "Total Size"

# Check chunk evolution
git log --oneline ~/zsh-chunks/
```

### Track Backup Frequency

```bash
# Count backups per day
grep "CHUNK_BACKUP_MARKER" ~/.zsh_history | wc -l

# Time between backups
grep "CHUNK_BACKUP_MARKER" ~/.zsh_history | tail -2
```

## ✅ Advantages Over Full Backups

| Feature | Full Backup | Incremental |
|---------|-------------|-------------|
| First backup | 114 MB | 114 MB |
| 2nd backup | 114 MB | 1-10 MB |
| 3rd backup | 114 MB | 1-10 MB |
| Network usage | High | Low |
| Corruption recovery | Overwrites | Preserves |
| Lost data risk | Medium | Low |
| Speed | Slower | Faster |
| Storage efficiency | Bad | Good |

---

## 🎯 Summary

This incremental system:
1. **Backs up only NEW commands** - Efficient
2. **Marks backup boundaries** - Knows what's backed up
3. **Protects against corruption** - Auto-recovery
4. **Merges intelligently** - Never loses history
5. **Saves bandwidth** - Much less data uploaded

**Your history is now both efficient AND safe!** 🚀
