# Sitios Astro + Cloudflare Worker (no tiendas) — patrones verificados
> **Qué es:** ARCHIVO VIVO: patrones de sitios Astro/estáticos en Cloudflare Workers + precios vigentes.
> **Actualizado:** 2026-11-22


**ARCHIVO VIVO.** Sitios de servicio con reservas/panel sobre Astro + Worker + D1 (ricardo-paredes, abogada-migratoria…).
Cada entrada: fecha, repo, commit. Lo de tiendas va en `tiendas-*`.

## 2026-10-22 — ricardo-paredes (commits 5ab8b98 → 44e3476)

### Bilingüe sin duplicar páginas
- La versión en inglés debe usar los **mismos componentes** con `lang` (no una página aparte "resumida": el usuario la
  rechazó por "súper básica"). Contenido editable del panel: `traducir(cfg)` traduce solo lo que sigue igual al texto de
  fábrica; lo editado en el panel sale tal cual. El Worker decide idioma por ruta (`/en/…`) y pasa `lang` a los bloques.
- Islas (Preact): idioma desde `<html lang>`; `api.ts` manda `X-Lang: en` y el Worker traduce los errores
  (`mensajeEn()`: diccionario + regex, desconocido → genérico). OJO: respuestas 200/402 con texto (p. ej. resultado de
  tarjeta) también hay que traducirlas, no solo los throw. Fechas: formatear en el navegador desde ms, no usar textos del servidor.
- ids de sección traducidos + mapa ES↔EN para que el botón de idioma conserve la sección.

### Rendimiento
- `content-visibility: auto` en secciones de abajo = mitad del layout inicial en celular (medido CPU ×4: 868 → 457 ms).
  **NO** aplicarlo a secciones ANTES de un efecto que cachea posiciones (scroll-driven/canvas): cambian de alto al
  dibujarse y descuadran el cálculo (rompió el modo cine en celular). Usar `.efecto ~ .sec { content-visibility:auto }`.
- Animaciones SVG que corren fuera de pantalla (ondas de un pin de mapa) cuestan layout en cada cuadro.
- Escribir `textContent` en cada evento scroll aunque no cambie fuerza layout → escribir solo si cambia.
- Para encontrar la causa: traza con Playwright (`browser.startTracing`) + variantes de CSS inyectadas vía `page.route`
  (quitar una sección a la vez) y comparar mediana de 5 corridas. Mucho más fiable que adivinar.
- Pruebas de fps: si hay autoplay que mueve el scroll, el test de scroll manual debe pausarlo antes de medir
  (si no, mide dos cosas peleando y da falsa regresión).

### Cloudflare
- `public/_headers` con caché larga para `/_astro/*` (immutable 1 año) e `/img/*` `/video/*` (7 días): Workers Static
  Assets sirve `max-age=0` por defecto → cada visita revalida todo.
- La analítica gratis de CF (`static.cloudflareinsights.com` + connect a `cloudflareinsights.com`) se bloquea con CSP
  estricta: agregarla si se quiere.
- **503 en páginas con `Sec-Purpose: prefetch`** = Speed Brain de CF rechazando la precarga
  (`cf-speculation-refused: prefetch refused: disabled for worker requests`). Inofensivo; la navegación real da 200.
- **JS Detections** (`/cdn-cgi/challenge-platform/scripts/jsd/main.js`) en plan Free NO se apaga → Lighthouse
  "Buenas prácticas" queda en ~81 por "deprecations". No bloquea a nadie. Bot Fight Mode de rameseba.com ya está OFF.
- ⚠️ No poner un comentario `//` a mitad de una línea que tiene más elementos del array de la CSP: comentó `frame-src`
  y bloqueó el mapa de Google. qa-cliente lo detectó (error de consola) antes del deploy.

### Prueba controlada en producción (con permiso explícito)
- `herramientas/prod-reserva.mjs es|en`: UNA reserva por idioma en el último día disponible, nombre "Prueba Rameseba",
  notas "PRUEBA TÉCNICA", HAR + consola + capturas por paso + resumen de red; cancela al final desde "Mi reserva"
  (no tocar el panel de producción: entrar con contraseña ahí no corresponde). Encontró caché, CSP y contraste que
  las pruebas locales no veían.

