## ⚠️ Patrón family-wide — un fallo al CONFIRMAR el pago no es un rechazo del banco (2026-08-24, `akim-pet-market-web` commit `78a4771`)
> **Qué es:** ARCHIVO VIVO: patrones de toda la familia de tiendas desde el 24-08.
> **Actualizado:** 2026-11-16


La clienta de Akim avisó que una venta **aprobada** mostraba en el panel:
`Error en commit de Transbank: Error al confirmar el pago con Transbank. Status: 422. |
Transbank Webpay Plus Aprobado. Tarjeta: Visa *******4153. Cod. Autorización: ...`.

**Causa (transferible a cualquier pasarela):** el mismo token se confirma DOS veces casi a la vez
—el POST de la pasarela al callback y la navegación del navegador—. La pasarela sólo permite UN
commit por token y responde **422** al segundo. El `catch` consultaba el estado real **una sola
vez**; esa consulta llegaba antes de que la confirmación paralela terminara, no veía `AUTHORIZED`,
y **cancelaba el pedido con una nota de error**. Medio segundo después el otro callback lo
aprobaba. La guarda que impide degradar un pedido pagado no cubre este orden (error primero,
aprobación después), y `updateOrderStatus` **concatena** notas con `" | "`, así que la nota de
error quedó pegada a una venta buena.

**Dos reglas que valen para toda la familia:**
1. **Un error de red/HTTP al confirmar es un estado INDETERMINADO, no un rechazo.** Consultar el
   estado real **con reintentos** (Akim: 3 × 1,2 s) hasta obtener un estado FINAL, y cancelar sólo
   ante rechazo explícito (`FAILED`/`NULLIFIED`/`REVERSED`/`response_code !== 0`). Si sigue
   indeterminado, dejar el pedido **pendiente** para el otro callback o el cron de reconciliación,
   y devolver al cliente un estado propio (`status=verificando`) con el aviso de **no volver a
   pagar** — nunca "rechazado", que empuja a pagar dos veces.
2. **Las notas de INTENTO no deben sobrevivir al resultado.** Al pasar el pedido a un estado
   pagado, descartar los segmentos de nota que empiecen por "Error en commit", "Transacción
   rechazada", "El usuario abortó el pago" (`pruneFailedAttemptNotes` en `src/lib/webpayOrders.ts`).
   Si no, el panel muestra un error en una venta cobrada y el dueño cree que algo falló.

**Chequeo en cualquier tienda de la familia:** en el manejador de retorno de la pasarela, buscar
todo `catch` que escriba estado "cancelado"/"rechazado" a partir de una **excepción de la llamada**
en vez de una respuesta explícita de la pasarela. Y `grep` de la concatenación de notas para ver si
mezcla intentos con resultado.

**Gotchas de esta sesión:**
- El `.env.local` de Akim tiene `SUPABASE_SERVICE_ROLE_KEY` **vacía** (largo 2 = `""`): vive sólo
  en Vercel/Supabase. Comprobarlo con el awk de largos antes de escribir un script que lea `orders`
  desde local — la anon key choca con RLS. La key se saca de supabase.com/dashboard → Project
  Settings → API Keys → `service_role`.
- **Al dar un comando con un valor a rellenar, el usuario pega el placeholder tal cual** (pasó con
  `PEGA_AQUI_LA_KEY` → 401 "Invalid API key"). Decir explícitamente que es un marcador, de dónde
  se saca el valor y que no lo pegue en el chat.
- **Verificar el deploy sin CLI de Vercel** (no está instalado en esta máquina):
  `gh api repos/{owner}/{repo}/commits/<sha>/status --jq .state`.
- `node -c ""` **cuelga** leyendo stdin en Git Bash; para validar sintaxis usar `node --check <archivo>`.

## ⚠️⚠️ Patrón family-wide — toda función de Convex que no sea `internal*` la puede llamar cualquier visitante (2026-08-26, encontrado y arreglado en `ua-antofa-cl`, commit `b7be75e`)

En el verificador de certificados de la UA, `informes:upsert` e `informes:seed` eran `mutation`
**públicas sin ninguna comprobación**. La URL de Convex viaja en el bundle del navegador, así que
cualquiera podía llamarlas — y `upsert` **sustituye por número**: bastaba mandar
`{numero:"77698-2", urlPdf:"<lo que sea>"}` para **reemplazar el archivo de un certificado real**.
En un sitio cuya única función es verificar documentos oficiales, eso es falsificación.
**Comprobado en producción**, no deducido: la inserción anónima devolvió `{"status":"success"}`.

Es el mismo error de fondo que los patrones ya registrados de "la censura vive en el server
action" y "el tope por IP vive en la ruta de Next": **lo que decide quién puede hacer algo tiene
que estar DENTRO de la función de Convex**. Aquí ni siquiera había nada fuera — la función estaba
al aire.

