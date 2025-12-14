# Script to create 7-inch and 10-inch tablet emulators
# Run this script in PowerShell: .\create_tablet_emulators.ps1

$AVD_MANAGER = "C:\android-sdk\cmdline-tools\latest\bin\avdmanager.bat"
$SDK_MANAGER = "C:\android-sdk\cmdline-tools\latest\bin\sdkmanager.bat"

# System image to use (Android 30 = API 30)
$SYSTEM_IMAGE = "system-images;android-30;google_apis;x86_64"

Write-Host "=== Tao Emulator May tinh bang 7 inch va 10 inch ===" -ForegroundColor Cyan
Write-Host ""

# Check if system image is installed
Write-Host "Kiem tra system image..." -ForegroundColor Yellow
$installed = & $SDK_MANAGER --list_installed | Select-String $SYSTEM_IMAGE

if (-not $installed) {
    Write-Host "System image chua duoc cai dat. Dang tai..." -ForegroundColor Yellow
    Write-Host "Luu y: Qua trinh nay co the mat 5-10 phut va can ~1GB dung luong" -ForegroundColor Yellow
    Write-Host ""
    
    # Accept licenses first
    Write-Host "Chap nhan licenses..." -ForegroundColor Yellow
    & $SDK_MANAGER --licenses | Out-Null
    
    # Download system image
    Write-Host "Dang tai system image (Android 30, Google APIs, x86_64)..." -ForegroundColor Yellow
    & $SDK_MANAGER $SYSTEM_IMAGE
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Loi khi tai system image. Vui long thu lai." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Tai xong!" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "System image da duoc cai dat." -ForegroundColor Green
    Write-Host ""
}

# Create 7-inch tablet emulator
Write-Host "Tao emulator 7 inch..." -ForegroundColor Green
& $AVD_MANAGER create avd -n Tablet_7inch -k $SYSTEM_IMAGE -d "pixel_c" --force

if ($LASTEXITCODE -eq 0) {
    # Update config for 7-inch tablet
    $configPath = "$env:USERPROFILE\.android\avd\Tablet_7inch.avd\config.ini"
    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw
        $config = $config -replace 'hw\.lcd\.width\s*=.*', 'hw.lcd.width = 600'
        $config = $config -replace 'hw\.lcd\.height\s*=.*', 'hw.lcd.height = 1024'
        $config = $config -replace 'hw\.lcd\.density\s*=.*', 'hw.lcd.density = 213'
        Set-Content $configPath -Value $config -NoNewline
        Write-Host "  [OK] Da cau hinh: 600x1024 (7 inch)" -ForegroundColor Green
    }
} else {
    Write-Host "  [ERROR] Loi khi tao emulator 7 inch" -ForegroundColor Red
}

Write-Host ""

# Create 10-inch tablet emulator (16:9 ratio for Google Play requirements)
# Google Play requires: 16:9 or 9:16, each side 1080px to 7680px
# Using 1920x1080 (16:9) - Full HD, suitable for 10-inch tablet
Write-Host "Tao emulator 10 inch (1920x1080, 16:9)..." -ForegroundColor Green
& $AVD_MANAGER create avd -n Tablet_10inch -k $SYSTEM_IMAGE -d "pixel_c" --force

if ($LASTEXITCODE -eq 0) {
    # Update config for 10-inch tablet with 16:9 ratio
    $configPath = "$env:USERPROFILE\.android\avd\Tablet_10inch.avd\config.ini"
    if (Test-Path $configPath) {
        $config = Get-Content $configPath -Raw
        $config = $config -replace 'hw\.lcd\.width\s*=.*', 'hw.lcd.width = 1920'
        $config = $config -replace 'hw\.lcd\.height\s*=.*', 'hw.lcd.height = 1080'
        $config = $config -replace 'hw\.lcd\.density\s*=.*', 'hw.lcd.density = 320'
        Set-Content $configPath -Value $config -NoNewline
        Write-Host "  [OK] Da cau hinh: 1920x1080 (10 inch, 16:9)" -ForegroundColor Green
        Write-Host "  [INFO] Phu hop voi yeu cau Google Play: 16:9, 1080px min" -ForegroundColor Cyan
    }
} else {
    Write-Host "  [ERROR] Loi khi tao emulator 10 inch" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Hoan thanh ===" -ForegroundColor Cyan
Write-Host ""

# List created emulators
Write-Host "Danh sach emulators da tao:" -ForegroundColor Yellow
& $AVD_MANAGER list avd

Write-Host ""
Write-Host "De chay emulator, dung lenh:" -ForegroundColor Cyan
Write-Host "  flutter emulators --launch Tablet_7inch" -ForegroundColor White
Write-Host "  flutter emulators --launch Tablet_10inch" -ForegroundColor White
Write-Host ""
Write-Host "Hoac chay app truc tiep:" -ForegroundColor Cyan
Write-Host "  flutter run -d Tablet_7inch" -ForegroundColor White
Write-Host "  flutter run -d Tablet_10inch" -ForegroundColor White