### Dominios
- **tld-list.com puede mostrar precios falsos** (Sav .mx: decía $17.71/$24.44, real $50.93/$63.41). Verificar en la
  página del registrador o, para Cloudflare, en cfdomainpricing.com. Cloudflare vende .mx ($30.70) y .com.mx ($16.75)
  a costo desde oct-2025. Disponibilidad .mx: no hay RDAP; usar WHOIS TCP 43 a `whois.mx`
  ("No_Se_Encontro_El_Objeto" = libre).

### Pagos México (investigado 2026-10-22)
- Recomendado para persona física sin empresa: **Mercado Pago Checkout Pro** (tarjeta, OXXO, saldo MP, MSI).
  Comisión 3.49% + $4 + IVA al instante / 2.95% + $4 + IVA a 30 días. Stripe MX 3.6% + $3 + IVA. Conekta pide RFC.

## Cloudflare Workers + paneles PWA (desde 4. Sistema-inventario / POS, 2026-10-23/24, versiones 1.67–1.74)
- **Dos copias de React tras `pnpm install`**: un monorepo con dos apps (web 19.3.1, panel 19.3.0) metió DOS React en el
  paquete de Vite → «Invalid hook call» en íconos y pantalla rota en producción. Fix: `resolve.dedupe: ['react','react-dom',
  'react-router','lucide-react']` (NO `scheduler`: queda sin resolver). **Tras cada build, contar versiones**:
  `"19.3.` en `dist/assets/index-*.js` debe dar una sola. Commit 42ef67b.
- **Service worker stale-while-revalidate + «Recargar»**: si la versión guardada está rota, `location.reload()` vuelve a
  servir la misma (la nueva solo entra a la 2.ª recarga). El botón de error debe BORRAR la página guardada en Cache API
  antes de recargar, y el ErrorBoundary recargar solo una vez desde la red (guardia de 30 s). Commit 14d8dd4.
- **Cron de Cloudflare que deja de dispararse**: tras el incidente del 23-10 («missed Cron Triggers») el `*/15 * * * *`
  seguía registrado pero no corría (los diarios sí); `wrangler triggers deploy` no lo arregló (y exige que exista
  `assets.directory`: crear la carpeta vacía). Arreglo: expresión equivalente nueva `0,15,30,45 * * * *` (el handler
  acepta ambas). Vigilar con un `/api/estado` que mire la hora del último chequeo + GitHub Actions cada hora. Commit 667efa5.
- **Animación de entrada con `transform` atrapa a los `position: fixed` de adentro** mientras dura (hojas inferiores en
  móvil aparecen al final de la página). Usar `animation-fill-mode: backwards` y, para bloques con algo fijo, solo fundido:
  `.page > *:has(.fixed, [class*="max-xl:fixed"]) { animation-name: fade }`. Commit 4b314e3.
- **Píldora deslizante genérica** (menú, pestañas, selectores): un módulo con MutationObserver pone un `<span>` absoluto
  detrás del `[aria-current]` y lo mueve con `transform` + curva con rebote `cubic-bezier(.34,1.36,.5,1)`; medir con
  `offsetLeft/Top` (no `getBoundingClientRect`, que falla durante animaciones de escala). Commit 54a9dca.
- **Mudar de Next a un Worker liviano**: medir qué falta con un grep de los nombres de acciones en el paquete publicado vs
  la lista ya mudada; mudar acciones de una pantalla que sigue en Next NO acelera nada (hay que mudar la pantalla).
  Acciones que solo leen no deben disparar el «refrescar pantalla» global (cada búsqueda recargaba todo). Commits bd8afb7, 4b314e3.
- **Aviso «versión nueva» en una PWA con stale-while-revalidate** (1.77, commit 362e596): sin él, cada publicación se ve
  recién a la 2.ª apertura y el cliente reporta «me sale igual». La app compara su `index-<huella>.js` con el de la página
  publicada pedida con `fetch(..., {cache:'no-store'})` (un fetch normal no es navegación: el SW no le sirve la copia) y
  ofrece «Actualizar» (borrar la página guardada en Cache API + reload). No recargar sola (formularios/ventas a medias).
  **Mejor aún (1.78):** la página HTML de la app en el SW como RED PRIMERO con tope de 3 s (fallback a la guardada sin red,
  con 5xx o si tarda) + aplicar la versión nueva sola al cambiar de RUTA (no de filtros) + en `activate` recargar UNA vez las
  ventanas abiertas con el SW anterior (marca en la caché). El usuario no hace nada. Probar el SW con una caché falsa en vitest
  (`new Function('self','caches','fetch', sw)`).