**Chequeo de 30 segundos para cualquier proyecto Convex (incluidas todas las tiendas):**
```bash
grep -rn "^export const" convex/*.ts | grep -v "internalMutation\|internalQuery\|internalAction"
```
Por cada resultado, preguntarse *"¿pasa nada si esto lo llama un desconocido con los argumentos
que quiera?"*. Las de alta/edición/borrado que no comprueben sesión van a `internalMutation` (se
siguen pudiendo llamar por CLI con `npx convex run`, que es para lo que suelen existir).
**Prueba en vivo desde la consola del navegador**, que es exactamente lo que puede hacer un
visitante:
```js
fetch('<convex-url>/api/mutation',{method:'POST',headers:{'content-type':'application/json'},
  body:JSON.stringify({path:'modulo:funcion',args:{},format:'json'})}).then(r=>r.text()).then(console.log)
```
`Could not find public function` = cerrada. Cualquier otra cosa = alcanzable desde fuera.
**Ojo:** las funciones de siembra/migración (`seed`, `backfill*`) son las que más se olvidan, y
son justo las que borran o rellenan tablas enteras.

**Corolario del mismo caso — el bloqueo por fuerza bruta no sirve si el aviso no llega.** Al
añadir el bloqueo tras 5 contraseñas fallidas, el panel seguía mostrando el genérico *"No se pudo
iniciar sesión"*: Convex sustituye el mensaje de todo error que no sea `ConvexError` por
`"[Request ID: …] Server Error"`, y el texto viaja en **`err.data`**, no en `err.message`. Ya está
registrado más arriba para las tiendas; **volvió a aparecer en un proyecto distinto del linaje**,
así que conviene comprobarlo en cualquier backend Convex nuevo: `grep -rn "throw new Error" convex/`.

## 2026-09-05 · pasapalos-cl · rebranding completo desde akim (commits 0b8eff1 → 9f45bec)
Patrones family-wide confirmados en producción (detalle en memoria del proyecto `project_pasapalos_handoff_opus.md`):
- **Tokens propios `--pp-*` mapeados a las vars shadcn** (`--primary`, `--secondary`, `--border`…) en globals.css: toda la app hereda la paleta sin tocar cada página. Tema oscuro con `.dark` + script inline en `<head>` (sin parpadeo) + toggle con localStorage.
- **Utilidades custom en `@layer utilities` van después de Tailwind y ganan**: nunca poner `position` en ellas (rompió fotos absolutas).
- **Zustand persist (carrito/favoritos) → `useMounted()` antes de renderizar estado**; si no, hydration mismatch en cada tarjeta y destello "carrito vacío" en checkout.
- **Sheets/Dialogs de Base UI deben estar montados siempre** (no `{open && <Sheet/>}`): la animación de salida se pierde.
- **`images.loader: 'custom'` desactiva `/_next/image`**: fotos locales se sirven tal cual → comprimirlas (sharp, 1000px q80).
- **Helpers usados por server y client** en `src/lib/`, jamás en archivos `"use client"` (rompe el prerender).
- **Lucide ≥ 2026 no trae íconos de marca** (Instagram/Facebook): SVG inline propio.
- **Reemplazos masivos de marca**: excluir `src/app/admin`, `actions`, `api`; verificar con `git diff --stat`.
- **QA con Claude Browser**: pane oculto = screenshots blancas; validar por DOM (`naturalWidth`, `nextjs-portal` issues) y con viewport alto en vez de scroll.

## 2026-09-05 · pasapalos-cl · buscador y analítica propia (commit b670bc1)
Patrones reutilizables para toda la familia de tiendas:
- **El buscador heredado de akim falla con ñ y tildes**: "tequenos" daba 0 resultados. Solución: `normalize()` con NFD + quitar diacríticos antes de comparar. Revisar esto en cualquier tienda con nombres acentuados.
- **Un solo motor de búsqueda** en `src/lib/*` compartido por el buscador del header y el filtro de la tienda; si están duplicados, dan resultados distintos para la misma palabra.
- **Fonética española barata** (ll→y, qu→k, c(ei)→s, v→b, h→∅) + Levenshtein acotado cubre los errores de tipeo reales sin meter Fuse.js.
- **Bonus de precisión** `40 * (tokens que calzan / palabras del nombre)`: hace que "queso" traiga "Pastel de Queso" antes que "Pastel de Maíz, Queso y Tocineta".
- **Analítica propia sin depender de GA4**: tabla de eventos con RLS que NO da insert a anon; se escribe solo por Route Handler con service role, validando tipo de evento y limitando por IP. `sendBeacon` para no frenar la navegación.
- **`add_to_cart` se instrumenta en el store de zustand** (`addItem`), no en cada componente: es el único punto por donde pasan tarjetas, ficha y favoritos.
- **`product_view` va en cliente**: con ISR el servidor no ve cada visita.
- **Route Handler cacheado**: no leer `request.url` si quieres `revalidate`; cualquier query param vuelve la ruta dinámica y pierde el cache.
- **"Buscaron y no encontraron"** es la métrica más valiosa para un catálogo chico: dice qué producto sumar.

