# Instalacion en un paso del kit para Google Antigravity.
# En PowerShell:
#   irm https://raw.githubusercontent.com/rameseba/kit-antigravity-ia/main/bootstrap.ps1 | iex
# Sin preguntas (por ejemplo desde el agente):
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/rameseba/kit-antigravity-ia/main/bootstrap.ps1))) -Programas Base -Marca "MiEstudio" -Correo "contacto@miestudio.cl" -GitUser "miestudio" -Pais "Venezuela"
# Actualizar (reusa los datos guardados en ~/.gemini/kit.json, no toca mis-reglas.md ni mis-*.md):
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/rameseba/kit-antigravity-ia/main/bootstrap.ps1))) -Actualizar
param(
  [ValidateSet('Preguntar','Base','Liviano','Todo','Ninguno')][string]$Programas = 'Preguntar',
  [string]$Marca, [string]$Dominio, [string]$Correo, [string]$GitUser, [string]$Pais,
  [switch]$Actualizar, [switch]$SoloRevisar
)
$ErrorActionPreference = 'Stop'
# Windows trae los .ps1 bloqueados por defecto: permitirlos SOLO en esta ventana (no cambia la seguridad del PC)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$repo = 'rameseba/kit-antigravity-ia'
$kitJson = Join-Path $HOME '.gemini\kit.json'

# Version publicada (ultimo commit)
$remota = ''
try { $remota = (Invoke-RestMethod "https://api.github.com/repos/$repo/commits/main" -Headers @{ 'User-Agent' = 'kit-antigravity' }).sha.Substring(0, 7) } catch { }

if ($Actualizar -or $SoloRevisar) {
  $prev = if (Test-Path $kitJson) { Get-Content $kitJson -Raw | ConvertFrom-Json } else { $null }
  $local = if ($prev) { $prev.version } else { '' }
  if ($SoloRevisar) {
    if ($remota -and $local -eq $remota) { Write-Host "El kit esta al dia (version $local)." -ForegroundColor Green }
    else { Write-Host "Hay una version nueva del kit: instalada '$local', publicada '$remota'." -ForegroundColor Yellow }
    try { Write-Host ((Invoke-RestMethod "https://raw.githubusercontent.com/$repo/main/CHANGELOG.md") -split "`n" | Select-Object -First 25 | Out-String) } catch { }
    return
  }
  if ($prev) {
    if (-not $Marca)   { $Marca = $prev.marca }
    if (-not $Dominio) { $Dominio = $prev.dominio }
    if (-not $Correo)  { $Correo = $prev.correo }
    if (-not $GitUser) { $GitUser = $prev.gitUser }
    if (-not $Pais)    { $Pais = $prev.pais }
  }
  if ($Programas -eq 'Preguntar') { $Programas = 'Ninguno' }
}

$tmp  = Join-Path $env:TEMP ("kit-antigravity-" + (Get-Date -Format 'yyyyMMddHHmmss'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
Write-Host "Descargando el kit desde github.com/$repo ..." -ForegroundColor Cyan
$zip = Join-Path $tmp 'kit.zip'
$ProgressPreference = 'SilentlyContinue'   # la barra de progreso hace MUY lenta la descarga en PowerShell 5
Invoke-WebRequest "https://github.com/$repo/archive/refs/heads/main.zip" -OutFile $zip -UseBasicParsing
Unblock-File $zip
Expand-Archive $zip -DestinationPath $tmp -Force
$kit = Get-ChildItem $tmp -Directory | Select-Object -First 1 -ExpandProperty FullName
Get-ChildItem $kit -Recurse -Filter *.ps1 | Unblock-File
if ($remota) { Set-Content -Path (Join-Path $kit 'VERSION') -Value $remota }

# Programas del PC
$progScript = Join-Path $kit 'programas\instalar-programas.ps1'
switch ($Programas) {
  'Base'    { & $progScript -SoloBase }
  'Liviano' { & $progScript -SoloBase -Liviano }
  'Todo'    { & $progScript -Todo }
  'Preguntar' {
    $r = Read-Host 'Instalar tambien los programas (Git, Node, Python, Chrome, CLIs...)? (s/n)'
    if ($r -match '^[sSyY]') { & $progScript }
  }
}

# Reglas y skills
$inst = Join-Path $kit 'instalar.ps1'
if ($Marca -or $Dominio -or $Correo -or $GitUser -or $Pais) {
  & $inst -Marca $Marca -Dominio $Dominio -Correo $Correo -GitUser $GitUser -Pais $Pais
} elseif ($Programas -eq 'Preguntar') {
  & $inst
} else {
  & $inst -SinPreguntas
}

# Copia local del kit (README, plantillas). Se reemplaza en cada actualizacion: no guardar cosas propias ahi.
$dest = Join-Path $HOME 'kit-antigravity-ia'
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
Copy-Item $kit $dest -Recurse
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Copia del kit (README.md, plantillas): $dest" -ForegroundColor Green
if ($Actualizar) { Write-Host "Kit actualizado a la version $remota. Tus archivos mis-reglas.md y mis-*.md no se tocaron." -ForegroundColor Green }
