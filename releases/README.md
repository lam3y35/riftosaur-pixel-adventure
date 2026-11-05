# Riftosaur Releases & Build Artifacts

This directory stores locally generated build artifacts (Android APKs, packages, checksums).

> **Note:** Binary APK files are excluded from git tracking via `.gitignore`. Checksums and verification logs are recorded in this file and in `docs/WORKLOG.md`.

---

## Naming Conventions

- **Debug Builds:** `Riftosaur-debug-<version>.apk` or `Riftosaur-debug.apk`
- **Release Builds:** `Riftosaur-release-<version>.apk`
- **Checksums:** `SHA256SUMS.txt`

---

## Builds Register

| File | Target | Version Code | Version Name | Size | SHA-256 Checksum | Evidence Level |
|---|---|---|---|---|---|---|
| `Riftosaur-debug.apk` | Android (arm64-v8a, x86_64) | 1 | 0.3.0 | 62,273,025 bytes (59.39 MB) | `EA8F74C26D008FFD5E3B9C0DB642F8A16D82956AE7BD581483F29231B3273223` | L4 Static APK Verification |

---

## Verification Commands

To verify an APK locally on Windows:
```powershell
# Calculate SHA-256
Get-FileHash -Path releases/Riftosaur-debug.apk -Algorithm SHA256

# Verify ZIP integrity
tar -tf releases/Riftosaur-debug.apk
```
