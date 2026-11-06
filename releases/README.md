# Riftosaur Releases & Build Artifacts

This directory stores locally generated build artifacts (Android APKs, packages, checksums).

> **Note:** Binary APK files are excluded from git tracking via `.gitignore`. Checksums and verification logs are recorded in this file and in `docs/WORKLOG.md`.

---

## Naming Conventions

- **Release Builds:** `Riftosaur-release.apk` (Signed with production release keystore, optimized size, v1.0.0)
- **Debug Builds:** `Riftosaur-debug.apk` (Signed with Godot debug keystore, v1.0.0)
- **Checksums:** `SHA256SUMS.txt`

---

## Builds Register

| File | Target | Version Code | Version Name | Size | SHA-256 Checksum | Evidence Level |
|---|---|---|---|---|---|---|
| `Riftosaur-release.apk` | Android (arm64-v8a, x86_64) | 1 | 1.0.0 | 62,987,449 bytes (60.07 MB) | `7E7E3A6DA48AA33913FDA77C9D3FEE654619F0ED32A47188458FBDE65D726204` | L4 Static Release APK Verification (v1.0.0 Production Signed) |
| `Riftosaur-debug.apk` | Android (arm64-v8a, x86_64) | 1 | 1.0.0 | 67,654,686 bytes (64.52 MB) | `1F5E33E3DB9CA82F3A04A5F6C1E97B78C2682EEBADF93811BDEC85372FFB3D55` | L4 Static Debug APK Verification (v1.0.0 Debug Signed) |

---

## Verification Commands

To verify an APK locally on Windows:
```powershell
# Calculate SHA-256
Get-FileHash -Path releases/Riftosaur-release.apk -Algorithm SHA256

# Verify APK package, alignment, and signature
powershell.exe -ExecutionPolicy Bypass -File tools/verify_apk.ps1 -apkPath "releases/Riftosaur-release.apk"
```
