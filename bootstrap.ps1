# Instalacion en un paso del kit para Google Antigravity.
# En PowerShell:
#   irm https://raw.githubusercontent.com/rameseba/kit-antigravity-ia/main/bootstrap.ps1 | iex
# Sin preguntas (por ejemplo desde el agente):
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/rameseba/kit-antigravity-ia/main/bootstrap.ps1))) -Programas Base -Marca "MiEstudio" -Dominio "miestudio.cl" -Correo "contacto@miestudio.cl" -GitUser "miestudio"
param(
  [ValidateSet('Preguntar','Base','Todo','Ninguno')][string]$Programas = 'Preguntar',
  [string]$Marca, [string]$Dominio, [string]$Correo, [string]$GitUser
)
$ErrorActionPreference = 'Stop'
# Windows trae los .ps1 bloqueados por defecto: permitirlos SOLO en esta ventana (no cambia la seguridad del PC)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$repo = 'rameseba/kit-antigravity-ia'
$tmp  = Join-Path $env:TEMP ("kit-antigravity-" + (Get-Date -Format 'yyyyMMddHHmmss'))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

Write-Host "Descargando el kit desde github.com/$repo ..." -ForegroundColor Cyan
$zip = Join-Path $tmp 'kit.zip'
Invoke-WebRequest "https://github.com/$repo/archive/refs/heads/main.zip" -OutFile $zip -UseBasicParsing
Unblock-File $zip
Expand-Archive $zip -DestinationPath $tmp -Force
$kit = Get-ChildItem $tmp -Directory | Select-Object -First 1 -ExpandProperty FullName
Get-ChildItem $kit -Recurse -Filter *.ps1 | Unblock-File

# Programas del PC
$progScript = Join-Path $kit 'programas\instalar-programas.ps1'
switch ($Programas) {
  'Base' { & $progScript -SoloBase }
  'Todo' { & $progScript -Todo }
  'Preguntar' {
    $r = Read-Host 'Instalar tambien los programas (Git, Node, Python, Chrome, CLIs...)? (s/n)'
    if ($r -match '^[sSyY]') { & $progScript }
  }
}

# Reglas y skills
$inst = Join-Path $kit 'instalar.ps1'
if ($Marca -or $Dominio -or $Correo -or $GitUser) {
  & $inst -Marca $Marca -Dominio $Dominio -Correo $Correo -GitUser $GitUser
} elseif ($Programas -eq 'Preguntar') {
  & $inst
} else {
  & $inst -SinPreguntas
}

# Copia local del kit (README, plantillas) para consultarla despues
$dest = Join-Path $HOME 'kit-antigravity-ia'
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
Copy-Item $kit $dest -Recurse
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Copia del kit (README.md, plantillas): $dest" -ForegroundColor Green
