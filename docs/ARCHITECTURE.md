# 🏗️ Architecture & Technical Design

## System Overview

zsh-sync is a **chunked, incremental backup system** with multi-device support.

```
┌─────────────────────────────────────────────────────────────┐
│                     ~/.zsh_history (29 MB)                  │
│                   (275,585 commands)                        │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
                  ┌──────────────────────┐
                  │  chunk-backup.sh     │
                  │  (Incremental)       │
                  └──────────┬───────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
    ┌─────────┐         ┌─────────┐        ┌──────────┐
    │Extract  │         │ Sync    │        │ Merge    │
    │New Cmds │         │Devices  │        │Chunks    │
    └────┬────┘         └────┬────┘        └────┬─────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             ▼
                  ┌──────────────────────┐
                  │ Split into 20MB      │
                  │ Chunks               │
                  └──────────┬───────────┘
                             │
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
    ┌─────────┐         ┌─────────┐        ┌──────────┐
    │SHA256   │         │Update   │        │Git       │
    │Hash     │         │Config   │        │Commit    │
    └────┬────┘         └────┬────┘        └────┬─────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             ▼
                  ┌──────────────────────┐
                  │ Git Push to GitHub   │
                  │ (Backup Complete)    │
                  └──────────────────────┘
```

---

## Directory Structure

```
~/zsh-sync/
│
├── config.json                 # Device metadata & chunk manifest
│
├── chunks/                     # Backup storage
│   ├── DEVICE_UUID_1/         # Device 1's chunks
│   │   ├── chunk_aa           # 20 MB chunk
│   │   ├── chunk_ab           # 14 MB chunk
│   │   └── chunk_ac           # (if needed)
│   │
│   ├── DEVICE_UUID_2/         # Device 2's chunks
│   │   ├── chunk_aa
│   │   └── chunk_ab
│   │
│   └── DEVICE_UUID_1.backup.20260704_120000/  # Previous backup
│       ├── chunk_aa
│       └── chunk_ab
│
├── logs/                       # Backup operation logs
│   ├── backup-20260704_100000.log
│   └── backup-20260704_110000.log
│
└── .git/                       # Version control
```

---

## Data Flow

### Phase 1: Extraction

```
Step 1: Read ~/.zsh_history
  │
  ├─ Find last backup marker (CHUNK_BACKUP_MARKER)
  │
  └─ Extract only NEW commands since marker
     └─ Output: new_commands.txt
```

**Marker Format:**
```
: 1688409600:0;# [CHUNK_BACKUP_MARKER: 2026-07-04T15:30:00Z]
```

### Phase 2: Multi-Device Sync (if SYNCALL mode)

```
Step 2: Auto-sync from other devices
  │
  ├─ List all devices in config.json
  │
  ├─ For each device:
  │   ├─ Read: chunks/OTHER_UUID/chunk_*
  │   ├─ Append to history
  │   └─ Deduplicate (sort -u)
  │
  └─ Output: Updated ~/.zsh_history
```

### Phase 3: Merge

```
Step 3: Merge old + new
  │
  ├─ Read existing chunks (if any)
  │   ├─ chunks/DEVICE_UUID/chunk_aa
  │   └─ chunks/DEVICE_UUID/chunk_ab
  │
  ├─ Append new commands
  │
  └─ Output: merged_history.txt
```

### Phase 4: Chunking

```
Step 4: Split into 20MB chunks
  │
  ├─ Total size: 29 MB
  ├─ Chunk size: 20 MB
  │
  ├─ split -b 20971520 merged_file chunks/chunk_
  │
  └─ Output:
     ├─ chunk_aa (20 MB)
     ├─ chunk_ab (9 MB)
     └─ chunk_ac (if needed)
```

### Phase 5: Validation

```
Step 5: Hash validation
  │
  ├─ For each chunk:
  │   ├─ Calculate: shasum -a 256 chunk_aa
  │   ├─ Compare: with config.json hash
  │   └─ Verify: match ✓ or fail ✗
  │
  └─ Continue only if all match
```

### Phase 6: Configuration Update

```
Step 6: Update config.json
  │
  ├─ Add device entry:
  │   ├─ laptop_id: UUID
  │   ├─ hostname: device name
  │   ├─ sync_mode: SYNCALL/NOSYNC
  │   └─ chunks: {...}
  │
  ├─ Update chunk metadata:
  │   ├─ timestamp: 2026-07-04T15:30:00Z
  │   ├─ count: 2
  │   ├─ total_size: 29000000
  │   ├─ command_count: 275585
  │   └─ parts: [{index, name, hash, size}]
  │
  └─ Output: config.json (updated)
```

### Phase 7: Backup Marker

```
Step 7: Mark backup boundary
  │
  ├─ Add marker to ~/.zsh_history:
  │   └─ `: 1688409600:0;# [CHUNK_BACKUP_MARKER: 2026-07-04T15:30:00Z]`
  │
  └─ Next backup will only grab commands after this marker