## 2026-09-05 · pasapalos-cl · legales de comida y blog SEO (commits ce4c2a0, 5692f67)
- **Venta de alimentos en Chile**: el derecho a retracto de 10 días (art. 3 bis Ley 19.496) SE PUEDE excluir si se informa expresamente en la oferta, y para alimentos congelados corresponde hacerlo. Lo que NO se puede excluir es la garantía legal por producto equivocado, incompleto o en mal estado. Redactar las dos cosas por separado, nunca "no aceptamos devoluciones" a secas.
- **Nunca escribir "no recolectamos datos"** si el checkout pide nombre, teléfono, dirección y RUT. Lo correcto es "solo pedimos lo necesario para entregarte el pedido" y aclarar aparte que los datos de tarjeta los procesa la pasarela.
- **Blog como datos tipados en TS, no Markdown**: sin dependencias (gray-matter, remark) y el mismo objeto alimenta la página y el JSON-LD. Para recetas, el schema `Recipe` es el que consigue resultados enriquecidos en Google; `FAQPage` es el que citan los asistentes de IA.
- **Datos de contacto en una sola constante** (`CONTACT`): en pasapalos había teléfono y dirección repetidos en 14 archivos, incluidos correos transaccionales y checkout. Cambiar un número tocó 14 archivos.
- **Cuidado con los horarios heredados del negocio anterior**: el sitio prometía "compra antes de las 13:00 y lo recibes mañana" cuando el negocio real trabaja con 48-72 horas. Confirmar horarios reales antes de dar por bueno el copy clonado.

## 2026-09-07 — pasapalos-cl: React 19.2 NO hidrata en pestañas ocultas (falsos positivos al probar)
Repo `pasapalos-cl` (Next 16.2.6 / React 19.2.4). `$RC` encola los límites de Suspense como `<!--$~-->`
y `$RV` los revela con `requestAnimationFrame`; en una pestaña en segundo plano rAF nunca dispara →
la página no hidrata → todos los `<Link>` son `<a>` planos → cada clic es recarga completa.
Síntoma engañoso: "la navegación tarda 5 s" medido desde Claude-in-Chrome/Claude Browser con la
pestaña oculta. Para probar en pestaña oculta: ejecutar
`window.requestAnimationFrame=(cb)=>setTimeout(()=>cb(performance.now()),16); if(Array.isArray($RB)&&$RB.length)$RV($RB);`
Aparte, mejoras reales aplicadas: prefetch activado en nav/logo/pie (estaba `prefetch={false}`),
Navbar deduplicando `setUser` (6-8 consultas a `profiles` por página) y `src/lib/toast.ts` para
reemplazar 170 `alert()` de golpe (regex `(?<![\w.])alert\(` + import automático).

## Cupón BYPASS / "Pedido en $0": NO es una falla (2026-09-27, pasapalos-cl)
Toda la familia akim trae el código maestro `BYPASSWEBPAY` (tipo `bypass`, "Pago de Pedido Falso").
Es una herramienta de pruebas del dueño: su consola vive en admin → Ajustes → Cupones y **solo la
ve/usa el rol Owner**; el checkout lo rechaza a quien no es staff. Que el código aparezca en
`settings.web_content.coupons` (legible) NO lo vuelve explotable. **No reportarlo como hueco ni
proponer borrarlo** — el usuario lo corrigió explícitamente.
Lo que SÍ era falla (distinto): `/api/orders/create` aceptaba `status:"procesando"` (= pagado) si el
POST traía `total: 0`, sin pasar por la UI. Fix pasapalos e893d0a: solo staff crea pedidos pagados.
Revisar ese endpoint en los otros forks antes de afirmarlo.

## CSP en Cloudflare Pages con dominio propio (2026-09-28, Barberia-cl f38267b..)
En el DOMINIO propio (no en *.pages.dev) Cloudflare inserta Web Analytics (static.cloudflareinsights.com +
connect a cloudflareinsights.com) y un script anti-bots inline que cambia en cada respuesta → no se puede
autorizar por hash: script-src necesita 'unsafe-inline'. Probar la CSP en el dominio real, no solo en la vista previa.
Otros hallazgos QA reutilizables: abono en línea pagable dos veces (revisar abono_pagado, no solo pagada);
`seccion in OBJ` deja pasar __proto__/constructor (usar Object.hasOwn); confirmar transferencia 2 veces duplicaba pago.

## 2026-10-02 — ISR Writes del plan Hobby (cupo 200K/mes COMPARTIDO por toda la cuenta Vercel)
Llegó a 179K/200K: akim 53K, beauty-gang 48K, imperio-morales 44K, ketalnetwork 21K, truckdiesel 12K.
Causa: fichas con `revalidate` 1 h (o `cacheLife` 60 s en beauty-gang) + bots visitando todo el día → regeneración constante; cada regeneración escribe página + cada `unstable_cache`/`use cache`.
Patrón aplicado (akim 65d6b20, imperio a33aa50, beauty 216ee60): caché 1 día + invalidación al instante con `revalidateTag(tag, { expire: 0 })` en TODO punto que cambie stock/precio/reseñas (admin guardar/borrar, webhook de pago, cancelar/restaurar stock, importar pedidos, aprobar reseña).
Trampa: `revalidatePath` NO limpia `unstable_cache` con tag → precio viejo hasta que vence el tag. Y el perfil `"max"` deja que el primer visitante vea la versión vieja.

