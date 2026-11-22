# Kit de IA para Google Antigravity

Este paquete convierte a Antigravity en un agente que ya sabe **cómo trabajar**: reglas de método,
errores que no se deben repetir, soluciones que ya funcionaron, qué hacer cuando dices ciertas
frases, y 84 skills (diseño web, Cloudflare, SEO/GEO, ventas, video, depuración…).

Todo sale de cientos de sesiones reales haciendo webs, tiendas, paneles, campañas y videos para pymes.

## Instalación en un paso (recomendado)
Abre **PowerShell** y pega:
```powershell
irm https://raw.githubusercontent.com/rameseba/kit-antigravity-ia/main/bootstrap.ps1 | iex
```
Pregunta si instalar los programas, luego tus 4 datos, y deja todo listo. Después reinicia Antigravity.

### O pídeselo directo a Antigravity
Pega esto en el chat del agente (cambia tus datos):
```
Instala mi kit de reglas y skills. Ejecuta en la terminal de PowerShell este comando y espera a que termine:
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/rameseba/kit-antigravity-ia/main/bootstrap.ps1))) -Programas Base -Marca "MiEstudio" -Dominio "miestudio.cl" -Correo "contacto@miestudio.cl" -GitUser "miestudio" -Pais "Venezuela"
Luego lee ~/kit-antigravity-ia/README.md y dime que quedo instalado.
```
Después cierra y vuelve a abrir Antigravity para que cargue las reglas.

## Paso 0: programas (si el PC está recién formateado o no programa todavía)
```powershell
powershell -ExecutionPolicy Bypass -File .\programas\instalar-programas.ps1
```
Instala Git, Node, Python, Chrome, Vercel/Cloudflare CLI, Playwright y pregunta por lo opcional
(Docker, video, GPU NVIDIA). Next.js, Astro, Convex, etc. no van en el PC: se instalan dentro de cada
proyecto. Detalle en `programas/PROGRAMAS.md`.

## Instalación del kit (2 minutos)

### Windows
1. Descomprime el .zip en cualquier carpeta.
2. Abre PowerShell en esa carpeta y ejecuta:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\instalar.ps1
   ```
3. Responde 4 datos (tu marca, dominio, correo de trabajo y usuario de git). Si aún no los tienes,
   deja en blanco y edita después la sección 0 de `~\.gemini\GEMINI.md`.
4. Cierra y vuelve a abrir Antigravity.

### Mac / Linux
```bash
bash instalar.sh
```

Si tu versión de Antigravity es antigua y no ve las skills, reinstala con `-Legacy` (Windows) o
`--legacy` (Mac/Linux): las copia también a `~/.gemini/antigravity/skills/`.

El instalador **respalda** tu `GEMINI.md` y tus reglas anteriores (`.bak-<fecha>`) antes de copiar.

## Qué se instala y dónde

| Qué | Dónde | Para qué |
|---|---|---|
| `GEMINI.md` | `~/.gemini/GEMINI.md` | Reglas globales, siempre activas: idioma, forma de trabajar, verificación, seguridad, costos, memoria, WhatsApp, diseño, disparadores |
| 8 reglas temáticas | `~/.gemini/config/rules/` | Se activan solas según el tema (el agente decide): diseño web, depuración, config/avisos, propuestas/ventas, costos cloud, video/GPU |
| 84 skills | `~/.gemini/config/skills/` | Capacidades que el agente carga cuando la tarea lo pide |
| `leads.md` | `~/.gemini/memoria/` | Tabla de leads/clientes con fecha de seguimiento |

### Las reglas temáticas
- `web-diseno-y-frontend.md` — diseño sin «cara de IA», formularios chilenos, modales, CSS/JS, capturas.
- `depuracion-y-errores.md` — cómo depurar sin dar vueltas; bugs de iPhone/Safari ya resueltos.
- `config-y-avisos.md` — respaldar antes de comandos que reescriben `.env`; no alarmar sin evidencia.
- `propuestas-y-ventas.md` — cotizar con propuesta visual A/B + estudio de mercado; qué no decir.
- `costos-cloud.md` — presupuesto fijo en Cloudflare, topes diarios, pruebas solo en local.
- `video-gpu.md` — usar la tarjeta NVIDIA para render, voz y transcripción.
- `antigravity-herramientas.md` — navegador integrado para verificar, qué modelo usar, terminal, imágenes.
- `mis-reglas.md` — tus reglas propias; las agrega el agente cuando le enseñas algo. Nunca se pisan.
- `venezuela.md` — economía bimonetaria (tasa BCV, Ref. $ + Bs.), IVA/IGTF, facturación SENIAT, RIF/cédula,
  teléfonos +58 (0412/0422/0414/0424/0416/0426), estados y municipios, Pago Móvil, bancos, Zelle, Binance,
  Cashea, webs para internet lento. Con `-Pais Venezuela` queda siempre activa.

### Actualizar el kit (sin perder lo tuyo)
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/rameseba/kit-antigravity-ia/main/bootstrap.ps1))) -Actualizar
```
O dile a Antigravity «actualiza el kit». Reusa tus datos y **no toca** `mis-reglas.md`, `cerebro/reference/mis-*.md`
ni tus leads. Para solo ver si hay novedades: `-SoloRevisar`. Internet lento: `-Programas Liviano`.

### Plantillas (en `~/kit-antigravity-ia/plantillas/`)
- `sitio-pyme`: web de negocio lista para personalizar (tasa BCV automática, formulario +58 a WhatsApp, estados,
  tarjetas 2x2 en móvil, crédito en el pie). HTML/CSS/JS, sin instalar nada.
