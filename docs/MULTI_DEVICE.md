# 🚀 Multi-Device Backup System

Support multiple laptops safely with isolated chunks per device!

## Current Problem

```
Laptop A backup:
  chunks/chunk_aa
  chunks/chunk_ab
  └─ Pushed to GitHub

Laptop B backup (same time):
  chunks/chunk_aa  ← OVERWRITES Laptop A's!
  chunks/chunk_ab  ← CORRUPTS Laptop B's!
  └─ Git conflict!

Result: BOTH BROKEN! ❌
```

## Solution: Device-Separated Chunks

```
chunks/
├── LAPTOP_A_UUID/
│   ├── chunk_aa
│   ├── chunk_ab
│   └── config-snapshot.json
│
└── LAPTOP_B_UUID/
    ├── chunk_aa
    ├── chunk_ab
    └── config-snapshot.json

config.json (tracks all laptops):
{
  "LAPTOP_A_UUID": {...},
  "LAPTOP_B_UUID": {...}
}
```

## Multi-Device Setup

### Step 1: On First Laptop (Laptop A)

```bash
# Setup
./setup-fresh-chunks.sh
# → Creates: chunks/C1A873F7-.../

# Backup
./chunk-backup.sh
# → Pushes to GitHub

# Status
chunk-status
# Laptop: C1A873F7-...
# Size: 29 MB
```

### Step 2: On Second Laptop (Laptop B)

```bash
# Clone existing repo (important!)
git clone git@github.com:user/zsh-chunks.git
cd zsh-chunks

# Copy scripts
cp ../chunk-backup-multi-device.sh chunk-backup.sh

# First backup on Laptop B
./chunk-backup.sh

# → Detects: NEW laptop (different UUID)
# → Creates: chunks/E2B984G8-.../ (Laptop B's directory)
# → No conflict with Laptop A!
# → Pushes to GitHub
```

### Result: Organized Repository

```
GitHub:
└── zsh-chunks/
    ├── config.json (tracks both laptops)
    ├── chunks/
    │   ├── C1A873F7-.../ (Laptop A)
    │   │   ├── chunk_aa
    │   │   ├── chunk_ab
    │   │   └── ...
    │   └── E2B984G8-.../ (Laptop B)
    │       ├── chunk_aa
    │       ├── chunk_ab
    │       └── ...
    └── logs/
        ├── backup-laptop-a-*.log
        └── backup-laptop-b-*.log
```

## Safety Features

✅ **Isolated chunks** - Each laptop has own directory
✅ **Concurrent backups** - Both can backup simultaneously
✅ **No conflicts** - Git won't clash
✅ **Shared config** - config.json tracks all
✅ **Easy restore** - Know which chunks are which
✅ **Clear logs** - See which laptop did what

## config.json Structure

```json
{
  "C1A873F7-E8F2-5512-9457-44841C008C2B": {
    "laptop_id": "C1A873F7-...",
    "prefix": "VL",
    "hostname": "gopeshchaudhary-mac",
    "created": "2026-07-04T10:00:00Z",
    "chunks": {
      "timestamp": "2026-07-04T14:30:00Z",
      "count": 2,
      "total_size": 29000000,
      "command_count": 275564,
      "chunk_dir": "chunks/C1A873F7-...",
      "parts": [...]
    }
  },
  "E2B984G8-F1A3-5612-9568-55942D119C3D": {
    "laptop_id": "E2B984G8-...",
    "prefix": "VL",
    "hostname": "personal-mbp",
    "created": "2026-07-04T15:00:00Z",
    "chunks": {
      "timestamp": "2026-07-04T15:30:00Z",
      "count": 3,
      "total_size": 50000000,
      "command_count": 450000,
      "chunk_dir": "chunks/E2B984G8-...",
      "parts": [...]
    }
  }
}
```

## Scenario: Concurrent Backups

### Timeline

```
Laptop A                          Laptop B
├─ 10:00:00 Start backup
│  └─ Create: chunks/C1A873F.../
│
├─ 10:00:05 Laptop B starts backup
│           └─ Create: chunks/E2B984G8.../
│              (Different dir, no conflict!)
│
├─ 10:00:10 Laptop A pushes
│  ├─ chunks/C1A873F.../chunk_aa ✓
│  ├─ chunks/C1A873F.../chunk_ab ✓
│  └─ config.json (updated)
│
├─ 10:00:15 Laptop B pushes
│  ├─ chunks/E2B984G8.../chunk_aa ✓
│  ├─ chunks/E2B984G8.../chunk_ab ✓
│  ├─ chunks/E2B984G8.../chunk_ac ✓
│  └─ config.json (merged, no conflict!)
│
└─ ✅ Both complete successfully!
```