- **Botón de acción en un panel lateral sticky** (1.76, commit 1fd02cb): `lg:sticky` sin alto máximo deja el final fuera
  de pantalla en laptops bajas; dar alto = pantalla − top real (medido) + scroll propio, y la fila del botón como hijo
  DIRECTO del panel con `position: sticky; bottom` (un sticky no sale de su contenedor).
- El panel de vista previa oculto (Claude Browser) no dibuja cuadros: animaciones y rAF quedan congelados; medir
  movimiento cuadro a cuadro en el Chrome real.

## 2026-10-25 — Clima-ven (sitio estático Node → dist/ en Worker, commit b9546d2)

- **Portada con video real en vez de 3D** (el cliente rechazó la escena Three.js "aire doméstico" y luego la cocina 3D):
  video vertical 576x1024 h264_nvenc cq34 (~1,7 MB) + póster AVIF 25 KB con `preload fetchpriority=high` (es el LCP);
  el video se asigna recién tras `load`, no en saveData/2G/3G/reduced-motion, botón pausa (WCAG 2.2.2), pausa fuera de
  pantalla. Escritorio: texto + tarjeta 9:16; móvil: video a sangre con degradado. Lighthouse móvil 91-92, escritorio 97.
  Gotcha: un loader genérico `video[data-src]` le puso `poster=undefined` al video del hero → 404 y LCP lento; acotar
  selectores (`.vid video[data-src]`). Gotcha CSS: `section{padding}` global se coló en el hero.
- **Tira de videos liviana:** `preload=none`, src solo si el video queda 0,5 s a la vista, sin autoplay en datos lentos,
  pósters WebP; tope 1 Mbps por clip.
- **Canonical en el Worker:** var `CANONICAL_HOST` → 301 de www, http y subdominio de prueba (excepto localhost/workers.dev).
- **Logo del cliente sobre negro → transparente** por brillo (`scripts/build-logo.py`: alpha = (max(rgb)-0.06)/0.30,
  des-premultiplicar) + íconos/og-image en el mismo script.
- Dominio, correo corporativo (Email Routing + Resend + Gmail) e indexación por DNS: ver supercerebro
  `patrones/SITIOS-LOCALES-ADS-GBP.md` (anexo 2026-10-25).

## 2026-11-06 — altagamaled-cl (tienda chica con panel KV, base estilograficoimpresores-cl)
- **Si el cliente aprobó una maqueta, la web real usa SU CSS tal cual** (portar tienda.css + estructura de HTML), no un
  «estilo parecido» sobre otra base: la v1 hecha sobre la base de otro cliente con colores cambiados fue rechazada.
- **Fotos de producto con fondo de bodega → «de estudio»**: rembg `isnet-general-use` (onnxruntime, sin torch) + recorte al
  objeto + lienzo 1200x1600 #efece7 con leve degradado + sombra de piso (máscara aplastada + GaussianBlur). Script:
  `altagamaled-cl/herramientas/_agl-estudio.py`. Las fotos de etiquetas/códigos se dejan originales.
- **Video de portada generado (Flow/Veo): revisar cuadro a cuadro con zoom** que el auto no tenga logos (salió estrella
  Mercedes + emblema BMW). Pedir «completely debadged, no logos, no emblems»; aun así 1 de 2 salió con logo.
- **Varios vendedores por WhatsApp:** listener en captura sobre `a[href*="wa.me/"]` → selector con los N números (leídos de
  `[data-n]`, así el panel/Worker los puede cambiar) que conserva el `?text=` (incluido el pedido del carrito);
  `data-directo` para enlaces que no deben pasar por el selector; con 1 número válido va directo.
- **Contraseña propia del cliente en un panel con secretos:** login acepta la temporal (secreto) solo mientras no exista KV
  `acceso`; al entrar con ella el panel abre un `<dialog>` que no se puede cerrar hasta crear la suya (PBKDF2-SHA256 100k
  con sal en KV). Olvido = borrar la clave `acceso`. Usuario simple (sin mayúsculas) y temporal corta: las largas fallan al copiar.