```

### Phase 8: Git Operations

```
Step 8: Commit & Push
  │
  ├─ git add chunks/ config.json
  │
  ├─ git commit -m "Backup - 2026-07-04 15:30:00 (mode: SYNCALL)"
  │
  └─ git push origin main
```

---

## config.json Structure

```json
{
  "DEVICE_UUID_1": {
    "laptop_id": "C1A873F7-E8F2-5512-9457-44841C008C2B",
    "hostname": "work-mac",
    "created": "2026-07-04T10:00:00Z",
    "sync_mode": "SYNCALL",
    "chunks": {
      "timestamp": "2026-07-04T15:30:00Z",
      "count": 2,
      "total_size": 29000000,
      "command_count": 275585,
      "parts": [
        {
          "index": 0,
          "name": "chunk_aa",
          "hash": "a1b2c3d4e5f6...",
          "size": 20971520
        },
        {
          "index": 1,
          "name": "chunk_ab",
          "hash": "f6e5d4c3b2a1...",
          "size": 8028480
        }
      ]
    }
  }
}
```

---

## Incremental Backup Algorithm

### On First Backup

```
Input:  ~/.zsh_history (29 MB, 275K commands)
        No previous marker
Process:
  1. Copy entire history
  2. Split into chunks (2 × 20MB)
  3. Calculate hashes
  4. Create config.json entry
  5. Add marker to history
  6. Commit & push
Output: chunks/DEVICE_UUID/ with 2 chunks
```

### On Subsequent Backups

```
Input:  ~/.zsh_history (29.5 MB, 275.6K commands)
        Previous marker found at: 2026-07-04T15:30:00Z
Process:
  1. Extract only commands AFTER marker (~100 new)
  2. Read old chunks from disk
  3. Append new to old
  4. Re-split if needed
  5. Update hashes
  6. Update config.json
  7. Add new marker
  8. Commit & push
Output: chunks/DEVICE_UUID/ with updated chunks
Efficiency: Only 100 commands re-processed, not 275K
```

---

## Multi-Device Sync

### SYNCALL Mode

```
Device A (SYNCALL):
  On Backup:
    1. Extract new commands from ~/.zsh_history
    2. List all devices in config.json
    3. For each OTHER device:
       ├─ Read: chunks/OTHER_UUID/chunk_*
       ├─ Append to local history
       └─ Deduplicate
    4. Merge with old chunks
    5. Split & backup
    6. Commit & push
  
  Result: Device A has all commands from all devices!
```

### NOSYNC Mode

```
Device B (NOSYNC):
  On Backup:
    1. Extract new commands from ~/.zsh_history
    2. Skip: Don't pull from other devices
    3. Merge with own old chunks only
    4. Split & backup
    5. Commit & push
  
  Result: Device B stays isolated but still backs up
          Other SYNCALL devices can pull from B
```

### Concurrent Backups

```
Timeline:
  10:00:00 Device A starts
           └─ Creates temp file, reads chunks
  
  10:00:05 Device B starts (no conflict!)
           └─ Creates different temp file
  
  10:00:10 Device A writes chunks/A_UUID/
           └─ Updates config.json (Device A section)
  
  10:00:15 Device B writes chunks/B_UUID/
           └─ Updates config.json (Device B section)
  
  10:00:16 Device A: git add, commit, push
  10:00:17 Device B: git add, commit, push
  
  Result: Both succeed! No conflicts!
          Different directories = safe concurrent access
```

---

## Hash Validation

### SHA256 Verification

```
Process:
  1. After chunking, calculate: shasum -a 256 chunk_aa
  2. Store hash in config.json
  3. On restore/verification:
     ├─ Read chunk file
     ├─ Calculate hash again
     └─ Compare: Expected vs Actual

Result:
  ✓ Match   = Chunk is intact, safe to use
  ✗ Mismatch = Chunk corrupted, restore from backup
```

### Corruption Detection

```
Primary Method: Command Count
  - Store: command_count in config.json
  - On backup: Count current commands
  - Loss >20% = Alert user
  - Action: Offer restore from backup

Why Command Count?
  - More reliable than file size
  - File size ambiguous (compression, rotation)
  - Commands are ground truth
  - Lost 57K commands = You know exactly
```

---

## Git Integration

### Commit Structure

```
Commit Message:
  Backup - 2026-07-04 15:30:00 (mode: SYNCALL)

What's Tracked:
  ✓ chunks/          (all chunk files)
  ✓ config.json      (metadata)
  ✗ logs/            (ignored, local only)
  ✗ ~/.zsh_history   (ignored, local only)

History:
  git log --oneline
  a1b2c3d Backup - 2026-07-04 15:30:00 (mode: SYNCALL)
  e5f6g7h Backup - 2026-07-03 14:20:00 (mode: SYNCALL)
  i9j0k1l Backup - 2026-07-02 10:15:00 (mode: SYNCALL)