## 2026-10-05 — Escritura directa en la BD = caché vieja en producción (pasapalos-cl 13bc899)
Al cambiar `settings` (zonas de despacho) con un script directo a Supabase, el `unstable_cache(['global-settings'])` siguió sirviendo la config vieja: el checkout mostraba despacho fijo $3.000 mientras `/api/mercadopago/crear` (lee la BD directo) exigía $6.500 → un cliente de comuna lejana NO habría podido pagar.
Regla: después de todo script que escriba `settings`/`products`, llamar `POST /api/revalidate` (sesión admin o `Bearer $CRON_SECRET`) y comprobar en el HTML de producción. Y si el servidor valida montos contra la BD, el cliente debe leer la misma fuente (o invalidar) o se rompe el pago.
Otros hallazgos del mismo día, aplicables a la familia: (1) `api/admin/pedidos/importar` insertaba columnas que `orders` no tiene (notes, shipping_address, tracking_number) → la venta manual fallaba siempre; van en `items.metadata`. (2) Confirmar pago a mano (pendiente→procesando) no descontaba stock ni aplicaba fidelidad: solo lo hacía el webhook. (3) Correos y panel con "Despacho: Gratis" escrito fijo; despacho real = total − productos.

## 2026-10-08 — Auditoría completa pasapalos-cl → CHECKLIST para toda la familia
Todo quedó destilado en `~/.claude/cerebro/tiendas-checklist-base-pasapalos.md` (leerlo antes de
auditar cualquier tienda). Lo más importante, que probablemente está en akim y sus hijas:
1. **Store global escrito durante el render** (`if(!initialized){ useSettings.getState().setLocalSettings(...) }`
   en `LandingPageClient`) → volver a Inicio tarda 5-6 s (React reinicia la transición ~60 veces).
   Detectar con `pasapalos-cl/scripts/auditoria/contar-render.cjs <url> tienda Inicio`. Fix: useEffect (d546b62).
2. `/api/upload/delete` y `/api/upload/imagen` SIN LOGIN (borrar/subir a Cloudinary) — heredado de akim (2d25de8).
3. Chat de soporte: Server Actions que confían en `senderId`/`userId`/`guestUserId` del cliente →
   suplantar al staff y leer PII ajena (2d25de8).
4. Carrera webhook + retorno de la pasarela (stock/correos/puntos duplicados) → reclamo atómico del estado.
5. `profiles.loyalty_points` editable por el cliente (RLS update-own) → cupón de nivel máximo (80233a5).
6. `select("*")` público expone `inventory_log` (ventas + ids de pedido) en el HTML (af48253).
7. `persist` de zustand guardando `isCartOpen` → carrito se abre solo al recargar (03e195b).
8. next 16.2.x con RCE crítico → 16.3.8; xlsx desde cdn.sheetjs.com.
Resultado pasapalos tras todo: PageSpeed móvil portada 92 / tienda 96, pago real de $50 verificado
de punta a punta, 0 vulnerabilidades altas en código del sitio. Decisión del usuario: pasapalos = BASE
para próximas tiendas y patrón contra el cual auditar las demás.

## REGLA (2026-10-13, pasapalos-cl 9b7e8fc): CSS de clientes separado del CSS del panel admin
Tailwind v4 genera UN solo CSS con las clases de TODO `src/` → el cliente descarga las del panel
admin en cada página (pasapalos: 188 KB, el 33 % era del panel). Pedido explícito del dueño: la
tienda y el admin llevan CSS distintos, siempre.
- `src/styles/tokens.css`: `@custom-variant dark` + `@theme inline {…}` (tokens de marca), compartido.
- `src/app/globals.css`: `@import "tailwindcss"; …; @import "../styles/tokens.css";` +
  `@source not "./admin"; @source not "../components/admin"; @source not "./api";` +
  `@source not "../components/ui/<x>.tsx"` para los ui que solo usa el panel (checkbox, dialog,
  select, tabs, textarea en pasapalos — verificar con grep en cada tienda).
- `src/app/admin/admin.css` importado en `admin/layout.tsx`, SIN preflight (repetirlo después
  pisa `border-color` y fondos de la tienda):
  `@layer theme, base, components, utilities; @import "tailwindcss/theme.css" layer(theme);`
  `@import "tailwindcss/utilities.css" layer(utilities) source(none); @import "tw-animate-css";`
  `@import "shadcn/tailwind.css"; @import "../../styles/tokens.css"; @source "./"; @source "../../components/admin"; …`
- `experimental.inlineCss` → **false**: Next 16 mete el CSS en el HTML Y lo repite en el payload
  RSC (portada 626 KB de HTML → 231 KB al apagarlo; Lighthouse igual o mejor, y el CSS queda en caché).
- Al terminar: `npm run build` y medir `.next/static/chunks/*.css` (el que tiene `box-sizing:border-box` es el de clientes).

