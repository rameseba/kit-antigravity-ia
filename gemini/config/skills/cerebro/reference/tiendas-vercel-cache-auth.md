> **Qué es:** Vercel, caché, Convex Auth y login con Google en las tiendas.
> **Actualizado:** 2026-10-24

**⚠️ Al optimizar CPU acotando el matcher del middleware, se rompe el login con Google
(2026-08-13, `piel-y-trigo-cl`: lo rompió `015362b`, lo arregló `299061f`).** En las tiendas con
Convex Auth el middleware atiende **DOS** rutas que no tienen route handler, no una: `/api/auth`
(login/logout/refresco) y el **canje del código de OAuth** —
`handleAuthenticationInRequest` actúa sobre **cualquier GET con `?code=` y `accept: text/html`**,
en la ruta que sea. Al volver de Google, Convex redirige a `window.location.origin`, o sea la
**portada**: si el matcher ya no la cubre, nadie canjea el código y el cliente aterriza en
`https://<sitio>/?code=12345678` sin sesión. **El login por correo NO se ve afectado** (va por el
SDK del navegador), así que es fácil dar el sitio por sano. Solución que conserva el ahorro:
`{ source: "/:path*", has: [{ type: "query", key: "code" }] }` — solo las visitas con `?code=`
gastan invocación. **Prueba de 10 segundos, sin sesión:**
`curl -s -o /dev/null -D - -H 'accept: text/html' 'https://<sitio>/?code=zzztest' | grep -i '^HTTP'`
— 200 en vez de 307 = login con Google roto.

**⚠️⚠️ Patrón CRÍTICO de la plantilla — `ConvexAuthNextjsServerProvider` en el layout raíz
ANULA toda la caché del sitio, y `export const revalidate` queda como código muerto
(2026-08-17, encontrado en `piel-y-trigo-cl`, aplica a TODA tienda Convex Auth de la familia).**
`src/app/layout.tsx` envuelve la app entera en `ConvexAuthNextjsServerProvider`. Por dentro hace
`await convexAuthNextjsServerState()` → `getRequestCookies()` → `await headers()` + `await cookies()`
de `next/headers` (ver `node_modules/@convex-dev/auth/dist/nextjs/server/cookies.js`). Leer
`cookies()` en el **layout raíz** vuelve dinámico **todo el árbol de rutas**: cualquier
`export const revalidate = 3600` debajo lo ignora Next **en silencio**, sin warning ni error de
build. Resultado: cada visita —persona o bot— ejecuta un render completo contra Convex.
**Cómo confirmarlo sin leer código, en Vercel → Observability → CDN/rutas:** mirar el % cacheado
por ruta. La firma es inconfundible — TODAS las rutas de `app/` al **0%**, y sólo `/robots.txt`
y `/sitemap.xml` cacheados (92-100%), porque son route handlers especiales que **no pasan por el
layout**. Ese corte exacto es la prueba.
**Síntomas que produce:** TTFB de ~2 s, CPU de Fluid que no baja aunque se optimice el
middleware, e ISR Writes altísimas sin relación con el tráfico real.
**Medido en Piel y Trigo (17-ago):** `/producto/[slug]` 65 peticiones/12h al 0%, `/tienda` 51 al
0%, `/` 40 al 0%; `/robots.txt` 92,9% y `/sitemap.xml` 100%.
**Arreglos posibles, de menos a más invasivo:** (1) sacar el provider del layout raíz y montarlo
sólo donde hace falta sesión (`/cuenta`, `/admin`, `/checkout`), dejando el catálogo público con
un layout sin cookies — el `ConvexClientProvider` del navegador ya resuelve la sesión en el
cliente; (2) Cache Components/PPR de Next 16 (`cacheComponents: true` + `use cache`), el arreglo
canónico pero el que más superficie toca; (3) hacer estáticas rutas puntuales, que es lo que se
hizo sin saberlo en Games-god (`f72eb59`, portada al 100% cacheado — por eso ese proyecto
consume menos CPU que akim y piel-y-trigo pese a tener volumen comparable). **Antes de tocar el
layout raíz de una tienda en producción hay que confirmar que nada del header/carrito dependa
del estado de auth renderizado EN SERVIDOR** — romper el login ahí es peor que el problema.