- `propuesta`: página para cotizar con muestras A/B, estudio de mercado y 3 precios.
No guardes proyectos dentro de `~/kit-antigravity-ia`: se reemplaza al actualizar. La skill `nueva-web` copia
la plantilla a `Documents`.

### Skills propias del kit
- `guardar-estado` — escribe `ESTADO.md` para cerrar el chat y retomar sin perder nada.
- `propuesta-visual` — flujo completo para responder un «cotízame».
- `nueva-web` — web nueva de punta a punta: plantilla → personalizar → repo → publicar → verificar.
- `publicar-cloudflare` — publicar gratis sin dominio (`*.workers.dev`), login con wrangler, dominio después.
- `conectar-github` — login con `gh`, identidad de git y repos privados automáticos.
- `investigar` — estudio de mercado (20 nacionales + 10 mundiales), precios del mercado, técnica y normas.
- `creativos-imagenes` — Pexels/Unsplash/Pixabay, Google Flow y Nano Banana, recortes, tamaños para redes.
- `motion-graphics` — reels y animaciones con Remotion o HTML + ffmpeg, voces venezolanas, subtítulos.
- `actualizar-kit` — novedades, actualización segura y respaldo privado de lo aprendido en GitHub.
- `cerebro` — base de conocimiento técnico (Astro + Workers, tiendas Next + Convex, Vercel, pagos
  Webpay/Mercado Pago/Flow, bots, Meta Ads, reels, WhatsApp con IA, auditorías) y cómo ir agregándole.

### Skills incluidas (de terceros, gratuitas)
- **Diseño:** `design-taste-frontend`, `impeccable`, `emil-design-eng`, `better-typography`,
  `motion-design`, `review-animations`, `explain-interface`, `modern-web-guidance`.
- **Calidad web / SEO:** `audit-website`, `seo-audit`, `web-quality-audit`, `web-perf`, `ai-seo`,
  `schema`, `cro`, `landing-page-conversion-audit`, `copywriting`.
- **Cloudflare:** `cloudflare`, `wrangler`, `cf-cli`, `workers-*`, `durable-objects`, `agents-sdk`,
  `frameworks-on-cloudflare`, `nextjs-on-cloudflare`, `cloudflare-email-service`, `turnstile-spin`, etc.
- **Ventas y negocio:** `estratega-propuestas`, `estratega-ofertas`, `analista-precios`,
  `director-financiero`, `deal-value-calc`, `sales-*`, `negotiation-concession-planner`.
- **Google:** `google-ads-api-*`, `google-analytics-data-api-basics`, `sign-in-with-google-web`,
  `server-side-conversion-tracking`.
- **Video:** `remotion-*`.
- **Método (superpowers):** `brainstorming`, `writing-plans`, `executing-plans`,
  `systematic-debugging`, `test-driven-development`, `verification-before-completion`,
  `requesting-code-review`, `receiving-code-review`, `using-git-worktrees`, `writing-skills`…
  Varias vienen marcadas para usarse **solo cuando las pides por nombre** (gastan más cuota).
- **Seguridad:** `skill-scanner` (revisar una skill antes de instalarla).

## Primeros pasos
1. Abre un proyecto y escribe: «lee las reglas y dime qué sabes hacer». Debe responder en español
   y nombrar las reglas.
2. Copia `plantilla-proyecto/AGENTS.md` a la raíz de cada proyecto y complétalo.
3. Cuando el chat se alargue, di **«guarda todo»**: queda `ESTADO.md` y puedes abrir un chat nuevo
   con «lee ESTADO.md y sigue».
4. Cada vez que el agente cometa un error que no quieres repetir, dile **«guárdalo en el cerebro»**
   o agrega una línea a `~/.gemini/GEMINI.md` con el porqué. Así el kit crece contigo.

## Frases que el agente ya entiende
| Dices | Hace |
|---|---|
| «guarda todo» / «continuamos después» | guarda `ESTADO.md` y avisa |
| «coti», «cotízale» | propuesta visual completa (A + B + estudio) |
| «audita», «revisa todo» | revisión exhaustiva por rondas |
| «sigue», «dale» | continúa sin volver a preguntar |
| «estoy en el teléfono» | trabaja solo y deja las dudas al final |
| «mensaje para X» | mensaje listo para WhatsApp en bloque de código |
| «usa subagentes» | recién ahí paraleliza |
| «hazme una web para…» | plantilla → GitHub → Cloudflare → verificada en vivo |
| «publícalo» | lo sube a `<proyecto>.<tu-subdominio>.workers.dev` |
| «investiga…», «busca fotos», «hazme un reel» | skills de investigación, imágenes y video |
| «recuerda esto siempre» | lo guarda en `mis-reglas.md` |
| «actualiza el kit» | trae la versión nueva sin pisar lo tuyo |
| «está feo», «cara de IA» | vuelve a las reglas de diseño y rehace |

## Notas
- Varias skills y archivos del `cerebro` nombran herramientas de otro agente (Claude Code: «Task»,
  «TodoWrite», «Agent», rutas `~/.claude`). Antigravity las interpreta como instrucciones de método;
  donde diga `~/.claude/skills` léase `~/.gemini/config/skills`.
- Los archivos del `cerebro` citan proyectos reales como ejemplos; las rutas de esa máquina
  (`Documents/<proyecto>`, `D:\...`) son de referencia, no existen en tu PC.
- Límite de Antigravity: 24 KB por archivo de reglas. Si agregas mucho a `GEMINI.md`, muévelo a un
  archivo nuevo en `~/.gemini/config/rules/` con su encabezado `trigger: model_decision`.
- Reglas de presupuesto (Cloudflare US$5/mes) y formularios chilenos vienen como ejemplo real:
  ajústalas a tu caso.
