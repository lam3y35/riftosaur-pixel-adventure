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
| `Riftosaur-debug.apk` | Android (arm64-v8a, x86_64) | 1 | 0.3.0 | 67,637,767 bytes (64.50 MB) | `95C2D8F1E67E1E34B4C7DB94FBA4593245CFBF38A1B9A85FD229733F8B68C039` | L4 Static APK Verification (M8 part 2: Schema v2, Lifecycle, Offline) |

---

## Verification Commands

To verify an APK locally on Windows:
```powershell
# Calculate SHA-256
Get-FileHash -Path releases/Riftosaur-debug.apk -Algorithm SHA256

# Verify ZIP integrity
tar -tf releases/Riftosaur-debug.apk
```
