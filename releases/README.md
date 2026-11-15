# Riftosaur Releases & Build Artifacts

This directory stores locally generated build artifacts (Android APKs, packages, checksums).

> **Note:** Binary APK files are excluded from git tracking via `.gitignore`. Checksums and verification logs are recorded in this file and in `docs/WORKLOG.md`.

---

## Naming Conventions

- **Release Builds:** `Riftosaur-release.apk` (v1.1.0, optimized release export signed with the local Godot keystore; can be re-signed with `riftosaur-release.keystore` via `apksigner` for store distribution)
- **Debug Builds:** `Riftosaur-debug.apk` (v1.1.0, signed with Godot debug keystore)
- **Checksums:** `SHA256SUMS.txt`

---

## Builds Register

| File | Target | Version Code | Version Name | Size | SHA-256 Checksum | Evidence Level |
|---|---|---|---|---|---|---|
| `Riftosaur-release.apk` | Android (arm64-v8a, x86_64) | 2 | 1.1.0 | 57,923,667 bytes (55.24 MB) | `351F12E64BA93A6F907A9C16D0C9FD4636185DC7B8022BED764937C7BD8C4295` | L4 Static Release APK Verification (v1.1.0 Signed with Local Godot Keystore) |
| `Riftosaur-debug.apk` | Android (arm64-v8a, x86_64) | 2 | 1.1.0 | 62,605,874 bytes (59.71 MB) | `F06CAE64C9BCDE1EB381638C9FE1CB16A66F999815AB952C403A82D226838AD8` | L4 Static Debug APK Verification (v1.1.0 Debug Signed) |

---

## Verification Commands

To verify an APK locally on Windows:
```powershell
# Calculate SHA-256
Get-FileHash -Path releases/Riftosaur-release.apk -Algorithm SHA256

# Verify APK package, alignment, and signature
powershell.exe -ExecutionPolicy Bypass -File tools/verify_apk.ps1 -apkPath "releases/Riftosaur-release.apk"
```