- **Ficha con tabla editable:** filas en un array común (`filas` en sitio.ts) que usan la ficha, el panel y el Worker;
  `[data-pf-fila]` con `hidden` si está vacía y CSS `div:not(:has(~ div:not([hidden])))` para el último borde.
- Contraste: gris `#6b6e74` sobre beige `#efece7` da 4,34 → usar `#5c5f65`. Medir con script (TreeWalker + color de fondo
  efectivo; ojo `color-mix()` devuelve `color(srgb 0..1)`).
- Windows: `taskkill /IM workerd.exe` mata los `wrangler dev` de otras sesiones → cerrar por PID del puerto y usar
  `--persist-to` propio.

## 2026-11-11 · Correos desde un Worker: `wrangler dev` con dominio propio ENVÍA DE VERDAD (ricardo-paredes)
Si wrangler.jsonc tiene `routes` con `custom_domain`, `wrangler dev` entrega el dominio REAL en `req.url`
(no localhost). Un "si es localhost no envíes" falla y las baterías de QA mandan correos reales por Resend
(pasó: ~73 correos de prueba, la mitad a la bandeja del cliente). Regla: interruptor explícito
`CORREO_MODO=simulado` en `.dev.vars` (no existe en prod), bloquear dominios de prueba (@prueba/@ejemplo),
y que las pruebas se nieguen a correr sin ese modo. Referencia: ricardo-paredes/servidor/correo.ts.
- **Recuperar contraseña del panel por correo (altagamaled-cl, 15-11, de6d8c3):** endpoints sin sesión `/api/admin/recuperar` (no revela si el usuario existe; tope 3 códigos/hora) y `/api/admin/restablecer` (código hasheado con SESSION_SECRET, 15 min, 5 intentos; deja sesión abierta). Correo de recuperación obligatorio al cambiar la temporal. Envío con Resend usando la key de rameseba.com (from no-responder@rameseba.com, sin verificar el dominio del cliente). Probar local con `--var MODO_PRUEBA:1` (devuelve el código) y `--var CANONICAL_HOST:` (si no, wrangler dev redirige en bucle al dominio de las rutas). Copiar a otros paneles KV (estilografico) cuando un cliente se bloquee.

## 2026-11-16 · Patrones sueltos de los sitios de noviembre (barrido de memorias)
- **`[hidden]` pisado por `display:grid` (la-cocina-gocha, 09-11):** una clase con `display:grid/flex` le gana al atributo
  `hidden` y el bloque nunca se oculta. Poner siempre `[hidden]{display:none!important}` en el CSS base.
- **www → raíz desde el Worker (Kokavee, 13-11):** Worker con `main: src/index.js` + `assets.run_worker_first`: www.dominio →
  301 a dominio; el subdominio `*.rameseba.com` queda de respaldo con `X-Robots-Tag: noindex`; el dominio real indexable
  (canonical, robots Allow, sitemap). En zonas propias también sirve una regla de redirección por zona (CRG la usó en vez del Worker).
- **Correo ofuscado por Cloudflare** también en sitios de clientes (daf-cl 10-11): `<!--email_off-->` en todo el body.
- **Email Routing hacia un correo del cliente:** la regla falla con error 2054 «Destination address is not verified» hasta que
  el cliente confirme el correo de verificación de Cloudflare (Kokavee admin@ → correo del cliente, pendiente).
- **Google Flow, método que funcionó (gocha 09-11):** subir referencia → «⋮ → Añadir a la petición» (si no: error «procesar la
  imagen de referencia») → pedir 1 primero y luego 10 en un mensaje → descargar por script (Más opciones → Descargar → 1K/2K).
  Subir archivo: crear `<input type=file>` con JS, `file_upload` y despachar `drop` sobre «Empieza a crear».
- **Material de Instagram del cliente:** `yt-dlp` baja reels sin login (snackaustral 13-11, 32 reels).
- **Web completa con reservas (Reino Kiwicha, 14-11):** Astro + Worker + D1 (esquema) + KV, abono por Mercado Pago con la
  cuenta del cliente, talleres con cupos, panel /admin, cron en el Worker, noindex fuera del dominio real. Mientras se construye,
  el dominio real sigue con el sitio «en construcción» (repo aparte) y al final sus rutas pasan al Worker nuevo.
