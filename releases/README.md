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
| `Riftosaur-release.apk` | Android (arm64-v8a, x86_64) | 3 | 1.2.0 | 58,075,419 bytes (55.39 MB) | `69BD536F66E5E5B088CD018FA1EEAABA1090BDD22011EAF122D4EEAE76994B93` | L4 Static Release APK Verification (v1.2.0 Signed) |
| `Riftosaur-debug.apk` | Android (arm64-v8a, x86_64) | 3 | 1.2.0 | 62,746,752 bytes (59.84 MB) | `8DA287D9D99BAF1264D126A7DABC3105B2AF021884DE806A17E31C85B6D22953` | L4 Static Debug APK Verification (v1.2.0 Debug Signed) |

---

## Verification Commands

To verify an APK locally on Windows:
```powershell
# Calculate SHA-256
Get-FileHash -Path releases/Riftosaur-release.apk -Algorithm SHA256

# Verify APK package, alignment, and signature
powershell.exe -ExecutionPolicy Bypass -File tools/verify_apk.ps1 -apkPath "releases/Riftosaur-release.apk"
```
