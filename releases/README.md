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
| `Riftosaur-debug.apk` | Android (arm64-v8a, x86_64) | 4 | 1.3.0 | 62,800,000 bytes (59.89 MB) | `8A03B0D2567FE41BA3DD28492F9805424BA07C9B7AE36EA2C3730DA3B02E60B9` | L4 Static Debug APK Verification (v1.3.0 Debug Signed) |
| `Riftosaur-release.apk` | Android (arm64-v8a, x86_64) | 4 | 1.3.0 | 58,061,938 bytes (55.37 MB) | `644330A4EA98F023E0EB8F0F2AA7EE21E3FC02E5FF8C366172DBD7A811A57095` | L4 Static Release APK Verification (`-AllowUnsigned`, zipaligned) |

---

## Verification Commands

To verify an APK locally on Windows:
```powershell
# Calculate SHA-256
Get-FileHash -Path releases/Riftosaur-release.apk -Algorithm SHA256

# Verify APK package, alignment, and signature
powershell.exe -ExecutionPolicy Bypass -File tools/verify_apk.ps1 -apkPath "releases/Riftosaur-release.apk"
```