**⚠️ Lección de método — no concluir NADA de un medidor acumulado, y no mezclar ventanas
(2026-08-17).** Tres errores propios en una misma sesión mirando el CPU de Vercel:
1. El medidor **"Last 30 days" es una ventana MÓVIL**. Un número alto ahí no prueba consumo alto
   hoy: puede ser consumo viejo que todavía no salió de la ventana. Un arreglo que funciona
   perfecto se ve exactamente igual que uno que no hizo nada, porque el contador queda **clavado**
   en vez de bajar. Para el consumo actual hay que ir a Observability y usar la ventana corta.
2. **Nunca dividir un total de 30 días por un tráfico de 7 días.** Así "deduje" 22 s de CPU por
   visita y me inventé una inundación de bots que no existía. Era puro artefacto de mezclar
   ventanas.
3. **Speed Insights es RUM de cliente**: sólo cuenta navegadores reales ejecutando JavaScript,
   no ve bots ni crawlers. No sirve para medir el tráfico que llega al servidor — para eso, Edge
   Requests en Observability. En esta cuenta el ratio es ~1:150 (1,8K eventos vs 268K Edge
   Requests en 30 días).

**⚠️ Retención de Vercel en plan Hobby (2026-08-17, medido):** Observability retiene **12 horas**
(24h/3d/7d/14d/30d están detrás de Pro). Firewall muestra sólo **la última hora**. Los errores de
runtime por API llegan a **7 días**. Usage sí da 30 días y 7 días. Al auditar, **anotar siempre
la ventana junto a cada número** o los datos no se pueden comparar entre proyectos.

**Prueba de 10 segundos para saber si una tienda cobra de verdad o simula (2026-08-17, aplicada
a 2 tiendas):** `POST` a `/api/mercadopago/webhook` con `{"isMock":true}` y **sin** `orderId`.
`400 Falta orderId` = **modo simulado**. `401 Firma de notificación inválida` o `403` = pasarela
real. Ojo con el redirect: hay que seguir a `www.` (`curl -L`) o sale un `308` sin respuesta.
Resultados: `imperiomorales.cl` → 401 (**real**, confirmado también por el dueño pagando con su
tarjeta; tiene `NEXT_PUBLIC_MOCK_GATEWAY` en Production pero no está activo);
`pielytrigo.com` → 400 (**simulado**, pendiente conocido).
**Corolario útil:** un POST anónimo cualquiera genera la línea de log "Firma de webhook inválida
(mismatch)". Así que ver unos pocos de esos errores sueltos en producción **no** significa que se
estén rechazando pagos reales — casi seguro son sondeos externos bloqueados correctamente.

**⚠️ Desconfiar del reparto por entorno que reporta una auditoría hecha por UI (2026-08-17).**
Una auditoría vía navegador informó "piel-y-trigo: Production 5 · Preview 8 · Development 7" y
levantó una alarma grave (Cloudinary y Resend ausentes en producción → correos que no salen).
**Era falso:** `vercel env ls production` mostró **15 variables en Production**, las 6 incluidas.
La lectura del reparto por entorno en la UI es poco fiable. **Verificar siempre con
`vercel env ls production`** (muestra sólo nombres y scope, nunca valores) antes de actuar sobre
un hallazgo de variables faltantes.

