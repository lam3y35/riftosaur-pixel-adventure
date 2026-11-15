# Riftosaur Releases & Build Artifacts

This directory stores locally generated build artifacts (Android APKs, packages, checksums).

> **Note:** Binary APK files are excluded from git tracking via `.gitignore`. Checksums and verification logs are recorded in this file and in `docs/WORKLOG.md`.

---

## Naming Conventions

- **Debug Builds (Ready to Sideload):** `Riftosaur-debug.apk` (v1.3.0, signed with Godot debug keystore for direct Android installation)
- **Release Builds (Unsigned Pre-Store):** `Riftosaur-release.apk` (v1.3.0, optimized unsigned release export; sign with release keystore before Play Store / device install)
- **Checksums:** `SHA256SUMS.txt`

---

## Builds Register

| File | Target | Version Code | Version Name | Size | SHA-256 Checksum | Evidence Level |
|---|---|---|---|---|---|---|
| `Riftosaur-debug.apk` | Android (arm64-v8a, x86_64) | 4 | 1.3.0 | 62,795,904 bytes (59.89 MB) | `76F07D66009CA458919FDB6C82C5D89578A30B7129893C24CEEDB0FB0C60013D` | L4 Static Debug APK Verification (v1.3.0 Debug Signed) |
| `Riftosaur-release.apk` | Android (arm64-v8a, x86_64) | 4 | 1.3.0 | 58,057,686 bytes (55.37 MB) | `AA249AE1F2862B6487AECA4CDA45DB5A95E8901E464E391F94D859D53B42B46D` | L4 Static Release APK Verification (`-AllowUnsigned`, zipaligned) |

---

## Verification Commands

To verify an APK locally on Windows:
```powershell
# Calculate SHA-256
Get-FileHash -Path releases/Riftosaur-release.apk -Algorithm SHA256

# Verify APK package, alignment, and signature
powershell.exe -ExecutionPolicy Bypass -File tools/verify_apk.ps1 -apkPath "releases/Riftosaur-release.apk"
```
