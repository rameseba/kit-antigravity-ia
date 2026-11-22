# Instala los programas y herramientas que usa el kit (Windows 10/11, requiere winget).
# Uso (PowerShell normal):
#   powershell -ExecutionPolicy Bypass -File .\instalar-programas.ps1
# Pide UNA sola vez permiso de administrador al inicio (ventana de Windows: hacer clic en "Si"),
# asi Git, Node, Python, etc. se instalan sin quedarse esperando a mitad de camino.
# -Todo: instala todo sin preguntar - -SoloBase: solo lo base, sin preguntas - -Liviano: base minima (internet lento)
param([switch]$Todo, [switch]$SoloBase, [switch]$Liviano, [switch]$SinElevar)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# 0) Un solo permiso de administrador para toda la instalacion
$esAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin -and -not $SinElevar) {
  Write-Host ''
  Write-Host '>>> Aparecera UNA ventana de Windows pidiendo permiso: haz clic en "Si". <<<' -ForegroundColor Yellow
  Write-Host '    (Si estas por escritorio remoto, mira la pantalla del PC.)' -ForegroundColor Yellow
  $argsHijo = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"")
  if ($Todo) { $argsHijo += '-Todo' }; if ($SoloBase) { $argsHijo += '-SoloBase' }; if ($Liviano) { $argsHijo += '-Liviano' }
  try {
    $p = Start-Process powershell -Verb RunAs -ArgumentList $argsHijo -Wait -PassThru
    Write-Host "Instalacion terminada (codigo $($p.ExitCode)). Abre una terminal nueva para usar los programas." -ForegroundColor Green
    return
  } catch {
    Write-Host 'No se dio el permiso: sigo sin administrador (algunos programas podrian pedirlo uno por uno).' -ForegroundColor Yellow
  }
}

function Preguntar($texto) {
  if ($Todo) { return $true }
  if ($SoloBase -or $Liviano) { return $false }
  $r = Read-Host "$texto (s/n)"
  return ($r -match '^[sSyY]')
}
function Instalar-Winget($ids) {
  foreach ($id in $ids) {
    winget list --id $id -e --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) { Write-Host "ya instalado: $id" -ForegroundColor DarkGray; continue }
    Write-Host "-> $id" -ForegroundColor Cyan
    winget install --id $id -e --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { Write-Host "   (no se pudo instalar $id; probar luego: winget install --id $id -e)" -ForegroundColor Yellow }
  }
}
function Refrescar-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host 'No esta winget. Instala "Instalador de aplicacion" desde Microsoft Store y vuelve a correr esto.' -ForegroundColor Red
  exit 1
}

# winget descarga MUY lento con Delivery Optimization en algunas redes: usar el descargador normal
try {
  $ws = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json'
  $j = if (Test-Path $ws) { Get-Content $ws -Raw | ConvertFrom-Json } else { [pscustomobject]@{} }
  if (-not $j) { $j = [pscustomobject]@{} }
  $j | Add-Member -Force -NotePropertyName network -NotePropertyValue ([pscustomobject]@{ downloader = 'wininet' })
  New-Item -ItemType Directory -Force -Path (Split-Path $ws) | Out-Null
  $j | ConvertTo-Json -Depth 10 | Set-Content $ws -Encoding UTF8
} catch { }

# 1) BASE: lo minimo para programar con el agente (Git primero: es lo mas importante)
Write-Host "`n=== 1. Base para programar ===" -ForegroundColor Green
$base = @(
  'Git.Git',                     # control de versiones
  'GitHub.cli',                  # gh: login, repos
  'OpenJS.NodeJS.LTS',           # Node + npm (Astro, Next, wrangler...)
  'Python.Python.3.12'           # Python para scripts, video, IA local
)
if (-not $Liviano) {
  $base += @(
    'astral-sh.uv',                # gestor rapido de Python
    'BurntSushi.ripgrep.MSVC',     # rg: busqueda rapida en codigo
    'Microsoft.PowerShell',        # PowerShell 7
    'Microsoft.WindowsTerminal',
    'Google.Chrome',               # navegador para pruebas
    '7zip.7zip',
    'Oven-sh.Bun',                 # runtime JS rapido (opcional)
    'Notepad++.Notepad++',
    'DEVCOM.JetBrainsMonoNerdFont' # fuente para la terminal
  )
}
Instalar-Winget $base
Refrescar-Path