**⚠️⚠️ Patrón CRÍTICO family-wide — un `Origin` opaco tumba el login en TODA tienda con Convex
Auth (2026-08-17, encontrado y arreglado en `Games-god`, commit `d561f7a`).**
**✅ ESTADO AL 2026-08-23: las TRES tiendas Convex Auth en producción responden `403` — el bug
ya no está en ninguna.** `Games-god`, `piel-y-trigo-cl` (arreglado en `9ad2e52`) y
`beauty-gang-world-com`. Comprobado con la sonda de abajo, incluyendo el control con el origen
real (`200`). Este archivo decía antes que seguía sin arreglar en las dos últimas: ya no es
cierto. Las tiendas de Supabase no lo tienen por construcción. **Quedan sin comprobar**
`criadero-cachorros`, `Barberia-cl`, `Picker-Cal` y `ua-antofa-cl` (no se conocen sus dominios). `isCorsRequest()` de
`@convex-dev/auth` (`dist/nextjs/server/utils.js`) hace
`const originURL = origin ? new URL(origin) : null`. **`Origin: null` es un valor VÁLIDO del
header**: el navegador manda la cadena literal `"null"` cuando el origen es opaco (iframes con
`sandbox`, páginas `file://`, ciertos redirects cross-origin, algunos modos de privacidad). La
guarda sólo cubre el header AUSENTE — la cadena `"null"` es truthy, entra a `new URL("null")` y
tira `TypeError: Invalid URL (input: 'null')`. Como pasa **dentro del middleware/proxy**, se cae
la petición entera. En Games-god: **100 fallas sobre 69 usuarios distintos en 7 días**, todas en
el flujo de autenticación. **El bug sigue presente en la última versión publicada (0.0.95), así
que actualizar la dependencia NO lo resuelve.**
**Prueba de 10 segundos contra cualquier tienda (seguir el redirect a www con `-L`):**
```bash
curl -s -L -o /dev/null -w "%{http_code}\n" -X POST "https://<dominio>/api/auth" \
  -H "Origin: null" -H "content-type: application/json" \
  -d '{"action":"auth:signOut","args":{}}'
```
`500` = roto · `403` = arreglado. Control obligatorio: repetir con el `Origin` real del sitio →
debe dar `200` (si TODO da 403, el 403 viene de otra cosa, no del arreglo).
**⚠️ El arreglo obvio —borrar el header `Origin` y seguir— es una REGRESIÓN DE SEGURIDAD:**
`isCorsRequest` pasaría a devolver `false` y la petición se trataría como del mismo origen, que
es justo lo que hay que bloquear (un origen opaco ES cross-origin). Hay que aplicar la MISMA
consecuencia que aplicaría la librería si no reventara — ver `proxy.ts` de Games-god:
`/api/auth` (POST) → `403 "Invalid origin"` igual que `proxyAuthActionToConvex`; cualquier otra
ruta → descartar las cookies de sesión y dejar seguir la petición como anónima, igual que
`validateCors`. Reconstruir el request **sólo** en la segunda rama (navegaciones GET), para no
clonar un cuerpo.

**⚠️ En CSP, `*.dominio.com` NO cubre `dominio.com` — rompe Google Analytics en silencio
(2026-08-17, `imperio-morales`).** La CSP tenía `*.analytics.google.com` en `connect-src`, pero
**GA4 se conecta al host pelado `analytics.google.com`**, así que el navegador bloqueaba todos
los eventos (`page_view`, `form_start`) y la tienda llevaba tiempo sin medir nada. No falla nada
visible: sólo aparece en la consola del navegador. **Chequeo:**
`grep -E "connect-src[^;]*analytics" next.config.*` — si sólo está la forma con comodín, está
roto. Hay que listar **ambas** formas. **Confirmado con el mismo bug:** `akim-pet-market-web` y
`3.pasapalos-cl`. (`piel-y-trigo-cl`, `Games-god` y `beauty-gang-world-com` no tienen
`analytics.google.com` en `connect-src` en absoluto — en Piel y Trigo es coherente porque GA
todavía está como TODO pendiente en `layout.tsx`, pero en los otros dos hay que confirmar si usan
GA, porque de usarlo estaría 100% bloqueado.)

