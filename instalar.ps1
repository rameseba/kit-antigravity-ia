# Instalador del kit de reglas y skills para Google Antigravity (Windows / PowerShell)
# Uso: clic derecho > "Ejecutar con PowerShell", o en una terminal:
#   powershell -ExecutionPolicy Bypass -File .\instalar.ps1
# Opcional: -Legacy  (copia las skills tambien en ~/.gemini/antigravity/skills para versiones antiguas)
#           -Marca X -Dominio x.cl -Correo c@x.cl -GitUser x   (sin preguntas; util desde el agente)
param([switch]$Legacy, [string]$Marca, [string]$Dominio, [string]$Correo, [string]$GitUser, [switch]$SinPreguntas)

$ErrorActionPreference = 'Stop'
$kit    = Split-Path -Parent $MyInvocation.MyCommand.Path
$src    = Join-Path $kit 'gemini'
$gemini = Join-Path $HOME '.gemini'
$config = Join-Path $gemini 'config'
$fecha  = Get-Date -Format 'yyyy-MM-dd-HHmm'

Write-Host ''
Write-Host '=== Kit Antigravity: instalacion ===' -ForegroundColor Cyan
$marca = $Marca; $dominio = $Dominio; $correo = $Correo; $gituser = $GitUser
if (-not $SinPreguntas -and -not ($marca -or $dominio -or $correo -or $gituser)) {
  Write-Host 'Responde 4 datos para personalizar las reglas (Enter = dejar el marcador para editar despues).'
  $marca   = Read-Host 'Nombre de tu marca o estudio (ej. MiEstudio)'
  $dominio = Read-Host 'Tu dominio (ej. miestudio.cl)'
  $correo  = Read-Host 'Correo de trabajo publico (ej. contacto@miestudio.cl)'
  $gituser = Read-Host 'Usuario de git (ej. miestudio)'
}

New-Item -ItemType Directory -Force -Path $gemini, $config, (Join-Path $config 'rules'), (Join-Path $config 'skills'), (Join-Path $gemini 'memoria') | Out-Null

# 1) Respaldo de lo que ya exista
$destGem = Join-Path $gemini 'GEMINI.md'
if (Test-Path $destGem) {
  Copy-Item $destGem "$destGem.bak-$fecha"
  Write-Host "Respaldo: GEMINI.md -> GEMINI.md.bak-$fecha" -ForegroundColor Yellow
}
$destRules = Join-Path $config 'rules'
if ((Get-ChildItem $destRules -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) {
  Copy-Item $destRules "$destRules.bak-$fecha" -Recurse
  Write-Host "Respaldo: rules -> rules.bak-$fecha" -ForegroundColor Yellow
}

# 2) Copiar reglas y skills
Copy-Item (Join-Path $src 'GEMINI.md') $destGem -Force
Copy-Item (Join-Path $src 'config\rules\*') $destRules -Recurse -Force
Copy-Item (Join-Path $src 'config\skills\*') (Join-Path $config 'skills') -Recurse -Force
if ($Legacy) {
  $leg = Join-Path $gemini 'antigravity\skills'
  New-Item -ItemType Directory -Force -Path $leg | Out-Null
  Copy-Item (Join-Path $src 'config\skills\*') $leg -Recurse -Force
}
$leads = Join-Path $gemini 'memoria\leads.md'
if (-not (Test-Path $leads)) {
  Set-Content -Path $leads -Encoding UTF8 -Value "# Leads y clientes`n`n| Fecha | Lead | Que pidio | Estado | Proximo seguimiento |`n|---|---|---|---|---|`n"
}

# 3) Personalizar marcadores
$reemplazos = [ordered]@{}
if ($correo)  { $reemplazos['<contacto@tu-dominio.com>'] = $correo }
if ($dominio) { $reemplazos['<tu-dominio.com>'] = $dominio }
if ($marca)   { $reemplazos['<TU_MARCA>'] = $marca }
if ($gituser) { $reemplazos['<tu-marca>'] = $gituser }
if ($reemplazos.Count -gt 0) {
  $archivos = @($destGem) + (Get-ChildItem $destRules -Filter *.md -File).FullName
  foreach ($s in 'guardar-estado','propuesta-visual','cerebro') {
    $p = Join-Path $config "skills\$s\SKILL.md"; if (Test-Path $p) { $archivos += $p }
  }
  foreach ($f in $archivos) {
    $t = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8)
    foreach ($k in $reemplazos.Keys) { $t = $t.Replace($k, $reemplazos[$k]) }
    [IO.File]::WriteAllText($f, $t, (New-Object Text.UTF8Encoding($false)))
  }
}

$nSkills = (Get-ChildItem (Join-Path $config 'skills') -Directory).Count
Write-Host ''
Write-Host "Listo. Reglas globales: $destGem" -ForegroundColor Green
Write-Host "Reglas tematicas: $destRules"
Write-Host "Skills instaladas: $nSkills en $(Join-Path $config 'skills')"
Write-Host ''
Write-Host 'Siguiente paso: cierra y vuelve a abrir Antigravity. Luego lee README.md (seccion "Primeros pasos").'
if (-not ($marca -and $dominio -and $correo -and $gituser)) {
  Write-Host 'Quedaron marcadores sin completar: edita la seccion 0 de ~/.gemini/GEMINI.md.' -ForegroundColor Yellow
}
