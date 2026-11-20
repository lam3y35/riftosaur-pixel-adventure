# Riftosaur Releases & Build Artifacts

This directory stores locally generated build artifacts (Android APKs, packages, checksums).

> **Note:** Binary APK files are excluded from git tracking via `.gitignore`. Checksums and verification logs are recorded in this file and in `docs/WORKLOG.md`.

---

## Naming Conventions

- **Debug Builds (Ready to Sideload):** `Riftosaur-debug.apk` (v1.4.0, signed with Godot debug keystore for direct Android installation)
- **Release Builds (Unsigned Pre-Store):** `Riftosaur-release.apk` (v1.4.0, optimized unsigned release export; sign with release keystore before Play Store / device install)
- **Checksums:** `SHA256SUMS.txt`

---

## Builds Register

| File | Target | Version Code | Version Name | Size | SHA-256 Checksum | Evidence Level |
|---|---|---|---|---|---|---|
| `Riftosaur-debug.apk` | Android (arm64-v8a, x86_64) | 4 | 1.3.0 | 62,863,962 bytes (59.95 MB) | `24A8083C5364D60EFF6779792D96FEDF09477C6604E7DE14CEC1326BF2B4F5A5` | L4 Static Debug APK Verification (v1.4.0 Debug Signed) |
| `Riftosaur-release.apk` | Android (arm64-v8a, x86_64) | 4 | 1.3.0 | 58,120,028 bytes (55.43 MB) | `546C3430F716587E8DFD111190C6467937C0A5657F41E501341D5E23A223DAB3` | L4 Static Release APK Verification (`-AllowUnsigned`, zipaligned) |

---

## Verification Commands

To verify an APK locally on Windows:
```powershell
# Calculate SHA-256
Get-FileHash -Path releases/Riftosaur-release.apk -Algorithm SHA256

# Verify APK package, alignment, and signature
powershell.exe -ExecutionPolicy Bypass -File tools/verify_apk.ps1 -apkPath "releases/Riftosaur-release.apk"
```
