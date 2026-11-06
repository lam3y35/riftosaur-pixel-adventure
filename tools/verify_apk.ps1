# Spec D: Full APK Verification Script for Riftosaur
param(
    [string]$apkPath = "releases/Riftosaur-release.apk"
)
$buildTools = "C:\Users\Tweety\AppData\Local\Android\Sdk\build-tools\36.0.0"
$aapt2 = "$buildTools\aapt2.exe"
$zipalign = "$buildTools\zipalign.exe"
$apksigner = "$buildTools\apksigner.bat"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Riftosaur APK Verification (Spec D - Level L4)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Existence, Size, and SHA-256
if (-not (Test-Path $apkPath)) {
    Write-Error "APK file does not exist at: $apkPath"
    exit 1
}
$fileItem = Get-Item $apkPath
$hash = (Get-FileHash -Path $apkPath -Algorithm SHA256).Hash
Write-Host "1. File Check:" -ForegroundColor Yellow
Write-Host "   Path   : $($fileItem.FullName)"
Write-Host "   Size   : $($fileItem.Length) bytes ($([math]::Round($fileItem.Length / 1MB, 2)) MB)"
Write-Host "   SHA-256: $hash"

# 2. Metadata Dump via aapt2
Write-Host "`n2. Metadata Dump (aapt2):" -ForegroundColor Yellow
$badging = & $aapt2 dump badging $apkPath
$packageLine = $badging | Select-String "package: name="
$sdkLine = $badging | Select-String "sdkVersion:"
$targetSdkLine = $badging | Select-String "targetSdkVersion:"
$activityLine = $badging | Select-String "launchable-activity:"
$nativeCodeLine = $badging | Select-String "native-code:"

Write-Host "   $packageLine"
Write-Host "   $sdkLine"
Write-Host "   $targetSdkLine"
Write-Host "   $nativeCodeLine"
Write-Host "   $activityLine"

# 3. Alignment Check via zipalign
Write-Host "`n3. 4-byte Alignment Check (zipalign):" -ForegroundColor Yellow
$alignOutput = & $zipalign -c -v 4 $apkPath 2>&1
$lastAlign = $alignOutput[-1]
Write-Host "   Result: $lastAlign"
if ($lastAlign -notmatch "Verification succesful" -and $lastAlign -notmatch "Verification successful") {
    Write-Error "Alignment check failed!"
    exit 1
}

# 4. Digital Signature Check via apksigner
Write-Host "`n4. Digital Signature & Certs (apksigner):" -ForegroundColor Yellow
& $apksigner verify --print-certs $apkPath

# 5. Archive Content Spot-Check
Write-Host "`n5. Archive Content Spot-Check:" -ForegroundColor Yellow
$zipContent = tar -tf $apkPath
$hasDex = ($zipContent -match "classes.dex").Count -gt 0
$hasArm64 = ($zipContent -match "lib/arm64-v8a/libgodot_android.so").Count -gt 0
$hasX86 = ($zipContent -match "lib/x86_64/libgodot_android.so").Count -gt 0
$hasPck = ($zipContent -match "assets/").Count -gt 0

Write-Host "   classes.dex present       : $hasDex"
Write-Host "   arm64-v8a native binary   : $hasArm64"
Write-Host "   x86_64 native binary      : $hasX86"
Write-Host "   assets/ archive bundled   : $hasPck"

# 6. Permissions Verification (Session 10 / Spec B)
Write-Host "`n6. Android Permissions Verification:" -ForegroundColor Yellow
$permissions = & $aapt2 dump permissions $apkPath
$hasVibrate = ($permissions -match "android.permission.VIBRATE").Count -gt 0
$hasInternet = ($permissions -match "android.permission.INTERNET").Count -gt 0
Write-Host "   android.permission.VIBRATE   : $hasVibrate"
Write-Host "   android.permission.INTERNET  : $hasInternet"
if ($hasInternet) {
    Write-Error "Security/Spec violation: INTERNET permission found in offline build!"
    exit 1
}

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host "APK Static Verification: PASSED (L4 Level Achieved)" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