**✅ VEREDICTO FINAL (probado en producción entrando con Google en las DOS tiendas).**
El patrón **es real, pero NO es universal: depende de cómo esté montado el provider.**
- `beautygangworld.com` **funciona con las páginas cacheadas**: `GET / → 307` (canje del `?code=`) ·
  `/` y `/tienda` **200 HIT desde el CDN** · `POST /api/auth → 200` (el cliente pide el token al
  volver) · `/api/cart` 200 (sesión activa). **No necesita ningún cambio.**
- `piel-y-trigo-cl` **sin el provider de servidor NO funciona**: `POST /api/auth → 200` ·
  `GET / → 307` · `GET / → 200 HIT` **y ahí se acaba** — ningún `POST /api/auth` posterior, ninguna
  llamada a `/api/cart` ni `/api/favorites` (que en esa tienda sí existen). El cliente nunca se
  entera de la sesión.
**La diferencia:** BGW **conserva** `ConvexAuthNextjsServerProvider` aislado en un `<Suspense>` con
**Cache Components / PPR**, así que esa parte se resuelve **por visitante** aunque el shell venga
cacheado. Piel y Trigo lo tenía en modo cliente puro: de una página cacheada no llega nada.
**Cómo saber en qué caso está una tienda — NO por el `cache-control`** (BGW da `public` y va bien),
sino **capturando el tráfico de un login real**: tras el `307` del canje, ¿aparece un
`POST /api/auth` y llamadas a rutas con sesión? Si el rastro muere en el `HIT`, la sesión no llegó.
Hay un vigía listo para esto: `piel-y-trigo-cl/scripts/qa/watch-pago.mjs --project <proyecto>`.
**Para tener caché Y login**: migrar a Cache Components/PPR como BGW (Next 16). Sin eso, el
provider de servidor es obligatorio y la tienda no cachea — es el precio correcto.
**Errores propios que costaron dos idas y vueltas en producción:** (1) escribir este patrón sin
haber observado nunca el flujo real; (2) al ver que BGW funcionaba, generalizar en sentido
contrario y revertir el arreglo bueno de Piel y Trigo, dejando al dueño sin login otra vez.
**Dos tiendas del mismo linaje pueden diferir en algo tan de fondo como dónde vive la sesión:
capturar el tráfico de CADA una antes de concluir.**

**⚠️ CORREGIDO EL MISMO DÍA — el patrón que sigue NO se sostuvo con datos. Leer esto antes.**
Se capturó en vivo el tráfico de `beautygangworld.com` mientras el dueño entraba con Google:
`POST /api/auth → 0` (abortado) · `GET / → 307` (el middleware canjeando el `?code=`) ·
`GET /` y `/tienda` **→ 200 HIT, servidas desde el CDN** · `POST /api/auth → 200` (entró) ·
`/api/cart` y `/api/favorites` → 200 (el servidor ya reconoce la sesión). **El login con Google
funcionó con la portada CACHEADA.** Que una página salga del CDN **no** impide entrar con Google:
el navegador consigue el token igual hablando con `/api/auth`. El síntoma «no inicia sesión» que
se reportó encaja con esa petición **abortada**, no con un fallo estructural.
**Por tanto: la prueba del `cache-control` de abajo NO detecta nada** (BGW da `public` y su login
va bien), **no hay que portar este "arreglo" a ninguna tienda**, y el aplicado a `piel-y-trigo-cl`
(`6b0e8e0`) **probablemente era innecesario** y cuesta la caché de toda la tienda — pendiente de
comprobar entrando con Google y, si va bien, revirtiéndolo y probando otra vez.
**Lección:** se construyó todo este patrón desde un síntoma reportado y una lectura de código
plausible, sin observar nunca el flujo real. La captura en vivo costó cinco minutos y habría
evitado dos cambios equivocados en la tienda de una clienta. **Cuando el síntoma es "a veces no
entra", mirar el tráfico ANTES de tocar código.**