- **Agente IA por WhatsApp, costos (Eproter 15-11):** Claude Haiku 5.5 ≈ US$0,0004 por respuesta → ~US$1/mes con 300
  conversaciones (Sonnet saldría ~US$18/mes: no usar para esto). Correos automáticos = Resend + cron del Worker; escrituras con
  tope diario. Precio: $150k instalación + $25k/mes; combo sistema $85k + agente = $220k.
- **Visor privado con contraseña sin KV (chats, 11-11):** Worker con login, secretos PASSWORD y SECRET, cookie firmada 30 días,
  noindex + robots Disallow, repo SIN git si el contenido es privado.

## 2026-11-16 · Precios y paquetes vigentes (memorias de rameseba, oct-nov)
- Web chica **$40k** (20 + 20; a veces «borrador gratis → 20 → 20»). **Web pyme $85k** = web + panel editable + SEO/AEO/GEO.
  **Google o Meta Ads $120k por plataforma SIEMPRE aparte** (15 días de administración, luego $80k/mes opcional); nunca dentro
  de un paquete web (el usuario se enojó en Contengo 09-11).
- Hosting: **$2.000/mes** (Email Routing, llega a su Gmail) o **$3.000/mes** (responde como contacto@dominio con «Enviar como» +
  SMTP). 1.er mes gratis; año completo $24k / $36k sin descuento.
- Tiendas: $150k (WhatsApp) / $250k (avanzada con pago). Nunca decir en la propuesta que es «parte de» otra web (suena a plantilla).
- Maquetas de propuestas: sistema hogarnuevavida.cl con colores del logo del cliente + fotos Flow 2K con su logo; NO las
  direcciones de galería del skill design-taste (William 03-11: «ahora está peor»).

## 2026-11-16 · interelectric-cl (Inter Electric, base estilograficoimpresores-cl)
- **Logo hecho con IA sobre fondo negro:** el método de alpha por brillo + des-premultiplicar vuelve GRISES los tonos marinos
  oscuros. Para logos con marino: `alpha = clip((max(rgb)-0.035)/0.07)` y conservar el color original (`herramientas/logo.py`).
- **Galería de trabajos editable:** KV `sitio.trabajos` = array {foto,titulo,lugar} o `null` (= los de fábrica); el Worker
  reemplaza el contenido de `[data-trabajos="N"]` con el mismo HTML que el componente Astro. El panel sube, ordena y titula.
- **Servicio oculto desde el panel:** todo enlace/tarjeta/botón con `data-srv` se borra con HTMLRewriter y la página da 404.
- Contenedores que el Worker puede llenar (galería de un servicio): renderizarlos siempre con `hidden`, no condicionalmente,
  o el HTMLRewriter no encuentra dónde escribir.
- **Dominio recién comprado (interelectric 17-11):** NIC delega en minutos, pero el certificado de Cloudflare sale recién
  cuando la zona pasa a activa. Si se publica con `CANONICAL_HOST` antes, el subdominio de prueba redirige a un dominio
  con error TLS. Publicar con `npx wrangler deploy --var CANONICAL_HOST:` hasta que `curl https://dominio` dé 200, y
  recién ahí el deploy normal. DNS locales/8.8.8.8 guardan el NXDOMAIN un rato: probar con `--resolve dominio:443:<ip>`.
- **Search Console de dominio:** elegir «Cualquier proveedor de DNS» y poner el TXT a mano en Cloudflare (no «Iniciar
  verificación», que pide autorizar a Google en la cuenta Cloudflare). El sitemap de una propiedad de dominio va con URL completa.

## 2026-11-17 — Interruptor de pago para webs en el hosting del cliente (cjovaeventos-cl, c510a56)
Política del usuario: si la web va al hosting/dominio del cliente antes de cobrar, **preguntarle siempre si se
pone** (él decide). El JS del sitio consulta `https://<cliente>.rameseba.com/estado.json` (Worker propio solo
assets; `_headers`: `Access-Control-Allow-Origin: *` + `Cache-Control: no-store`). Con `"activo": false` la página
se reemplaza por «Sitio temporalmente no disponible». `estado-sitio.ps1 activar|bloquear` = escribir estado.json
+ `wrangler deploy` (efecto en minutos). Si el Worker no responde, la web sigue viva. Subirlo antes de que el
cliente cambie su clave FTP. Probado en vivo en ambos sentidos el 17-11.