**No conflicts!** Each laptop writes to its own directory.

## Laptop Status Command

```bash
# On Laptop A
chunk-status

ZSH Chunk Backup Status:
  Laptop: C1A873F7-...
  Hostname: gopeshchaudhary-mac
  Chunks: 2
  Size: 29 MB
  Commands: 275,564
  Last: 2026-07-04T14:30:00Z

# On Laptop B
chunk-status

ZSH Chunk Backup Status:
  Laptop: E2B984G8-...
  Hostname: personal-mbp
  Chunks: 3
  Size: 50 MB
  Commands: 450,000
  Last: 2026-07-04T15:30:00Z
```

## Sync Across Devices

Want to copy history from Laptop A to Laptop B?

```bash
# On Laptop B
git pull origin master

# See all devices
chunk-list-all

Devices in backup:
1. C1A873F7-... (gopeshchaudhary-mac)
   Size: 29 MB | Commands: 275,564 | Last: 2026-07-04T14:30:00Z

2. E2B984G8-... (personal-mbp)
   Size: 50 MB | Commands: 450,000 | Last: 2026-07-04T15:30:00Z

# Restore from Laptop A on Laptop B
chunk-restore --device C1A873F7-...

# Result: Laptop B's history becomes Laptop A's history
# (or merge them)
```

## Git Repository Growth

```
1 Laptop:  29 MB
2 Laptops: 29 + 50 = 79 MB
3 Laptops: 29 + 50 + 40 = 119 MB

Each laptop: ~30-50 MB depending on history size
Linear growth, no conflicts ✓
```

## Backup Commands (Multi-Device)

```bash
# Backup current laptop
./chunk-backup.sh

# Backup with force
./chunk-backup.sh --force

# Reset current laptop only
./chunk-backup.sh --reset

# List all backed-up devices
chunk-list-all

# Restore from specific device
chunk-restore --device DEVICE_UUID

# Restore and merge from another device
chunk-restore --device DEVICE_UUID --merge

# Compare histories between devices
chunk-compare DEVICE_A DEVICE_B

# Sync all devices
chunk-sync-all
```

## Setup on Multiple Devices

### Device 1: Initial Setup

```bash
# Create repo
./setup-fresh-chunks.sh
# → Repo created with Device 1's UUID

# First backup
./chunk-backup.sh
# → Pushes Device 1's chunks

# Push to GitHub
git push -u origin master
```

### Device 2: Join Existing Repo

```bash
# Clone existing repo
git clone git@github.com:user/zsh-chunks.git
cd zsh-chunks

# Copy scripts
cp ../chunk-backup-multi-device.sh chunk-backup.sh

# First backup on Device 2
./chunk-backup.sh
# → Detects: New device (different UUID)
# → Creates: chunks/DEVICE_2_UUID/
# → No conflict!
# → Pushes updates

# Now repo has both devices
```

### Device 3: Join Later

```bash
# Same as Device 2
git clone ...
cp scripts...
./chunk-backup.sh
# → Adds Device 3, no conflicts
```

## Advantages

✅ **Safe concurrent backups** - Multiple devices simultaneously
✅ **No git conflicts** - Separate chunk directories
✅ **Shared repository** - Single GitHub repo for all devices
✅ **Easy restore** - Know which chunks from which device
✅ **Organized** - Clear device separation
✅ **Scalable** - Add devices anytime
✅ **Flexible** - Sync between devices optional

## Device Management

```bash
# List all devices
chunk-list-all

# Check device status
chunk-status --device DEVICE_UUID

# Remove old device backup
chunk-remove --device OLD_DEVICE_UUID

# Export device history
chunk-export --device DEVICE_UUID > history.txt

# Import to another device
chunk-import --from history.txt
```

---

## Next Steps

This requires a new script version: **chunk-backup-multi-device.sh**

Features:
- Auto-detect laptop UUID
- Separate chunks per device
- config.json tracks all devices
- Concurrent backup safety
- Device management commands
- Cross-device restore
- Merge histories option

Would you like me to create this multi-device version?

---

## TL;DR

**Current:** All devices → chunks/ → Conflicts ❌
**Multi-Device:** Each device → chunks/DEVICE_UUID/ → Safe ✅

Perfect for syncing ZSH history across multiple Macs!
