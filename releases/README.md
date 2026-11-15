# Riftosaur Releases & Build Artifacts

This directory stores locally generated build artifacts (Android APKs, packages, checksums).

> **Note:** Binary APK files are excluded from git tracking via `.gitignore`. Checksums and verification logs are recorded in this file and in `docs/WORKLOG.md`.

---

## Naming Conventions

- **Release Builds:** `Riftosaur-release.apk` (v1.2.0, optimized release export signed for Android distribution)
- **Debug Builds:** `Riftosaur-debug.apk` (v1.2.0, signed with Godot debug keystore)
- **Checksums:** `SHA256SUMS.txt`

---

## Builds Register

| File | Target | Version Code | Version Name | Size | SHA-256 Checksum | Evidence Level |
|---|---|---|---|---|---|---|
| `Riftosaur-release.apk` | Android (arm64-v8a, x86_64) | 3 | 1.2.0 | 58,071,323 bytes (55.38 MB) | `36A2FC70DD9FA0992802F910C74838C99D9C885D19EDDA6E81F34064404CCED2` | L4 Static Release APK Verification (v1.2.0 Signed) |
| `Riftosaur-debug.apk` | Android (arm64-v8a, x86_64) | 3 | 1.2.0 | 62,742,656 bytes (59.84 MB) | `CE1B86A9ED58C92F2FEECF97012DA6020DFE815D6AFEB16496808ABB25C91D16` | L4 Static Debug APK Verification (v1.2.0 Debug Signed) |

---

## Verification Commands

To verify an APK locally on Windows:
```powershell
# Calculate SHA-256
Get-FileHash -Path releases/Riftosaur-release.apk -Algorithm SHA256

# Verify APK package, alignment, and signature
powershell.exe -ExecutionPolicy Bypass -File tools/verify_apk.ps1 -apkPath "releases/Riftosaur-release.apk"
```