## 2026-11-17 · PANEL DE CLIENTE = el de Universidad-abierta-internacional (decisión del usuario)
El usuario vio el panel simple de interelectric (copiado de estilografico: pestañas + formularios) y dijo «qué sencillo, tiene
que ser como el de la Universidad Abierta Internacional, ese es un buen panel». **Todo panel nuevo parte de
`Documents/Universidad-abierta-internacional`**: `src/pages/admin.astro` (login con foto + menú lateral + inicio con cifras,
accesos rápidos e historial), `src/scripts/editor.ts` (modo edición sobre la propia web: clic en texto, «Cambiar foto»,
barra inferior, globos que mandan al panel), `scripts/marcar-editables.mjs` (en el build: `data-e` por hash del texto y
`data-e-foto` por nombre de archivo; `SALTAR_SEL` para lo que se maneja en pestañas propias) y en el Worker
`leerContenido / contenidoPublico / aplicarContenido / camposContenido` + `/api/admin/sesion` y `/api/admin/contenido`.
Port hecho en interelectric-cl (commit 1ab405b): ojo, si el sitio ya usaba `data-e` con claves fijas, quitarlas (chocan).

## Responsive: revisión automática y 3 bugs que se repiten (2026-11-17, ricardo-paredes f2d6570)
- Script reutilizable: `ricardo-paredes/pruebas/responsive.mjs` (Playwright, local): scroll horizontal, elementos fuera de pantalla, placeholder/valor de campos que no cabe (mide con canvas), texto cortado por overflow, botones partidos (cuenta líneas reales con Range), flotantes que tapan botones. Correr en 320/390/768/1024/1366.
- Texto `.sr` (position:absolute) dentro de un contenedor `overflow-x:auto` SIN `position:relative` se escapa y ensancha la página → poner `position:relative` al contenedor con scroll.
- Grillas de formulario con media queries por ancho de pantalla fallan cuando el formulario va en una columna angosta (1024 px) → `repeat(auto-fit, minmax(min(100%, max(250px, calc((100% - gap)/2))), 1fr))` (máx. 2 columnas, se apilan solas).
- Campo con prefijo (bandera +56) se come el número en columnas angostas → `container-type: inline-size` en la fila y modo compacto con `@container (max-width: 290px)`.
- Corte de layout panel/cajón: el fondo de la barra lateral y el cajón móvil deben usar el MISMO breakpoint (había franja negra entre 761 y 860 px).

## 2026-11-17 · DEMO FUNCIONAL de reservas con pago (propuesta-electrico, commit 8b5f69e)
Para leads que piden «reservas + pago»: en vez de capturas, una demo clicable dentro de la propuesta.
`Documents/propuesta-electrico/public/demo/`: `datos.js` (servicios, comunas, bloques de 3 h, reservas de ejemplo relativas a hoy,
localStorage solo de demo), `demo.js` (reserva 4 pasos con validación chilena, pago simulado MP/Webpay, .ics, modo `?editar`),
`panel.js` (panel estructura UAI: agenda semanal, reservas con estados pagada→confirmada→camino→terminada, «voy en camino» por
WhatsApp, reprogramar, precios, horarios/días bloqueados, pagos, clientes). La reserva hecha en la web aparece en el panel como NUEVA.
Motion sin «cara de IA»: título por palabras, foto que se revela una vez, cable SVG `pathLength=1` con dashoffset según scroll que
enciende los pasos. CSP de propuesta (script-src 'self'): nada de JS inline; íconos Phosphor como sprite (`demo-src/build-demo.js`).
Ojo: clase `.acc` de la web chocó con `.acc` del panel al compartir demo.css → prefijar clases del panel. Precio sugerido: $40k (agendar
por WhatsApp) / $85k (panel + calendario) / $150k (con pago online), confirmado por el usuario 17-11.