**⚠️⚠️ ATENCIÓN — sacar `ConvexAuthNextjsServerProvider` del layout para ganar caché ROMPE EL
LOGIN CON GOOGLE (2026-08-23, pasó en producción en `piel-y-trigo-cl`; regresión de `58ed0d9`,
arreglada en `6b0e8e0`).** Son dos caminos distintos para la misma sesión: con **correo y
contraseña** el canje lo hace el SDK en el navegador y deja el token en **`localStorage`**; con
**Google** lo hace el **middleware** y lo deja en **cookies**. Sin el provider de servidor, el
navegador mira solo `localStorage` y nunca se entera de la sesión de Google: el usuario vuelve a
la portada como si no hubiera entrado, y como el login por correo sí funciona, parece
intermitente. Comprobado en `node_modules/@convex-dev/auth/dist/react/client.js`: con
`serverState !== undefined` toma el token de las cookies y lo guarda; con `undefined` cae en
`readStateFromStorage()` y nada más.
**La prueba del `?code=` NO detecta esto** — el middleware sigue devolviendo 307 y canjeando bien;
el fallo está en el otro extremo. **La prueba que sí lo detecta, sin iniciar sesión:**
```bash
curl -sI https://<dominio>/ | grep -i cache-control
```
`private, no-cache, no-store` → lee cookies → login con Google OK.
`public, max-age=0, must-revalidate` (o `x-vercel-cache: HIT/PRERENDER`) → **si esa tienda ofrece
entrar con Google, está roto**.
⚠️ **Ese arreglo de caché se portó a `Games-god` (`f72eb59`), `beauty-gang-world-com` (`52bd151`)
e `imperio-morales` (`89de0dd`).** Medido el 23-ago: las portadas de `beautygangworld.com` y
`gamesgod360.com` responden `public` → **sospechosas, sin confirmar** (no se pudo comprobar si
ofrecen login con Google; el panel puede cargarse en un chunk diferido). Confirmarlo es abrir su
panel de sesión y ver si hay botón de Google.
**Coste asumido al arreglarlo:** restaurar el provider vuelve dinámica toda la rama de la tienda y
se pierde la caché. Recuperar ambas cosas exige sembrar `localStorage` tras el canje del OAuth sin
leer cookies en el layout — **no intentarlo sin poder probar un login real de Google**.
**Lección de método:** el arreglo de rendimiento se verificó midiendo cabeceras y contenido del
HTML, y todo daba bien. No se probó el camino de sesión que no pasa por el navegador. Cuando un
cambio toca DÓNDE VIVE la sesión, hay que probar **cada forma de entrar**, no solo la más común.


### ⚠️ `unstable_cache` con revalidate corto arrastra a TODAS las páginas que lo usan (pasapalos ee8e19b, 24-10-2026)
Pasapalos llegó a 157K/200K ISR Writes en 30 días con 8 pedidos: `getCachedSettings` tenía `revalidate: 60`
(2a34a0c, para que tarifas cambiadas en la base llegaran al checkout) y la portada/manifest pasaron a regenerarse
CADA MINUTO (la página toma el menor revalidate de sus datos; el build lo muestra: `○ /  1m`). Fichas 30 min, resto 1 h.
Fix: todo a 1 día + invalidación inmediata (`revalidateProduct` en venta, devolución de stock y reseñas) +
`/api/settings/public` leyendo DIRECTO de la base con `s-maxage=60` (desacopla checkout de la caché de páginas).
**Regla:** después de cualquier `revalidate` nuevo, mirar la columna Revalidate de `next build`; nada bajo 1d salvo motivo.
Supabase t3a.nano: CPU 3%, RAM 60%, 15/60 conexiones = normal. Advisors: "Leaked password protection" es solo Pro.
