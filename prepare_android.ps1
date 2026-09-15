$ErrorActionPreference = 'Stop'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { Write-Host 'Flutter غير مثبت أو غير موجود في PATH.' -ForegroundColor Red; exit 1 }
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$temp = Join-Path $root '_flutter_android_temp'
if (Test-Path $temp) { Remove-Item $temp -Recurse -Force }
flutter create --platforms=android --project-name islamic_kids_learning $temp
Remove-Item (Join-Path $temp 'lib') -Recurse -Force
Copy-Item (Join-Path $root 'lib') (Join-Path $temp 'lib') -Recurse
Copy-Item (Join-Path $root 'pubspec.yaml') (Join-Path $temp 'pubspec.yaml') -Force
if (Test-Path (Join-Path $root 'assets')) { Copy-Item (Join-Path $root 'assets') (Join-Path $temp 'assets') -Recurse }
$manifest = Join-Path $temp 'android/app/src/main/AndroidManifest.xml'
if (Test-Path $manifest) {
  $m = Get-Content $manifest -Raw
  $m = $m -replace 'android:label="[^"]*"', 'android:label="طفلي المسلم"'
  Set-Content $manifest $m -Encoding UTF8
}
$backup = Join-Path $root '_backup_before_android_fix'
if (Test-Path $backup) { Remove-Item $backup -Recurse -Force }
New-Item -ItemType Directory -Path $backup | Out-Null
Get-ChildItem $root -Force | Where-Object { $_.Name -notin @('_flutter_android_temp','_backup_before_android_fix') } | ForEach-Object { Move-Item $_.FullName $backup -Force }
Get-ChildItem $temp -Force | ForEach-Object { Move-Item $_.FullName $root -Force }
Remove-Item $temp -Recurse -Force
Write-Host 'تم تجهيز مشروع Android حديث.' -ForegroundColor Green
