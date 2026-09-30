<#
.SYNOPSIS
  Publica una nueva version: compila el APK release, crea el tag,
  lo sube a GitHub y publica el Release con el APK adjunto.

.EXAMPLE
  .\tool\release.ps1 -Version 1.0.1
  .\tool\release.ps1 -Version 1.0.1 -Notes "Arreglo del total semanal"

.NOTES
  Usa las credenciales guardadas de git (las mismas del push).
  No imprime ni guarda ningun token.
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$Version,

  [string]$Notes = ""
)

$ErrorActionPreference = 'Stop'
$Repo = 'tincho950303/app-ingresos-riders'
$ProjectDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
# Si el script vive en <proyecto>/tool/, la raiz es su padre:
if (-not (Test-Path "$ProjectDir/pubspec.yaml")) {
  $ProjectDir = Split-Path $PSScriptRoot -Parent
}
Set-Location $ProjectDir

if ($Notes -eq '') {
  $Notes = 'Actualizacion de la app. Descarga el APK, permite apps desconocidas e instala.'
}

Write-Host "== 1/5 flutter analyze ==" -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze fallo' }

Write-Host '== 2/5 build APK release ==' -ForegroundColor Cyan
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw 'flutter build fallo' }

$apk = 'build/app/outputs/flutter-apk/app-release.apk'
$mb = [math]::Round((Get-Item $apk).Length / 1MB, 1)
Write-Host "APK listo: $apk ($mb MB)" -ForegroundColor Green

Write-Host '== 3/5 tag + push ==' -ForegroundColor Cyan
git tag -a "v$Version" -m "v$Version Control de Ganancias"
git push origin "v$Version"

Write-Host '== 4/5 crear Release en GitHub ==' -ForegroundColor Cyan
$credInput = "protocol=https`nhost=github.com`n`n"
$cred = ($credInput | git credential fill 2>&1) | Out-String
$user = ([regex]::Match($cred, '(?m)^username=(.*)$')).Groups[1].Value.Trim()
$pass = ([regex]::Match($cred, '(?m)^password=(.*)$')).Groups[1].Value.Trim()
$b64 = [Convert]::ToBase64String(
  [Text.Encoding]::UTF8.GetBytes("${user}:${pass}"))
$H = @{
  Authorization = "Basic $b64"
  Accept        = 'application/vnd.github+json'
}
$releaseBody = @{
  tag_name = "v$Version"
  name     = "v$Version Control de Ganancias"
  body     = $Notes
} | ConvertTo-Json
$rel = Invoke-RestMethod `
  -Uri "https://api.github.com/repos/$Repo/releases" `
  -Method Post -Headers $H -Body $releaseBody `
  -ContentType 'application/json'
Write-Host "Release: $($rel.html_url)" -ForegroundColor Green

Write-Host '== 5/5 subir APK ==' -ForegroundColor Cyan
$asset = Invoke-RestMethod `
  -Uri "https://uploads.github.com/repos/$Repo/releases/$($rel.id)/assets?name=control-ganancias-v$Version.apk" `
  -Method Post `
  -Headers ($H + @{'Content-Type' = 'application/vnd.android.package-archive' }) `
  -InFile $apk
Write-Host "APK: $($asset.browser_download_url)" -ForegroundColor Green
Write-Host 'Listo.' -ForegroundColor Green