## Proyectos NUEVOS: usar pnpm, no npm (decisión del usuario, 2026-11-19)
Motivo: disco C: lleno. Con npm cada repo copia su `node_modules` (0,3-0,7 GB por sitio, 6,5 GB el POS) y hay 50+ repos en
`Documents`. pnpm guarda cada paquete UNA vez en un almacén global y lo enlaza en cada proyecto → ahorra GB y las
instalaciones son más rápidas.
- Aplica a repos nuevos, clones de una base y presupuestos/maquetas nuevas: `pnpm install`, `pnpm dev`, commitear `pnpm-lock.yaml`
  (no `package-lock.json`). Vercel y Cloudflare lo detectan solos por el lockfile.
- Repos existentes con `package-lock.json`: NO migrar de pasada; solo si el usuario lo pide (migrar = borrar lock y
  `node_modules`, `pnpm import`, probar build y deploy).
- Trampa ya vista con pnpm: monorepo con dos versiones de React (ver «Dos copias de React tras `pnpm install`» más arriba).
- No cambia precios ni paquetes: es solo cómo se trabaja en el PC.

## 2026-11-19 · REGLA propuestas: el wordmark gigante «rameseba» corta la última «a»
- En TODAS las propuestas (propuesta.css de la familia propuesta-contengo/kiwicha) el `.wordmark` del cierre corta el borde
  derecho de la «a» final: `letter-spacing:-.035em` + `background-clip:text` recortan el último glifo. El usuario lo notó (19-11).
- **Regla:** en cada propuesta nueva agregar
  `.wordmark{font-size:min(210px,17vw)!important;letter-spacing:-.02em!important;padding:0 .08em .06em!important;overflow:visible;white-space:nowrap}`
  y revisar con captura que la «a» salga completa en 1440 y 390. NO tocar las propuestas ya publicadas salvo que lo pida
  (corregido solo en propuesta-uniformes-ricardo, commit «wordmark sin la a cortada»).
- Mismo día: maqueta «tienda en su web» va en el marco de computadora `.stage > .screen#tilt > .clip > img` (+ `.screen .clip{height:auto!important}`),
  no en tarjeta chica; y propuestas con POCO texto (una línea por sección) — al usuario le da flojera leer.

## 2026-11-20 · Demo de reserva de horas para profesionales de salud (propuesta-psicologo)
`Documents/propuesta-psicologo/public/maqueta-comun/reserva.js` + `reserva.css`: se monta en cualquier `[data-reserva]`, toma colores de
`--ink/--muted/--accent/--line/--paper/--r` de la página. 4 pasos (modalidad presencial/online + quién consulta → día con nº de horas libres → datos con
validación chilena y motivo opcional confidencial → confirmación con .ics y aviso por WhatsApp). Horarios de ejemplo deterministas por fecha.
Reutilizable para psicólogos, nutricionistas, kinesiólogos, abogados. Precios ofrecidos: $40k (botón a su Google Calendar) / $85k (reserva propia + panel) / $150k con abono online.

## `wrangler dev` con assets: recompilar aparte deja la página en blanco (2026-11-21, POS 1.162)
Si el Worker sirve una SPA (`assets` / custom build) y se recompila el front MIENTRAS `wrangler dev` corre, puede seguir
entregando el `index.html` viejo que pide `index-<hash>.js` borrado → 404 y pantalla en blanco. Reiniciar `wrangler dev`.
Ojo en Windows: detenerlo desde la vista previa a veces deja vivo el `workerd` hijo ocupando el puerto (y colgado): usar
otro puerto (`--port`/`--inspector-port` distintos) en vez de pelear con el proceso.

## Límite de velocidad de Cloudflare en la zona rameseba.com (2026-11-21, POS 1.166)
- Hay UNA regla de rate limiting para TODA la zona (todos los sitios `*.rameseba.com`): «Limite por IP - evitar consumo excesivo»,
  120 solicitudes / 10 s por IP → bloqueo 10 s (Error 1015). Plan Free: periodo y bloqueo fijos de 10 s.
- Bloqueó a una tienda real del POS (Venezuela, varios equipos detrás de una IP) justo tras publicar: cada equipo bajaba ~60
  piezas de código de golpe. Arreglo: (1) la regla excluye archivos fijos: `/p/assets/`, `/_next/static/`, `/icons/`, `/sw.js`,
  `/manifest.webmanifest` (expresión `starts_with(...,"/") and not starts_with(...)…`; validó en Free); (2) en el código, las
  descargas en segundo plano van con pausa (300-400 ms entre piezas).
