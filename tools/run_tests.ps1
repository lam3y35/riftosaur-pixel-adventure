# Riftosaur Test and Validation Runner
param (
    [switch]$L1Only,
    [switch]$L2Only
)

$godot = "C:\Users\Tweety\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path $godot)) {
    Write-Error "Godot executable not found at: $godot"
    exit 1
}

$exitCode = 0

if (-not $L2Only) {
    Write-Host "`n>>> Running L1 Validation <<<" -ForegroundColor Cyan
    & $godot --headless --path . --script tools/validate_l1.gd
    if ($LASTEXITCODE -ne 0) {
        Write-Error "L1 Validation failed!"
        $exitCode = 1
    }

    Write-Host "`n>>> Running Validator V1 (Analytic Reach/Rise Fairness) <<<" -ForegroundColor Cyan
    & $godot --headless --path . --script tools/validate_v1.gd
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Validator V1 failed!"
        $exitCode = 1
    }
}

if (-not $L1Only -and $exitCode -eq 0) {
    Write-Host "`n>>> Running L2 Automated Tests <<<" -ForegroundColor Cyan
    & $godot --headless --path . --script tests/test_runner.gd
    if ($LASTEXITCODE -ne 0) {
        Write-Error "L2 Tests failed!"
        $exitCode = 1
    }
}

if ($exitCode -eq 0) {
    Write-Host "`nAll validation and tests passed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nSome checks failed." -ForegroundColor Red
}

exit $exitCode
