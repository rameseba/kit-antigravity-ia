# Instala los programas y herramientas que usa el kit (Windows 10/11, requiere winget).
# Uso (PowerShell normal, NO hace falta admin; winget pedira permiso cuando lo necesite):
#   powershell -ExecutionPolicy Bypass -File .\instalar-programas.ps1
# Saltar preguntas e instalar todo: agregar -Todo
# Solo lo base, sin preguntas (util desde el agente): -SoloBase
param([switch]$Todo, [switch]$SoloBase)

$ErrorActionPreference = 'Continue'
function Preguntar($texto) {
  if ($Todo) { return $true }
  if ($SoloBase) { return $false }
  $r = Read-Host "$texto (s/n)"
  return ($r -match '^[sSyY]')
}
function Instalar-Winget($ids) {
  foreach ($id in $ids) {
    Write-Host "-> $id" -ForegroundColor Cyan
    winget install --id $id -e --silent --accept-source-agreements --accept-package-agreements
  }
}
function Refrescar-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host 'No esta winget. Instala "Instalador de aplicacion" desde Microsoft Store y vuelve a correr esto.' -ForegroundColor Red
  exit 1
}

# 1) BASE: lo minimo para programar con el agente
Write-Host "`n=== 1. Base para programar ===" -ForegroundColor Green
Instalar-Winget @(
  'Git.Git',                     # control de versiones
  'GitHub.cli',                  # gh: repos, PRs
  'OpenJS.NodeJS.LTS',           # Node + npm (Next, Astro, Vite, Convex, wrangler...)
  'Python.Python.3.12',          # Python para scripts, video, IA local
  'astral-sh.uv',                # gestor rapido de Python
  'Oven-sh.Bun',                 # runtime JS rapido (opcional en proyectos)
  'BurntSushi.ripgrep.MSVC',     # rg: busqueda rapida en codigo
  'Microsoft.PowerShell',        # PowerShell 7
  'Microsoft.WindowsTerminal',
  'Google.Chrome',               # navegador para pruebas y extension del agente
  'Notepad++.Notepad++',
  '7zip.7zip',
  'DEVCOM.JetBrainsMonoNerdFont' # fuente para la terminal
)
Refrescar-Path

# 2) CLIs globales de Node
Write-Host "`n=== 2. Herramientas de linea de comandos (npm) ===" -ForegroundColor Green
npm install -g vercel wrangler squirrelscan
# Next.js, Astro, Convex, Supabase, Tailwind, Remotion: NO se instalan globales.
# Se instalan dentro de cada proyecto con "npm install" (o se usan con npx). Ver PROGRAMAS.md.

# 3) Navegador para capturas y pruebas automaticas (Playwright)
Write-Host "`n=== 3. Playwright (capturas y pruebas en navegador) ===" -ForegroundColor Green
npx -y playwright install chromium

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
