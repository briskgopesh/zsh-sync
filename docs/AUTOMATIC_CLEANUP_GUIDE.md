# 🧹 Automatic Backup Cleanup

Smart cleanup that keeps only recent backups and removes old ones!

## Problem Solved

```
Before:
chunks.backup.20260701_100000
chunks.backup.20260701_120000
chunks.backup.20260701_140000
chunks.backup.20260701_160000
chunks.backup.20260702_080000
chunks.backup.20260702_100000
... (keeps accumulating!)

After (with cleanup):
chunks.backup.20260702_100000  ✓ Keep
chunks.backup.20260703_080000  ✓ Keep
(Old ones deleted automatically!)
```

## New Feature: Auto-Cleanup

Now **every backup automatically cleans up old backup folders**!

## What Gets Cleaned

### Backup Folders
```
chunks.backup.20260701_100000  → Deleted if >2 recent
chunks.backup.20260701_120000  → Deleted if >2 recent
chunks.backup.20260702_100000  ✓ Keep (recent)
chunks.backup.20260703_080000  ✓ Keep (most recent)
```

### Log Files
```
logs/backup-20260701_100000.log  → Deleted if >4 recent
logs/backup-20260701_120000.log  → Deleted if >4 recent
logs/backup-20260702_100000.log  ✓ Keep
logs/backup-20260703_080000.log  ✓ Keep
logs/backup-20260704_090000.log  ✓ Keep
logs/backup-20260704_100000.log  ✓ Keep
```

**Rule: Keep 2 recent backup folders + 4 recent log files**

## How It Works

### Automatic (After Each Backup)
```bash
./chunk-backup.sh

... (backs up) ...

▶ Step 10: Cleaning up old backups
Found 5 backup folders
Keeping: 2 most recent

  ✓ Keep: chunks.backup.20260704_100000 (45MB)
  ✓ Keep: chunks.backup.20260703_080000 (45MB)
  ✗ Delete: chunks.backup.20260702_100000 (45MB)
  ✗ Delete: chunks.backup.20260701_140000 (45MB)
  ✗ Delete: chunks.backup.20260701_080000 (45MB)

Cleanup complete

✅ COMPLETE
```

**Done!** Old backups automatically removed.

### Manual Cleanup
```bash
./chunk-backup.sh --cleanup
```

Run this anytime to clean up without backing up.

## Why This Matters

### Disk Space Saved
```
5 backup folders × 45 MB = 225 MB wasted
With cleanup: Keep 2 = 90 MB
Saves: 135 MB ✓
```

### Git Repository
```
Before: Large repo with many old backup folders
After: Clean, minimal repo with only recent backups
```

## Configuration

Edit script to change how many to keep:

```bash
# Default: Keep 2 recent backup folders
KEEP_BACKUPS=2

# To keep 5 most recent:
KEEP_BACKUPS=5

# To keep only 1:
KEEP_BACKUPS=1
```

Log cleanup uses: `KEEP_BACKUPS * 2`
- 2 backup folders → Keep 4 logs
- 5 backup folders → Keep 10 logs
- 1 backup folder → Keep 2 logs

## All Commands

```bash
# Normal backup (auto-cleanup at end)
./chunk-backup.sh

# Force backup (auto-cleanup at end)
./chunk-backup.sh --force

# Reset backup (auto-cleanup at end)
./chunk-backup.sh --reset

# Manual cleanup only (no backup)
./chunk-backup.sh --cleanup

# Help
./chunk-backup.sh --help
```

## Example: Your Workflow

### Week 1: Many Backups
```
Day 1: ./chunk-backup.sh
       chunks.backup.20260701_100000 created ✓
       
Day 2: ./chunk-backup.sh
       chunks.backup.20260702_100000 created ✓
       
Day 3: ./chunk-backup.sh
       chunks.backup.20260703_100000 created ✓
       
Day 4: ./chunk-backup.sh
       chunks.backup.20260704_100000 created ✓
       
Day 5: ./chunk-backup.sh
       chunks.backup.20260705_100000 created ✓
       
       ▶ Cleanup triggered!
       ✓ Keep: chunks.backup.20260705_100000
       ✓ Keep: chunks.backup.20260704_100000
       ✗ Delete: chunks.backup.20260703_100000
       ✗ Delete: chunks.backup.20260702_100000
       ✗ Delete: chunks.backup.20260701_100000
```

After cleanup:
```bash
ls -la chunks.backup.*

chunks.backup.20260705_100000  45 MB ✓
chunks.backup.20260704_100000  45 MB ✓
(Only 2 kept, 3 deleted!)
```

## Safe to Delete?

**YES!** Backup folders are safe to delete because:

✓ Chunks are already in active `chunks/` directory
✓ Chunks are already pushed to GitHub
✓ Backup folders are only local recovery copies
✓ If backup succeeds, you don't need the old copy

The backup folder is just insurance while the backup is happening. Once it's done and pushed, you don't need it.

## When to Keep More

### Keep 5 Recent Backups
```bash
# Edit the script
KEEP_BACKUPS=5

# Or run manual cleanup
./chunk-backup.sh --cleanup
```

**Use case:** Want more history of backups for recovery.

## When to Keep Fewer

### Keep Only 1 Backup
```bash
# Edit the script
KEEP_BACKUPS=1
```

**Use case:** Disk space critical, trust GitHub as primary backup.

## Safety Features

✅ Keeps at least 2 recent backups by default
✅ Only deletes if >KEEP_BACKUPS exist
✅ Never deletes active chunks/ directory
✅ Never deletes config.json or other files
✅ Only cleans .backup. folders and .log files
✅ Automatic after successful backup
✅ Manual cleanup available anytime

## Installation

```bash
cd ~/zsh-chunks
cp ../chunk-backup-incremental-final.sh chunk-backup.sh

# Works exactly like before, but now with cleanup!
./chunk-backup.sh
```

## Monitoring

### Check Current Backups
```bash
ls -lah chunks.backup.*
```

### Check Logs
```bash
ls -lah logs/
```

### See Cleanup in Action
```bash
./chunk-backup.sh

... (backup runs) ...

▶ Step 10: Cleaning up old backups
Found X backup folders
Keeping: 2 most recent
  ✓ Keep: ...
  ✗ Delete: ...
✓ Cleanup complete
```

---

## Summary

**Before:** Backup folders accumulate forever ❌
**After:** Only keep 2 recent, auto-delete old ones ✅

**Benefits:**
- ✅ Saves disk space (100+ MB)
- ✅ Cleaner repository
- ✅ Automatic (no manual cleanup)
- ✅ Still safe (GitHub has full history)
- ✅ Fast backups (less to manage)

**Perfect for production!** 🎉