# 2) CLIs globales de Node
Write-Host "`n=== 2. Herramientas de linea de comandos (npm) ===" -ForegroundColor Green
if ($Liviano) { npm install -g wrangler } else { npm install -g vercel wrangler squirrelscan }
# Next.js, Astro, Convex, Supabase, Tailwind, Remotion: NO se instalan globales.
# Se instalan dentro de cada proyecto con "npm install" (o se usan con npx). Ver PROGRAMAS.md.

# 3) Navegador para capturas y pruebas automaticas (Playwright, ~250 MB)
if (-not $Liviano) {
  Write-Host "`n=== 3. Playwright (capturas y pruebas en navegador) ===" -ForegroundColor Green
  npx -y playwright install chromium
}

# 4) Cloudflare
if (Preguntar 'Instalar cloudflared (tuneles de Cloudflare)?') { Instalar-Winget @('Cloudflare.cloudflared') }

# 5) Docker (bases de datos locales: Supabase local, etc.). Pesa y consume RAM.
if (Preguntar 'Instalar Docker Desktop + WSL (para Supabase local y bases de datos)?') {
  Instalar-Winget @('Microsoft.WSL','Docker.DockerDesktop')
  $wsl = Join-Path $HOME '.wslconfig'
  if (-not (Test-Path $wsl)) { Set-Content $wsl "[wsl2]`nmemory=6GB`n" ; Write-Host 'Tope de memoria WSL: 6 GB en ~/.wslconfig' }
}

# 6) Multimedia: video, imagenes, audio
if (Preguntar 'Instalar herramientas de video e imagen (ffmpeg, ImageMagick, OBS, HandBrake, VLC)?') {
  Instalar-Winget @('Gyan.FFmpeg','ImageMagick.ImageMagick','OBSProject.OBSStudio','HandBrake.HandBrake','VideoLAN.VLC')
}

# 7) Paquetes de Python
Refrescar-Path
if (Preguntar 'Instalar paquetes de Python (PDF, Word, Excel, fondos, descargas, voz, QR)?') {
  python -m pip install --upgrade pip
  python -m pip install yt-dlp rembg onnxruntime edge-tts pymupdf pypdf python-docx openpyxl qrcode matplotlib Markdown mss curl_cffi vtracer psd-tools svglib mutagen
}

# 8) GPU NVIDIA: transcripcion y quitar fondos con la tarjeta
$nvidia = (Get-CimInstance Win32_VideoController | Where-Object Name -match 'NVIDIA')
if ($nvidia -and (Preguntar "Se detecto $($nvidia[0].Name). Instalar aceleracion GPU (faster-whisper, onnxruntime-gpu, cuBLAS/cuDNN)?")) {
  python -m pip uninstall -y onnxruntime
  python -m pip install faster-whisper onnxruntime-gpu nvidia-cublas-cu12 "nvidia-cudnn-cu12==9.*"
  $sp = python -c "import site;print(site.getsitepackages()[-1])"
  $extra = @("$sp\nvidia\cublas\bin", "$sp\nvidia\cudnn\bin") | Where-Object { Test-Path $_ }
  if ($extra) {
    $u = [Environment]::GetEnvironmentVariable('Path','User')
    foreach ($e in $extra) { if ($u -notlike "*$e*") { $u = "$u;$e" } }
    [Environment]::SetEnvironmentVariable('Path', $u, 'User')
    Write-Host 'Agregadas DLL de CUDA al PATH de usuario (abre terminales nuevas).'
  }
}

# 9) Extras de comodidad
if (Preguntar 'Instalar extras (Oh My Posh, zoxide, Wispr Flow para dictar por voz)?') {
  Instalar-Winget @('JanDeDobbeleer.OhMyPosh','ajeetdsouza.zoxide','WisprFlow.WisprFlow')
}

Write-Host "`nListo. Cierra y abre la terminal para que tome el PATH nuevo." -ForegroundColor Green
Write-Host 'Comprobar:  node -v ; npm -v ; git --version ; python --version ; wrangler --version ; vercel --version'
Write-Host 'Luego inicia sesion una vez:  gh auth login ; wrangler login ; vercel login'