```

### Rollback Strategy

```
To Restore Old Backup:
  1. git log --oneline
  2. git checkout COMMIT_HASH -- chunks/
  3. cat chunks/DEVICE_UUID/chunk_* > ~/.zsh_history
  4. exec zsh
```

---

## Performance Characteristics

### Time Complexity

```
Fresh Backup (29 MB):
  - Read history:     1s
  - Hash chunks:      2s
  - Git ops:          2s
  Total:              ~5s

Incremental (100 cmds):
  - Read history:     <1s
  - Merge chunks:     <1s
  - Hash:             <1s
  - Git ops:          1s
  Total:              ~2-3s

SYNCALL Merge (3 devices, 900K cmds total):
  - Read histories:   2s
  - Sort/dedup:       3s
  - Hash:             2s
  - Git ops:          2s
  Total:              ~9s
```

### Space Complexity

```
Single Device:
  Active chunks:      ~30 MB
  Backup copies:      ~30-60 MB (2 kept)
  Total:              ~60-90 MB

Two Devices:
  Device 1:           ~30 MB
  Device 2:           ~30 MB
  Old backups:        ~60 MB
  Total:              ~120 MB

Storage Efficient:
  - Only keep 2 old backups (configurable)
  - Auto-cleanup removes excess
  - GitHub free tier: 100 GB available
```

---

## Reliability & Safety

### Backup Strategy

```
Levels of Protection:

1. Local Chunks:
   └─ chunks/DEVICE_UUID/chunk_aa
   └─ chunks/DEVICE_UUID/chunk_ab
   
2. Previous Backup:
   └─ chunks/DEVICE_UUID.backup.20260704_120000/
   
3. Git History:
   └─ Can recover from any previous commit
   
4. GitHub:
   └─ Remote backup of all chunks + git history
```

### Recovery Options

```
If ~/.zsh_history Corrupted:

Option 1 - Restore from chunks:
  cat chunks/DEVICE_UUID/chunk_* > ~/.zsh_history

Option 2 - Restore from old backup:
  cat chunks/DEVICE_UUID.backup.*/chunk_* > ~/.zsh_history

Option 3 - Restore from git:
  git checkout COMMIT_HASH -- chunks/
  cat chunks/DEVICE_UUID/chunk_* > ~/.zsh_history

Option 4 - Restore from GitHub:
  git pull origin main
  cat chunks/DEVICE_UUID/chunk_* > ~/.zsh_history
```

---

## Security Considerations

### Data Privacy

```
What's Backed Up:
  ✓ All ZSH commands (including paths, options)
  ✓ Exact command syntax
  ⚠️ May include: passwords, API keys if typed

Recommendations:
  1. Keep repo PRIVATE on GitHub
  2. Don't type sensitive data in shell
  3. Use environment variables for credentials
  4. Review history: grep -v "^:" ~/.zsh_history
```

### Access Control

```
Local:
  - Permissions: Read only by current user
  - chmod: 600 on config.json (recommended)
  
Remote (GitHub):
  - Private repo: Only you can access
  - SSH key: Authenticate securely
  - No passwords in URLs
```

---

## Design Decisions

### Why Chunking?

```
Problem: 29 MB history file doesn't compress well with git
Solution: Split into 20 MB chunks
Benefits:
  - Better with git (VCS handles binary better)
  - Easier to verify (hash each chunk)
  - Parallel processing possible
  - Recovery granularity
```

### Why SHA256?

```
Alternatives Considered:
  - MD5: Outdated, collisions found
  - SHA1: Weak, being deprecated
  - SHA256: Current standard, secure

Choice: SHA256
  - Industry standard
  - Collision-resistant
  - Available in all tools
```

### Why Markers?

```
Alternative: Always backup entire history
Problem: Inefficient, slow, large commits

Solution: Backup markers
  - Track backup boundaries
  - Only grab new since last marker
  - Fast incremental backups
  - Efficient git history
```

### Why Device UUID?

```
Alternative: Use hostname
Problem: Hostnames can change, duplicate

Solution: Hardware UUID
  - Immutable (tied to Mac hardware)
  - Unique across all devices
  - Can't conflict even if renamed
  - Survives OS reinstall
```

---

## Future Architecture Enhancements

### Planned Features

1. **Encryption**
   ```
   Add GPG/AES encryption layer
   Before: chunks/chunk_aa (plain)
   After:  chunks/chunk_aa.enc (encrypted)
   ```

2. **Compression**
   ```
   Add optional gzip compression
   Before: 29 MB chunks
   After:  ~8 MB (70% reduction)
   Trade: CPU for storage
   ```

3. **Deduplication**
   ```
   Cross-device command dedup
   Before: Same command in A & B (200 KB × 2)
   After:  Stored once, referenced (200 KB)
   ```

4. **Web API**
   ```
   REST API for management
   - List backups
   - View statistics
   - Restore operations
   - Cross-device search
   ```

---

**Architecture designed for reliability, efficiency, and multi-device support.** 🏗️
