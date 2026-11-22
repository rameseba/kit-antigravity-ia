# Checklist de auditoría de tiendas — base: pasapalos.cl (2026-10-08)
> **Qué es:** checklist para armar una tienda nueva desde la plantilla pasapalos.
> **Actualizado:** 2026-11-19


**Para qué sirve:** auditar las demás tiendas de la familia contra lo que ya se corrigió en
pasapalos.cl, que es la tienda MÁS corregida (decisión del usuario 2026-10-08: "luego trabajaremos
de base con esta"). Cada punto dice qué buscar, cómo detectarlo rápido y dónde quedó el arreglo.

- Repo base: `Documents/pasapalos-cl` (privado `michperdomo28/pasapalos-cl`). Linaje: clon limpio de
  **akim-pet-market-web** (Next.js App Router + **Supabase** + Vercel), Webpay → **Mercado Pago**.
  Los forks **Convex** (beauty-gang-world, piel-y-trigo, Games-god, criadero…) comparten la LÓGICA
  (checkout, cupones, correos, panel) pero no la capa de datos: adaptar los puntos de RLS/Supabase.
- Historial: 111 commits; 56 de arreglos (sec/fix/perf/a11y). Memoria del proyecto:
  `~/.claude/projects/C--Users-<USUARIO>-Documents-pasapalos-cl/memory/` (17 archivos, leer
  `project_pasapalos_auditoria_2026-10-08.md` y `..._handoff_opus.md` primero).
- Scripts reutilizables copiados al repo: `pasapalos-cl/scripts/auditoria/` (ver §K).

Leyenda: 🔴 crítico (dinero/datos/borrado) · 🟠 alto · 🟡 medio · ⚪ cosmético.

---

## A. Rutas API y Server Actions abiertas (lo más grave de la familia)
Regla: **todo `export` de un archivo `"use server"` es un endpoint público**, y toda `route.ts` sin
`validateServerSession()` está abierta. Inventario rápido (Node, en la raíz del repo):
contar por archivo `validateServerSession(`, `auth.getUser()`, `CRON_SECRET`, `rateLimited` y listar
los `export async function`. Revisar a mano cada una que dé 0.

- 🔴 `/api/upload/delete` **sin login** borraba cualquier foto de Cloudinary (el `public_id` se ve en
  la URL de cada imagen). → solo admin/owner + validar `public_id` con regex. (pasapalos 2d25de8)
- 🔴 `/api/upload/imagen` sin login: cualquiera subía a tu Cloudinary y elegía la carpeta (`userId`
  del form). → carpeta desde la sesión, solo `image/*` ≤ 6 MB, límite por IP. (2d25de8)
- 🔴 **Chat de soporte (Server Actions)**: `sendSupportMessageFromServer({senderId})` permitía
  escribir COMO EL STAFF en cualquier ticket (phishing a clientes); `createSupportTicketForGuest
  ({guestUserId})` copiaba teléfono/RUT/dirección de cualquier usuario al asunto y luego
  `fetchTicketByIdFromServer` lo devolvía; `fetchActiveTicketFromServer(userId)` = IDOR.
  → identidad SIEMPRE de `auth.getUser()`; helper `puedeUsarTicket()` (staff, dueño, o ticket de
  invitado por UUID); `notifyNewTicket` deja de exportarse; tope diario de tickets. (2d25de8)
- 🟠 `/api/support/notify` sin login mandaba correos al equipo con HTML sin escapar → retirada (410).
- 🟠 `/api/seo/indexnow` abierta → solo staff/cron.
- 🟠 Server Actions de correo/notificaciones (`sendOrderConfirmationEmail`,
  `createNewOrderNotificationsServer`): tomar datos del pedido en BD, solo pedidos < 30 min,
  una vez por pedido, cooldown. (2026-10-05)
- 🟡 `DELETE` de pedidos con `auth.getSession()` (no verifica el JWT) → `validateServerSession`.
- 🟡 Bypass de desarrollo por `referer` con `bypass_auth=true`: OK solo si está dentro de
  `NODE_ENV === 'development'`. Verificar en cada tienda.

## B. Dinero: checkout, pago y cupones
- 🔴 **Carrera webhook + retorno de la pasarela**: los dos leen "pendiente" a la vez y ambos
  descuentan stock, mandan correos y dan puntos. → reclamo atómico:
  `update({status:'procesando'}).eq('id').not('status','in','(procesando,enviado,entregado)').select('id')`
  y seguir solo si devolvió fila. (`src/lib/mercadopagoOrders.ts`, 2d25de8). Aplica igual a Webpay/Convex.
- 🔴 Comparar `payment.transaction_amount` con `order.total` antes de marcar pagado.
- 🔴 Precio, cantidad y despacho los decide el SERVIDOR: precios desde BD, **cantidad entera 1..500**
  (una negativa/decimal bajaba el subtotal), despacho por método+comuna desde settings, piso
  `subtotal − descuento máximo + despacho`. (`api/mercadopago/crear`)
- 🔴 `/api/orders/create` aceptaba `status:"procesando"` (= pagado) desde el navegador con total 0.
  → solo staff puede crear pagado. (2026-09-27)
- 🟠 Tope diario de pedidos (300/24 h) en crear y orders/create: sin él, un script vacía la cuota
  de correos (transferencia manda correo a cualquier dirección).
- 🟠 Textos libres recortados (dirección 200, comuna 80, comentarios 1000, nombre 150…).
- 🟠 Cupones: viven en tabla `coupons`, canje atómico con RPC `redeem_coupon` AL PAGAR (no al
  aplicar). El sistema viejo `settings.web_content.coupons` se marcaba usado desde el navegador y
  fallaba en silencio → todo cupón de un uso era infinito. Confirmar transferencia a mano en el panel
  TAMBIÉN debe canjear el cupón (`canjearCuponesDelPedido`). Cupones personales: dueño = sesión.
- 🟠 Cupón de reseña escrito en el sistema viejo → al cliente le llegaba un código que el checkout
  rechazaba. → `emitirCupon()` en tabla, uno por PEDIDO.
- 🟠 Bienvenida: no emitir a sesiones anónimas ni sin correo confirmado; índice único
  `coupons(user_id) where source='welcome'`.
- 🟡 "Pedido pagado" definido en 5 lugares con listas distintas → `src/lib/orderStatus.ts` único
  (`ESTADOS_PAGADOS`). El análisis sumaba estados que la pasarela nunca escribe → ventas en 0.
- 🟡 Productos de prueba `is_test` (solo visibles para admin vía `TestProductGuard`) exentos del
  mínimo de compra → permite PROBAR EL COBRO REAL con $50 + cupón personal de envío gratis.

## C. Base de datos / RLS (Supabase)
- 🔴 `profiles` editable por su dueño (política "update for owner") → el cliente se ponía
  `loyalty_points` y se llevaba el cupón del nivel máximo. → calcular desde `loyalty_events`
  (solo servidor) + trigger `security.protect_loyalty_columns`. Mismo riesgo con CUALQUIER columna
  sensible en `profiles` (rol ya tiene `protect_profile_role`).
- 🟠 `products.inventory_log` (ventas por producto + ids de pedido) legible por anon y metido en el
  HTML de /tienda vía `select("*")`. → columnas explícitas (`src/lib/productColumns.ts`) en TODAS las
  consultas públicas (tienda, categorías, ficha, favoritos, feeds Merchant) + `revoke select ... from
  anon; grant select (columnas) to anon`.
- 🟠 `settings` legible por CUALQUIER usuario autenticado (registro abierto): no guardar claves ahí.
- 🟡 Política de `notifications` "insert … `is_staff_v2(user_id)`": un cliente podía mandar avisos
  (con enlace) a un admin → solo self o staff.
- 🟡 Aviso al staff de pedidos por WhatsApp corría en el navegador: la RLS no deja leer perfiles del
  staff → nunca llegaba a la campana. → Server Action.
- Prueba rápida de RLS: script REST con la anon key contra cada tabla (`GET ?select=*&limit=3`)
  → debe dar 0 filas o 401 salvo catálogo/reseñas aprobadas. RPCs sensibles: `revoke … from anon`.
- SQL de referencia: `pasapalos-cl/supabase/migrations/<ID>_auditoria_endurecimiento.sql`.

## D. Inyección / XSS
- 🟠 JSON-LD con texto de usuarios (reseñas) dentro de `<script>`: `JSON.stringify(x).replace(/</g,"\\u003c")`
  (OJO: en el fuente va `"\\u003c"`; con una sola barra es un no-op).
- 🟠 Correos: escapar nombre de producto/variante/cliente (`escHtml` en `emailItemsTable`).
- 🟡 `dangerouslySetInnerHTML` de páginas legales: DOMPurify (actualizar a ≥ 3.4.16).

## E. Dependencias
- 🔴 next 16.2.x → 16.3.8+ (RCE en optimizador de imágenes/AVIF, SSRF, cache poisoning). Fijar exacta.
- 🟠 xlsx 0.18.5 (npm) vulnerable; la buena está en `https://cdn.sheetjs.com/xlsx-0.20.3/xlsx-0.20.3.tgz`.
- 🟡 `shadcn` CLI en devDependencies (traía express/MCP SDK a producción).
- Comando: `npm audit --omit=dev --json` y mirar `isDirect`.

## F. Rendimiento (meta PageSpeed móvil > 90)
- 🔴 **Escribir un store global (zustand) DURANTE el render** (`if(!initialized){useSettings.getState()
  .setLocalSettings(...)}`) → en navegación cliente (transición) React reinicia el render ~60 veces
  hasta su vencimiento de 5 s: "volver a Inicio tarda 5–6 s". Detectar: contar `createElement` durante
  la navegación (`scripts/auditoria/contar-render.cjs`): 61.311 nodos para ~1.000 finales. Arreglo:
  `useEffect`. 5.197 → 253 ms. (d546b62) **Buscar el mismo patrón en akim y TODAS las hijas.**
- 🟠 `experimental.inlineCss: true` (CSS de Tailwind ya no bloquea el primer pintado).
- 🟠 GA4 + GTM: cargar tras la 1ª interacción o 3,5 s (gtag encola en dataLayer desde el inicio).
- 🟠 Buscador (cmdk/radix) y carrito (base-ui) con `next/dynamic` y montados SOLO al usarse; precarga
  por intención (hover/touchstart/focus). NO precargar por tiempo: a los 6 s cae dentro de la ventana
  de TBT y la nota bajó de 76 a ~51.
- 🟠 `content-visibility:auto; contain-intrinsic-size:auto 900px` en secciones bajo el pliegue.
- 🟡 Foto LCP: `priority` + `fetchPriority="high"` explícito (Next 16 no lo marca solo).
- 🟡 Fotos propias en WebP 400/800 con loader propio.
- Medición: Lighthouse en el PC del usuario varía ±20 pts → usar **pagespeed.web.dev en Chrome**
  (pestaña nueva; si queda en segundo plano no dibuja: leer `document.body.innerText`).
  Resultado pasapalos: portada 92 / tienda 96 (a11y 100/97, BP 100, SEO 100, agentes 3/3).

## G. UX / bugs funcionales del cliente
- 🟠 `persist` de zustand guardaba `isCartOpen` → el carrito se abría solo al recargar cualquier
  página. → `partialize: s => ({ items: s.items })`.
- 🟠 Mínimo de compra solo se avisaba al tocar "Pagar" → aviso "te faltan $X" en el carrito.
- 🟠 Cerrar sesión borraba carrito y favoritos del servidor (sync con lista vacía) → `clearLocal()`.
- 🟠 Buscador sin normalizar tildes/ñ: "tequenos" daba 0 → `normalize()` NFD (src/lib/search.ts).
- 🟡 Restos de la plantilla: "dueños de mascotas", "Webpay", favicon/datos de Akim, `/nutricion` →
  grep `mascota|perro|gato|Webpay|akim` en src y en settings de la BD.
- 🟡 Móvil: tarjetas 2x2 SIEMPRE (queja n.º 1 del usuario); sin scroll horizontal.
- 🟡 Guía de entrega imprimible: `@page{margin:0}` (quita URL/fecha del navegador), una hoja,
  QR de Maps separado del QR interno, QR de recompra con utm.

## H. Accesibilidad
- 🟡 Slides ocultos con `aria-hidden` y links enfocables → `inert`.
- 🟡 Puntos de carrusel 8 px → área táctil 24 px.
- 🟡 `aria-label` del botón carrito contradecía el texto visible → texto visible `aria-hidden`.
- 🟡 Naranja #F26B1D sobre blanco = 3:1 → texto chico `#C2410C` (5,2:1) con regla CSS que excluye
  títulos (`:root:not(.dark) .text-pp-accent:not(h1 *, h2 *, h3 *, .font-display *)`).
- 🟡 Select y migas sin nombre accesible.

## I. SEO / GEO / AEO / Google
- JSON-LD: FoodEstablishment/Store (sameAs/hasMap con el GBP), Product con shippingDetails,
  BreadcrumbList, FAQPage, Recipe (imagen + `url` por paso `#paso-N` + keywords), BlogPosting.
- `llms.txt`, robots (agentes de IA SÍ pasan, ver tiendas-politica-bots), sitemap, IndexNow.
- Redirección de URLs mal escritas del blog (`slugParecido`), www → apex 308, restos viejos 308.
- Títulos ≤ ~60 y descripciones ≤ ~155 con INTENCIÓN DE COMPRA ("dónde pedirlos en Santiago").
- GA4: excluir `mercadopago`/`mercadolibre` en referencias no deseadas (si no, las ventas quedan
  "Unassigned"); CSP debe permitir `www.googletagmanager.com` en img-src y connect-src.
- Merchant Center: feed TSV `/api/seo/google-merchant` (columnas explícitas, `item_group_id` solo con
  tamaños reales), datos de atención al cliente, encuesta "Reseñas de Clientes en Google".
  Resultado: 38/38 aprobados, 132 clics gratis en 28 días.
- GBP: publicaciones 2/semana desde el blog (botón sin utm: Google los marca inválidos); al guardar
  ofrece copiar a otros perfiles → NUNCA.

## J. Correo, DNS, operación
- Resend con DKIM alineado; SPF; **DMARC `p=quarantine`** una vez confirmado que nadie envía como el
  dominio desde Gmail (buscar `from:contacto@dominio in:sent`).
- Cloudflare delante de Vercel: apagar "Email Address Obfuscation" (inyecta email-decode.min.js).
- Correo/dirección personal del usuario fuera de código, correos, og:image, políticas (regla global).
- GitHub Actions: `vigilancia-sitio.yml` (cada hora, abre issue "caida") y `respaldo-base.yml`
  (lunes, tablas por REST → artefacto 90 días; secret key `sb_secret_…` va SOLO en header `apikey`).
- Ley 21.719 (rige 1-dic-2026): política con base legal, transferencias internacionales, plazos y
  derechos (borrador en `pasapalos-cl/docs/privacidad-ley-21719-borrador.md`).

## K. Método y herramientas (lo que funcionó)
- Scripts en `pasapalos-cl/scripts/auditoria/`: `db.mjs` (lectura REST con service key desde
  `.env.local`), `rls-anon.mjs` (qué lee un anónimo), `contar-render.cjs` (detecta renders en bucle;
  en pasapalos ya corregido da ~190 ms y creados ≈ finales), `lh.sh` (Lighthouse N veces),
  `monitor-pedido.mjs` (vigila un pedido durante una prueba de pago real).
- Prueba de pago real: producto `is_test` $50 + cupón personal free_shipping → el usuario paga, Claude
  monitorea BD (estado, pago, stock, cupón, avisos) y Gmail.
- El dev local de pasapalos usa la BD de PRODUCCIÓN: no crear pedidos/tickets de prueba desde local.
- Clasificador de permisos bloquea: conexión pg directa, `git rm`, `gh secret set`, push de workflows
  sin OK explícito, edición DNS sin pedido explícito del usuario. Neutralizar archivos con Edit.
- Chrome real: pestaña en segundo plano no dibuja (screenshots en blanco/timeouts) → leer DOM por JS;
  en formularios de Google el 1er `type` tras cargar se pierde → verificar `value.length`.

## L. Cómo usar pasapalos como BASE de una tienda nueva (pendiente de planificar)
Partir de `pasapalos-cl` en vez de akim: ya trae MP, cupones en tabla, fidelidad segura, chat seguro,
panel QA'd, SEO completo, workflows y SQL de endurecimiento. Pasos a definir con el usuario:
quitar marca/datos (pasapalos, Michelle, tequeños), parametrizar contacto/zonas/rellenos, `.env`
nuevo, Supabase nuevo con las migraciones + SQL de endurecimiento, usuario invitado
`3f6dee20-…` creado en la BD nueva (si no, FK de pedidos de invitado falla).

**2026-11-19 · Tienda NUEVA → usar pnpm** (`pnpm import` desde el `package-lock.json` de pasapalos y commitear `pnpm-lock.yaml`).
Detalle y motivo en `sitios-astro-worker-patrones.md` → «Proyectos NUEVOS: usar pnpm».

## Pagos: Webpay + pasarelas configurables (desde 2026-11-19, pasapalos 92651f4)
- La plantilla trae Webpay Plus (Transbank REST), oculto en producción hasta tener claves. Activar: contrato Transbank del cliente → integrar/validar en validador.transbankdevelopers.cl (9 casos; reembolso parcial con CRÉDITO; logo 130x59) → Transbank manda Api-Key-Secret al contacto técnico (~1 día hábil) → Vercel env `WEBPAY_ENVIRONMENT=production`, `WEBPAY_COMMERCE_CODE`, `WEBPAY_SECRET_KEY`, `NEXT_PUBLIC_WEBPAY_ACTIVO=1` → redeploy → compra real $50 con producto `is_test` → desactivar producto. Actualizar textos públicos (/pagos, FAQ, legales, llms.txt) para nombrar Webpay.
- Ajustes › Pagos: activar/desactivar Webpay/MP/Transferencia con mínimo y máximo (`payment_config.metodos`). Recomendar máximo a MP (antifraude rechaza montos altos).
- MP: `buildPreferenceBody({ categoryId })` según rubro (home, fashion, others…).