## RENDIMIENTO Y PANEL — pasapalos-cl, 13/14-10-2026 (commits ef8254b…0773168). PASAPALOS REEMPLAZA A AKIM COMO PLANTILLA
Decisión del dueño (14-10): **pasapalos-cl sustituye a akim-pet-market-web como base de futuras tiendas.**
Tienda nueva = clonar pasapalos (no akim), quitar marca/productos, aplicar checklist `tiendas-checklist-base-pasapalos.md`.
Resultados medidos (Lighthouse móvil local): portada 87-95, ficha 97, tienda 76→91, checkout 66→92-95, blog 90;
panel `/api/admin/*` 0,75-1,4 s → 0,32-0,42 s; lista de productos del panel 4,1 s → 0,8 s.

### Patrones (aplicar en toda tienda)
1. **useSearchParams en página estática = HTML vacío.** Todo lo bajo el mismo Suspense se dibuja en el navegador
   (`BAILOUT_TO_CLIENT_SIDE_RENDERING` en el HTML). Y si la página envuelve el cliente en `<Suspense>`, el contenido
   llega en `<div hidden id="S:0">` y React lo revela con un script tardío (LCP esperando; en pestaña oculta nunca).
   Fix: componente `ParamsSync` que lee `useSearchParams` dentro de SU PROPIO `<Suspense fallback={null}>` y pasa
   `sp.toString()` al padre por estado; quitar el Suspense externo. Detectar: `curl … | grep 'div hidden id="S:'`.
   Pasar al cliente solo los campos que usa la tarjeta (el catálogo viaja 2 veces: markup + payload RSC).
2. **Lighthouse: mirar `metrics.observedLargestContentfulPaint`** además del simulado; si el observado es rápido y el
   simulado lento, buscar bloques ocultos/reveal o recursos tempranos, no "optimizar imágenes" a ciegas.
3. **SDK Supabase perezoso** (`src/lib/supabaseLazy.ts`: `getSupabase()`, `hasAuthCookie()`, `onSupabaseReady()`,
   `selectPublic()` por fetch a PostgREST). Invitado sin cookie `sb-*-auth-token` no descarga los ~54 KB gzip.
   En checkout: `getSessionLazy()` devuelve sesión null sin bajar el SDK.
4. **Checkout con esqueleto útil en el HTML** (`CheckoutShell`: Navbar + h1 + párrafo de condiciones + esqueleto)
   como fallback de Suspense y mientras `!hasMounted`. Sin esto: spinner + pantalla blanca (LH 66).
5. **Admin rápido:** `validateServerSession` con `supabase.auth.getClaims()` (verifica JWT ES256 en local, sin viaje
   a Auth; confirmar claves en `/auth/v1/.well-known/jwks.json`) + caché de perfil 60 s por instancia (Map). Rol en
   `sessionStorage` (`pp_rol_v1`) revalidado por detrás; layout del panel monta la página tapada (overlay, `main inert`)
   en vez de bloquear; `router.prefetch` al hover/touch del menú; caché de módulo (`let cacheX`) por sección.
6. **Región:** Supabase us-west-2 → `vercel.json` `"regions": ["pdx1"]` (las funciones iban en iad1, +70 ms por consulta).
7. **Búsquedas analíticas:** registrar solo el término final (`createSearchLogger` en `src/lib/track.ts`: al elegir,
   cerrar, `pagehide` o 4 s quieto). Con debounce de 1,2 s se guardaban fragmentos ("teq").
8. **PWA con protagonismo:** `InstallAppCard` + `INSTALL_PROMPT_SCRIPT` inline en `<head>` (captura
   `beforeinstallprompt` antes de hidratar). Android: botón nativo; iOS: pasos Compartir → Agregar a inicio; oculto si
   `display-mode: standalone`. Va en comprobante, mis pedidos, consulta de invitado y pie (cerrable).
9. **Ficha producto escritorio:** foto `md:items-start md:sticky md:top-28` (centrada en vertical dejaba hueco enorme
   junto a columnas altas de variantes/rellenos).
10. **Cloudflare delante de Vercel:** NO cachear HTML en el borde (sin Skew Protection, HTML viejo pide chunks borrados
   tras deploy; purgar en cada deploy exige token en CI). Ganancia ~90 ms no lo justifica.

### Restos de akim (mascotas) que hay que limpiar al clonar — encontrados en pasapalos
- Editor de producto: "formato" obligatorio (bloqueaba guardar stock), SKU, ingredientes, ficha nutricional,
  "compromiso"; parser de peso solo Kg/gr (guardaba "350 Unidades" como "350 Kg"). Categorías fijas por tienda.
- Editar web: secciones que la portada no lee (textos del héroe, "Guía de nutrición", beneficios+QR, textos del pie).
  Regla: el editor solo muestra campos que algún componente público lee (`grep web_content` antes de dejar uno).
- Análisis: `orders.items` es objeto `{metadata,…}` → leer con `decodeResilientOrder` (si no, "vendidos" = 0);
  quitar embudo/distribución/"riesgo de fuga" si no hay datos de carrito de invitados.
- Usuarios: compras sin cuenta van al perfil comodín (`3f6dee20-…`, "Cliente Invitado") → el panel debe agrupar por
  `customer_email` del pedido (filas sintéticas `guest:<correo>`), no mostrar un "cliente" con todos los pedidos.