- Al agregar un sitio con muchos archivos sin huella fija, revisar que no choque con esta regla. Medir en producción con calma
  (una corrida por equipo): repetir mediciones seguidas desde la misma IP dispara el 1015.
- Ver eventos: Security › Analytics › Events (filtro país); mi IP de la PC de trabajo es de Chile (cambia).

## Worker con placement + archivos estáticos: servirlos desde el borde (2026-11-22, POS 1.171)
- Con `"placement": { "region": "aws:us-east-1" }` (Worker junto a la base) TODO lo que pasa por el Worker viaja a Virginia,
  también JS/CSS. Con `run_worker_first: true` los archivos fijos iban por el Worker: desde Chile ~0,1-0,4 s más por archivo.
- Arreglo: compilar en `dist/<prefijo>/…` (la URL coincide con el archivo), `"run_worker_first": ["/*", "!/p/*"]` y un
  `dist/_headers` (Workers Static Assets lo lee) con `Cache-Control: public, max-age=31536000, immutable` para los que tienen
  huella (`! Cache-Control` para quitar el no-cache general). Verificar en prod: `CF-Cache-Status: HIT`.
- Ojo local: `wrangler dev` con build propio puede leer la lista de archivos antes de terminar de compilar → 404 de todo;
  reiniciar (otro puerto si el workerd quedó colgado).

## Script en línea con CSP estricta: por huella sha256, nunca unsafe-inline (2026-11-22, POS 1.172)
- Un script chico que debe correr antes que todo (tema, pedir datos temprano) va DENTRO del HTML; el Worker calcula
  `crypto.subtle.digest('SHA-256', texto)` del contenido exacto de `<script>…</script>` y lo agrega a `script-src` (memo por texto).
- Ahorra un viaje entero (medido 0,19 s desde Chile). Si un script externo se reemplaza así, dejar el archivo viejo publicado:
  las páginas guardadas por el service worker lo siguen pidiendo.
- Ojo: si la página lista otros archivos JS (precargas), ningún otro trozo puede llamarse como el principal (`index-*`):
  todo código que busque «el principal» por nombre en el HTML se confunde.

## GEO/AEO: que las IA citen un sitio (deep research 2026-11-22, rameseba.com)
Informe completo: `Documents/investigaciones/reports/Visibilidad en IA para rameseba.md` (notas en `research_notes/`).
- NO publicar 3–4 posts/semana hechos con IA: Google castiga «scaled content abuse» (spam + core update mar-2026). Ritmo: 2 nuevas + 2–4 actualizaciones/mes.
- Pesa más FUERA del sitio: menciones de marca (corr. 0,66) y YouTube (~0,74) > backlinks (0,22) (Ahrefs, proveedor). Reseñas Google/Clutch/Sortlist, LinkedIn, YouTube con transcripción, Bing Places.
- AI Overviews/AI Mode citan ~76 % del top 10 de Google; ChatGPT/Claude/Gemini coinciden solo 4–13 % y prefieren terceros. Caer en Google baja citas en ChatGPT (~−28 %).
- Formato citado: respuesta corta arriba + tabla + «Actualizado el…» + FAQ + fuente oficial por cifra + autor Person. Datos chilenos propios (precios CLP, casos con números) = hueco libre.
- Bots: dejar OAI-SearchBot, Claude-SearchBot, PerplexityBot, bingbot (búsqueda); GPTBot/ClaudeBot son entrenamiento. Probar con `curl -A` que Cloudflare responda 200. llms.txt: 97 % sin tráfico, no invertir.
- Medición gratis: GSC informe «Generative AI» (solo impresiones) + regex en Rendimiento (consultas de 6+ palabras / qué|cómo|cuánto, sin `\b` con tildes), Bing Webmaster «AI Performance» (única fuente gratis de citas), GA4 canal «AI Assistant», preguntar «¿cómo nos encontraste?».
- Píxel de Meta inline choca con la CSP (Lighthouse BP 73): cargarlo solo donde se necesita o permitir por hash.
