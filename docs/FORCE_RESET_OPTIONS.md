# 🚀 Backup Force & Reset Options

Take full control of your backup with `--force` and `--reset` flags!

## Three Modes

```bash
./chunk-backup.sh              # Normal mode (ask for confirmation)
./chunk-backup.sh --force      # Force mode (skip checks, backup as-is)
./chunk-backup.sh --reset      # Reset mode (clean old, start fresh)
```

## Your Situation

```
Current state:
  Previous backup:  826,670 commands, 88 MB (false/corrupted)
  Current history:  275,564 commands, 29 MB (correct)

Problem: Old backup is wrong, new is correct
Solution: Use --reset to overwrite with fresh 29 MB backup
```

## Mode 1: Normal (Default)

```bash
./chunk-backup.sh
```

**Behavior:**
```
Command Statistics:
  Previous backup:   826,670 commands, 88 MB
  Current history:   275,564 commands, 29 MB
  Command change:   -66%

⚠ Lost 551,106 commands (66% decrease)!
...
Restore old history from backup? (y/n):
```

- Shows warning if history shrunk
- Asks for confirmation
- Conservative approach
- **Use for:** Normal daily backups

## Mode 2: Force (--force)

```bash
./chunk-backup.sh --force
```

**Behavior:**
```
Command Statistics:
  Previous backup:   826,670 commands, 88 MB
  Current history:   275,564 commands, 29 MB
  Command change:   -66%

⚠ Lost 551,106 commands (66% decrease) - FORCING BACKUP ANYWAY
```

- Shows warning
- **Skips confirmation** ✓
- Backs up current state as-is
- Does NOT restore old
- Updates remote with 29 MB backup
- **Use for:** When you know the old backup is wrong

## Mode 3: Reset (--reset)

```bash
./chunk-backup.sh --reset
```

**Behavior:**
```
RESET MODE: Cleaning old backup

This will:
  • Delete old chunks
  • Reset config.json to empty
  • Clear backup markers from history
  • Start completely fresh

Are you absolutely sure? (type 'YES' to confirm): YES

✓ Chunks cleaned
✓ Config reset
✓ Markers removed from history
Ready for fresh backup

▶ Step 2: Extracting new commands
New commands:   275,564 commands

✓ Complete
Mode: RESET (fresh start)
New Commands:   275,564
Total Commands:  275,564
Chunks: 2
Total Size: 29 MB
```

- **Deletes everything** ✓
- Starts completely fresh
- Uses current history as baseline
- Force pushes to GitHub (overwrites remote)
- **Use for:** Resetting corrupted/wrong backups

---

## Decision Tree

```
Do I want to keep old backup?
├─ YES, restore it → ./chunk-backup.sh (normal, restore option)
├─ NO, but keep history small → ./chunk-backup.sh --force
└─ NO, completely reset → ./chunk-backup.sh --reset
```

## Your Case: Step-by-Step

### Current Problem
```bash
Old backup: 88 MB (wrong, 826K commands)
Current:    29 MB (correct, 275K commands)
```

### Solution: Use --reset

```bash
cd ~/zsh-chunks

# This will:
# 1. Delete old 88 MB chunks
# 2. Start fresh with 29 MB
# 3. Push to GitHub (overwrite)
./chunk-backup.sh --reset

# When prompted:
Are you absolutely sure? (type 'YES' to confirm): YES

# Then:
✓ Chunks cleaned
✓ Config reset
✓ Markers removed from history
Ready for fresh backup

... (backs up new 29 MB) ...

✅ COMPLETE
Mode: RESET (fresh start)
Total Size: 29 MB
```

### Result
```bash
# Remote updated with fresh 29 MB backup
# Old 88 MB backup gone
# Start completely fresh ✓

# Check status
chunk-status

ZSH Chunk Backup Status:
  Chunks: 2
  Size: 29 MB
  Last: 2026-07-04T14:30:00Z
```

---

## What Each Mode Does

### Normal Mode
```
├─ Read last backup info
├─ Compare current vs last
├─ Warn if >20% loss
├─ Ask user for confirmation
├─ Back up selected state
├─ Push to GitHub
└─ Done
```

### Force Mode
```
├─ Read last backup info
├─ Compare current vs last
├─ Warn if >20% loss
├─ Skip confirmation (--force)
├─ Back up current state anyway
├─ Push to GitHub
└─ Done
```

### Reset Mode
```
├─ Confirm reset (type 'YES')
├─ Delete all chunks
├─ Clear config.json
├─ Remove history markers
├─ Back up entire current history
├─ Force push to GitHub (overwrite)
└─ Done - completely fresh!
```

---

## Important Notes

### Force Mode (--force)
- Still shows warnings
- Skips user confirmation
- **Does NOT** restore old backup
- **Safe** - just bypasses prompt

### Reset Mode (--reset)
- **Requires explicit confirmation** (type 'YES')
- Deletes old chunks (keeps backup)
- Overwrites remote (force push)
- **Start completely fresh**
- Careful with this!

---

## Installation

```bash
cd ~/zsh-chunks
cp ../chunk-backup-incremental-v3-force.sh chunk-backup.sh

# Test it
./chunk-backup.sh --help

# Use it
./chunk-backup.sh --reset
```

## Help

```bash
./chunk-backup.sh --help

Usage: ./chunk-backup.sh [OPTIONS]

Options:
  (no args)    Normal incremental backup with confirmation
  --force      Skip corruption check, backup current history as-is
  --reset      Clean old backup, start completely fresh

Examples:
  ./chunk-backup.sh                # Normal backup
  ./chunk-backup.sh --force        # Force backup without prompts
  ./chunk-backup.sh --reset        # Reset everything, start fresh
```

---

## Example Workflow

### Situation: Old Backup Wrong, Want Fresh Start

```bash
# Check current state
du -sh ~/.zsh_history
# 29M

# Check old backup
chunk-status
# Size: 88 MB (wrong!)

# Reset to fresh 29 MB
./chunk-backup.sh --reset
# Type: YES
# ... backs up 29 MB ...

# Verify
chunk-status
# Size: 29 MB ✓

# GitHub updated with new 29 MB backup ✓
```

---

## Safety Features

✅ Reset requires explicit confirmation (type 'YES')
✅ Old chunks kept as backup: `chunks.backup.20260704_143000`
✅ Force push only happens with --reset
✅ All operations logged in logs/
✅ Each backup has timestamp marker

---

## Your Fix

For your 88MB → 29MB situation:

```bash
cd ~/zsh-chunks
./chunk-backup.sh --reset

Type: YES

# Done!
# Fresh 29 MB backup pushed to GitHub
```

**Perfect!** 🎉