- Productos a pedido (`is_made_to_order`): no descontar/restaurar stock, sin tope en carrito, fuera de "stock crítico".
- Chat de soporte invitado: pedir solo nombre/correo/celular (no RUT ni dirección); conservar el mensaje del botón
  rápido al mostrar el formulario.
- Reseñas: botón "Opinar en Google" en el correo de calificar, SIN premio (Google prohíbe incentivar); el cupón solo
  por reseña en la web.
- Ajustes: quitar "Categorías y formatos"; plegar fidelidad (puntos/reglas/historial) en `<details>`.

### Modo noche en tiendas heredadas (pasapalos ee33985, 14-10-2026)
Componentes heredados usan colores fijos para fondo claro (bg-white, bg-amber-50, text-[#00754E], text-red-600…) y
`bg-pp-ink` con texto blanco (en noche el ink es crema). En vez de tocar 60 archivos: bloque de remapeo en
`src/styles/tokens.css` dentro de `@layer utilities` con `:where(.dark) .clase` (misma especificidad que la utilidad,
declarado después → gana a la base y pierde ante `dark:`/`hover:` explícitos). Medir con
`pasapalos-cl/scripts/auditoria/contraste.js` (escáner WCAG para consola; recorre páginas en iframes ocultos).
Correos: comprobar entrega real en Resend (`GET /emails`) antes de asumir que "no llegó" (suele ser Promociones).

### ⚠️ CORRECCIÓN a la regla "CSS del panel separado" (pasapalos f3b4be8, 14-10-2026)
Next App Router NO descarga la hoja de un layout al navegar sin recargar. Al volver del panel a la tienda
(Link "Salir al sitio", "Panel Administrativo"↔cuenta…), `admin.css` seguía activo y su `.hidden`/`grid-cols-*`
(misma capa `utilities`, declarada después) pisaban las variantes responsive de la tienda: menú oculto,
cuenta en columnas rotas, ficha superpuesta, foto del hero diminuta. Al probar entrando directo NO se ve.
Fix obligatorio junto con la separación: `admin/layout.tsx` intercepta (captura) clics a enlaces fuera de
/admin y hace `window.location.assign`; `ClientEffects` recarga si el pathname pasa de /admin a otro (router.push).
Verificar SIEMPRE con el recorrido panel → "Salir al sitio" y mirar `document.styleSheets`.

### ⚠️ Pagos que "no procesan" y clientes que se rinden: retornos no manejados + recuperación (akim, 23-10-2026)
Síntoma: clientes intentan pagar, ven "error" o "pendiente", reintentan varias veces o se van. En akim 8/24 clientes
con fallos y 3 nunca compraron (ago–oct). Ningún intento fallido tenía nota del callback → el retorno no se reconocía.
**Webpay Plus REST (doc oficial transbankdevelopers.cl/documentacion/webpay-plus)** vuelve al `return_url` así:
- normal (aprobado/rechazado): solo `token_ws`
- anulado (botón): `TBK_TOKEN` + `TBK_ORDEN_COMPRA` + `TBK_ID_SESION`
- **tiempo agotado = 4 MIN en producción** (10 en integración): SOLO `TBK_ORDEN_COMPRA` + `TBK_ID_SESION`, SIN token
  → caía en "sin parámetros" = "error inesperado" + pedido pendiente. Común en móvil aprobando en la app del banco.
- **error en el formulario + "volver al sitio"**: `token_ws` Y `TBK_TOKEN` a la vez → se intentaba commit, fallaba y
  se mostraba "verificando, NO vuelvas a pagar" → el cliente esperaba un pago inexistente y se iba.
Fix (akim 97498ba): casos explícitos, consultar `GET /transactions/{token}` antes de cancelar, mensajes que digan
"no se hizo ningún cobro" + motivo típico. Guardar `vci` (3-D Secure), `payment_type_code` y hora en la nota.
**Recuperación (akim 6317481) — replicar en TODA tienda con pasarela:**
1. Al volver con falla: banner "Pagar por WhatsApp" con #pedido (8 chars), productos y total pre-escritos.
2. Cron 2×/día (Hobby: 2 entradas diarias en vercel.json): correo "Tu pago no se completó" a pagos fallidos de
   45 min–36 h, correo real, sin compra posterior, una vez por intento (marca en `items.metadata`); botones
   "Reintentar el pago" (`/checkout?reintentar=<uuid>` rearma el carrito vía API que devuelve solo ids+cantidades)
   y "Terminar por WhatsApp". Si está pendiente, preguntar a la pasarela antes de escribir.
3. Resumen al dueño (admin_emails + support_email) con pedido, cliente, teléfono, productos, total, comuna, motivo.
4. Factura/otros tipos de facturación: verificar que SIEMPRE se pida correo (akim guardaba `cliente@` genérico).
Código de referencia: akim `src/lib/paymentRecovery.ts`, `src/app/api/cron/recuperar-pagos`, `src/app/api/webpay/confirmar`.
Medir: `scripts/qa/intentos-pago.mjs` (fallos por cliente, quién nunca compró).
**Portado a pasapalos (Mercado Pago) 23-10-2026, commit 3f5fd2c:** `src/lib/recuperarPagos.ts` + cron. Diferencias:
el botón principal del correo es el **link de pago único del pedido** (`/pagar/<id>?t=<token>`, `link_pago` en
metadata, vence 7 días) en vez de rearmar el carrito → conserva rellenos y entrega; un pedido rechazado se reabre
como `pendiente` y `mercadopago/reconciliar` NO cancela pedidos con link vigente creado después del último pago.
Antes de escribir se consulta `searchPaymentsByOrder` (approved/pending/in_process → no se escribe). Mensaje
"verificando" ya no dice "NO vuelvas a pagar". También se portó el fix de ajustes pisados (merge solo de lo enviado,
lectura sin caché para staff, `revalidateTag(..., {expire:0})`, Editar web con snapshot de cambios sin guardar).
Pasapalos YA tenía cerrados: soporte por sesión, avisos de pedido atados al pedido real, consulta con mínimo 8.
Tienda nueva → copiar AMBAS piezas (retornos de pasarela + recuperación) desde pasapalos.

## 2026-10-26 · PyP-beauty-palace-cl — correos por SMTP del cPanel del cliente (sin Resend)
- Convex "use node" internalAction con nodemailer (`convex/correoSmtp.ts`), env SMTP_HOST/PORT/USER/PASS; usar el host del servidor (p. ej. marte.hosting.5h.cl:465) porque mail.<dominio> suele no tener SSL válido. Tope diario en código (300). Remitente y reply-to = la casilla del sistema.
- Casilla la crea el USUARIO en cPanel (nunca crear cuentas con clave en prod). Clave en archivo `*-no-leak.txt` (gitignore `*no-leak*`), nunca en chat/código.
- Correos de cuenta (alta, cambio de usuario/clave, cambio de correo → al nuevo y aviso al anterior con correo oculto) sin incluir nunca la clave. Commits 07112d8, 912f76a.
- Mensaje al cliente moroso: lista simple de cambios, nada técnico (ni BD ni hosting), cierre recordando el pago.

## 2026-10-27 · PyP-beauty-palace-cl — pantalla negra en una sección del panel (React.lazy)
- Causa 1 (cPanel): zips repartidos por tamaño → un chunk JS cayó en el zip de "videos" que no se subía → 404 → lazy() falla → sin error boundary React desmonta todo → pantalla negra. Regla: zips de CÓDIGO separados de medios y se suben SIEMPRE; verificar con HEAD cada archivo tras publicar (scripts/verificar-cpanel.py).
- Causa 2 (Cloudflare assets SPA): archivo viejo de /assets devuelve index.html con 200 → error MIME. Fix: Worker con run_worker_first ["/assets/*"] que convierte HTML en 404.
- Siempre: error boundary por sección + raíz, `vite:preloadError` → recargar 1 vez, SW que no cachee text/html en /assets.
- Sesión: plazo fijo sacaba a la gente "de la nada" → renovar mientras se usa (al abrir, al volver a primer plano, cada 20 min; solo escribe pasada la mitad). setTimeout > 2^31 ms dispara al tiro: topar. Error "Sesión caducada" en useQuery → volver al login, no caerse. Commits 9dc56a1, 4efd7b0.

## 2026-10-31 · arias-wear-cl (auditoría vs pasapalos) — patrones nuevos para revisar en TODA la familia
Commits `c645df9`, `bdcee22`, `2035731` en rameseba/arias-wear.
- 🔴 **Preferencia de Mercado Pago armada solo con los ítems**: no suma despacho ni resta cupón → se cobra otro monto que el mostrado (Arias perdió el despacho en pedidos reales). Arreglo: total en servidor (`src/lib/checkoutPricing.ts`) y, si hay descuento, una sola línea con el total.
- 🔴 `/api/checkout` con `amount === 0` → pedido "procesando" (= pagado) sin pagar. Buscar `amount === 0` en las hijas de akim.
- 🔴 **Secret `NEXT_PUBLIC_SITE_URL` = localhost** → robots `Disallow: /`, `noindex` y sitemap a localhost en producción durante meses. Revisar `curl https://<sitio>/robots.txt` en cada tienda. Arreglo en código: en `NODE_ENV=production` ignorar URL local.
- 🟠 Mapas Leaflet con `basemaps.cartocdn.com`: CARTO empezó a exigir clave ("API KEY REQUIRED" pintado sobre el mapa) → `{s}.tile.openstreetmap.org` + filtro gris.
- 🟠 `SessionSync` → `syncForUser(null)` al montar vaciaba carrito y favoritos de **invitados** en cada recarga. Limpiar solo si `ownerId` era una cuenta.
- 🟠 Pedido "por WhatsApp" del carrito insertado desde el navegador: la RLS de `orders` lo rechaza en silencio → nunca se guarda ni avisa. Moverlo a una ruta de servidor.
- 🟠 Perfiles staff legibles por anon (política "Cualquiera lee perfiles de admin/owner/mod") exponían correo/teléfono/RUT del dueño.
- 🟡 `NEXT_PUBLIC_MASTER_EMAIL` mete el correo personal en el bundle público.

## 2026-11-03 · abogada-migratoria (tugestionmigratoria.cl), commits 69d603f + 586ddeb — sesiones sin estado que no se revocan
Patrón transversal a cualquier sitio con cookie firmada (HMAC) y sin tabla de sesiones: **borrar el usuario, cambiar la
contraseña o regenerar el PIN NO cierra las sesiones abiertas** (la cookie sigue válida hasta `exp`: 12 h admin, 7 días cliente).
Fix barato: guardar en la cookie una versión (`clave_ver`) o huella (`pin_hash.slice(-16)`) y comprobarla contra la base en cada
pedido (1 lectura D1, sin escrituras). También: validar subidas por **bytes reales** (magic numbers), no por extensión; y
`Range` mal formado en R2 daba 500 → responder 416. Contraseña temporal: columna `debe_cambiar` + bloqueo en el servidor (no solo en la UI).

## 2026-11-06 — Tienda demo «mimo.» clonada desde web-cueros (Documents/tienda-mascotas, sin commits)
- Clonar una tienda de cliente para demo = **riesgo de filtrar datos del cliente**: `src/lib/datosBancarios.ts` traía la
  cuenta bancaria real (nombre, RUT, n.º, correo) y se mostraba en el checkout por transferencia; el teléfono estaba
  cableado en ~10 archivos (wa.me/569…). Grep obligatorio: nombre del dueño, RUT, n.º de cuenta, teléfono, correo, Instagram.
- Supabase local con otro project_id → cambiar puertos (555xx) **y la CSP de next.config.ts** (traía 55421 cableado: el
  login fallaba en silencio con «Failed to fetch»). Turnstile en local: clave de prueba `1x<ID>AA`.
- El panel exige proveedor Google: en local marcar `raw_app_meta_data.provider = google` al usuario de prueba.
- `ajustesEnvioDe()` (src/lib/despacho.ts) tiene sus PROPIOS métodos por defecto; si se habilita «express» en
  useSettings hay que agregarlo también ahí o el servidor rechaza «El método de entrega elegido no está disponible».
- Checkout exige «indicaciones de entrega» para habilitar el paso de envío.
- Next 16 dev guarda `unstable_cache` en `.next/dev/cache`: tras cambiar la base, parar el server y borrar esa carpeta.
- Correos en local: `RESEND_API_URL` → buzón propio (`scripts/demo/buzon.mjs`, :3061) para verlos y grabarlos.

## 2026-11-07 (muebles-pro-oficial, e790237) Columna nueva en products = GRANT a anon
Las tiendas clonadas de pasapalos tienen SELECT POR COLUMNA para anon en products (auditoría 20261008). Si agregas una columna y la pides en PRODUCT_PUBLIC_COLUMNS o en un select público, la consulta falla y la ficha da 404 en producción. Siempre en la misma migración: `grant select (col) on public.products to anon;`

## 2026-11-07 (muebles-pro-oficial, plantilla pasapalos) Features reutilizables en el panel de pedidos
- **Cobros extra con link de pago**: tabla `cobros` (RLS sin políticas, solo service role), `src/lib/cobros.ts` crea preferencia MP con `external_reference = "cobro:<id>"`; el webhook la reconoce ANTES de buscar pedido; `/api/admin/cobros` (GET/POST/PATCH anular), `CobrosDialog` (botón "Cobrar extra" en el detalle + "Link de pago" suelto), vuelta en `/pagar/cobro`. Sirve para cobrar el envío por pagar, diferencias o abonos sin tocar el total del pedido.
- **Marcar como enviado con transportista**: `src/lib/transportistas.ts` (settings.web_content.carriers, URL con {codigo}), `EnviarPedidoDialog` (toda transición a "enviado" pasa por la ventana), `metadata.carrier` en el pedido, correo con empresa + enlace.
- **Instalación por producto/comuna/región**: orden de precio = propio comuna → propio región → general comuna → general región; versiones -plaza-media heredan.
- Ojo id heredado `nextday` = "Envío a todo Chile por pagar": el panel lo mostraba "Mañana ⚡".

## 2026-11-16 (rescatado del grafo retirado) Ciclo de imports en toda la familia Next
`src/app/actions/settings.ts` importa `src/store/useSettings.ts` y viceversa. Viene de akim y está en pasapalos, web-cueros,
tienda-mascotas, snackaustral, persamarket, muebles-pro, arias-wear, beauty-gang, piel-y-trigo e imperio-morales. Hoy no
rompe, pero un cambio de orden de carga puede dejar `undefined` en el arranque. Si se toca ese par en una tienda: sacar lo
compartido a un tercer módulo (p. ej. `src/lib/settings-types.ts`) y arreglarlo en la plantilla pasapalos primero.

## 2026-11-19 · Pasarelas configurables por monto (muebles-pro-oficial 9cb105e)
`src/lib/metodosPago.ts`: `payment_config.metodos = {webpay|mercadopago|transferencia: {activo, minimo, maximo}}` (0 = sin límite, sin config = todo activo). Mismo evaluador en checkout (esconde/bloquea con motivo), servidor de creación y link de pago. Útil para bajar el máximo de MP (antifraude rechaza montos altos) y empujar Webpay. Link de pago con Webpay: retorno con `?link=1` → si falla, el pedido sigue pendiente y vuelve al link.
