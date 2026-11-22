# Programas y dependencias

Hay dos tipos de cosas que instalar:

1. **Programas del PC** (una sola vez): los instala `instalar-programas.ps1`.
2. **Dependencias de cada proyecto** (Next.js, Astro, Convex, Supabase, Tailwind, Remotion…): NO se
   instalan en el PC. Viven dentro de cada proyecto en `package.json` y se instalan con `npm install`
   al abrir o clonar el proyecto. El agente lo hace solo.

## 1. Programas del PC (`instalar-programas.ps1`)

| Grupo | Qué | Para qué |
|---|---|---|
| Base | Git, GitHub CLI (`gh`) | versiones, repos, PRs |
| Base | Node.js LTS + npm | todo lo de JavaScript: Next, Astro, Vite, Convex, wrangler |
| Base | Python 3.12 + uv | scripts, PDFs, video, IA local |
| Base | Bun | runtime JS rápido (algunos proyectos) |
| Base | ripgrep, PowerShell 7, Windows Terminal, Notepad++, 7-Zip, fuente JetBrains Mono | herramientas diarias |
| Base | Google Chrome | pruebas y extensión del navegador para el agente |
| npm global | `vercel`, `wrangler`, `squirrelscan` | publicar en Vercel / Cloudflare; auditoría de sitios |
| npx | Playwright + Chromium | capturas de página completa y pruebas automáticas |
| Opcional | cloudflared | túneles de Cloudflare |
| Opcional | Docker Desktop + WSL (tope 6 GB) | Supabase local y bases de datos de prueba |
| Opcional | ffmpeg, ImageMagick, OBS, HandBrake, VLC | video, reels, imágenes |
| Opcional | Python: yt-dlp, rembg, edge-tts, pymupdf, pypdf, python-docx, openpyxl, qrcode, matplotlib, vtracer… | bajar videos, quitar fondos, voz, PDF/Word/Excel, QR, gráficos, vectorizar |
| Opcional (NVIDIA) | faster-whisper, onnxruntime-gpu, cuBLAS/cuDNN | transcribir y quitar fondos con la tarjeta de video |
| Opcional | Oh My Posh, zoxide, Wispr Flow | terminal bonita, saltar carpetas, dictar por voz |

Después de instalar, iniciar sesión una vez:
```powershell
gh auth login
```
```powershell
wrangler login
```
```powershell
vercel login
```

## 2. Dependencias por proyecto (las instala el agente con `npm install`)

| Stack | Paquetes típicos | Cómo se crea un proyecto |
|---|---|---|
| Sitio rápido en Cloudflare | `astro`, `@astrojs/cloudflare`, `wrangler`, `tailwindcss` | `npm create astro@latest` |
| Tienda / app | `next`, `react`, `convex` o `@supabase/supabase-js`, `tailwindcss`, `shadcn` | `npx create-next-app@latest` |
| Backend en el borde | `wrangler`, `hono` | `npm create cloudflare@latest` |
| Video con código | `remotion`, `@remotion/cli` | `npx create-video@latest` |
| Base de datos local | Supabase CLI (`npx supabase start`, requiere Docker) / Convex (`npx convex dev`) | dentro del proyecto |
| Íconos / fuentes | `@phosphor-icons/core`, fuentes variables (Geist, Plus Jakarta Sans) | dentro del proyecto |
| Pagos Chile | `transbank-sdk` (Webpay), `mercadopago`, Flow por API | ver `cerebro/reference/tiendas-pagos-akim.md` |

## 3. Cuentas gratuitas que conviene tener
GitHub · Cloudflare (sitios y dominios) · Vercel (tiendas Next) · Convex o Supabase (base de datos) ·
Resend (correos) · Google Search Console · Pexels (fotos reales).
Regla del kit: presupuesto fijo y nada de productos de pago sin pensarlo (`costos-cloud.md`).

## 4. Opcional: conectar herramientas al agente (MCP)
Antigravity acepta servidores MCP (menú del agente → MCP / «Manage MCP servers»). Útiles:
Cloudflare (`https://mcp.cloudflare.com/mcp`), GitHub, Playwright (`npx @playwright/mcp@latest`),
Search Console (`npx search-console-mcp`). Agregar solo los que se usen: cada uno ocupa contexto.
