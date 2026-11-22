# Patrones técnicos de la familia de tiendas (Next.js + Convex)

> Destilado de la auditoría completa de `piel-y-trigo-cl` del **2026-08-23** (6 fases,
> ~15 arreglos en producción) más las comprobaciones cruzadas en `beautygangworld.com`,
> `gamesgod360.com` e `imperio-morales`.
>
> **Todo lo de aquí está medido contra producción, no deducido.** Cuando algo no se pudo
> confirmar, se dice.
>
> **Ampliado el 2026-08-28** con la auditoría completa de `AirSoft-cl` (Next.js + Convex +
> Mercado Pago, con un pago real de $50 verificado extremo a extremo). Es el mismo linaje:
> lo de abajo marcado *(AirSoft)* se encontró ahí, y toca comprobarlo en las tiendas.
>
> Complementa `TRANSVERSALES.md` (cómo trabaja el usuario). Esto es cómo fallan sus tiendas.

---

## Cómo usar este documento en una tienda nueva

Orden por coste/beneficio. Las primeras cinco sondas son de **solo lectura, sin efectos
secundarios**, y no necesitan sesión: se pasan todas en unos minutos.

| # | Sonda | Qué destapa |
|---|---|---|
| 1 | POST al webhook de pago con `{"isMock":true}` sin `orderId` | si la tienda **simula** el cobro |
| 2 | Comparar `price` del JSON-LD vs `<g:price>` del feed vs base | precio falso a Google |
| 3 | `POST <convex>/api/query` a las queries de pedidos | fuga de datos personales |
| 4 | `curl -sI` de una página pública | caché rota (con el matiz del §4) |
| 5 | Markup sin `<script>`: ¿hay productos? | catálogo invisible sin JS |
| 6 | `/api/checkout` con `amount` menor al real | despacho y descuentos server-side |
| 7 | Pulsar Guardar en una ficha sin promoción y mirar el precio en la BASE | precios que se van a 0 (§1.4) |
| 8 | Pedir más unidades de las que hay en stock | tope que sólo se dibuja (§1.5) |
| 9 | Abrir la pantalla de retorno de pago con un id inventado | pantalla gris del navegador (§5.2) |

---

## 1. Dinero

### 1.1 El JSON-LD puede publicar un precio 100 veces menor que el feed
Medido en `piel-y-trigo-cl`: base **12.350 CLP**, JSON-LD **123,50 CLP**, los dos feeds
**12.350**. Dos precios contradictorios para la misma ficha → rich snippets falsos y
desajuste feed↔página de destino, que **es motivo de sanción en Merchant Center**.

Causa: un comentario heredado que afirmaba que los precios están en centavos.

**⚠️ NO es «quitar el ÷100» en todas partes.** En `beautygangworld.com` el ÷100 es
**correcto**: esa tienda cobra en centavos de CAD (comprobado, declara 38,03 y muestra
38,03). **La regla es que JSON-LD, precio visible y feed digan el MISMO número.**

En el mismo bloque suele haber un `shippingDetails` con valor `0` hacia `"CA"` (Canadá) —
las dos cosas falsas fuera de la tienda original.

### 1.2 Sondear el checkout sin crear pedidos
Mandar a `/api/checkout` un `amount` menor al real: responde **400 `TOTAL_MISMATCH`** con
sus propios `{shipping, discount, subtotal, expectedTotal}` y **no crea nada**. Es la forma
barata de auditar despacho y descuentos en vivo. Tope: 20 por hora y por IP.

### 1.3 Una variable de entorno puede apagar el cobro en silencio
`NEXT_PUBLIC_MOCK_GATEWAY` en Production. Aunque el código compare con `=== "true"`
estricto, **basta cambiar su valor para que la tienda deje de cobrar sin que nada avise**.
Borrarla. `imperio-morales` la tenía; en `piel-y-trigo-cl` se borró el 23-ago.
**Claude no puede**: el clasificador bloquea modificar variables de entorno, y hace bien.

### 1.4 Guardar un formulario escribe `0` donde debía ir vacío, y el precio se va a CERO *(AirSoft)*
Encontrado **en producción, en el evento real**. Bastaba pulsar Guardar en la ficha de un
evento sin promoción para que la jornada pasara a cobrar **$0 la entrada y $0 el arriendo**.
Cambiar la hora o la foto habría hecho lo mismo.

Dos fallos que se suman, y ninguno se ve por separado:

1. El `handleSubmit` guardaba los campos de la promoción **crudos**: `presaleEntryFee: 0`,
   `presaleEndsOn: ""`. La **vista previa SÍ los normalizaba** (convertía el 0 en «sin
   promoción»), así que la pantalla mostraba el precio correcto mientras la base quedaba mal.
2. `isPresaleActive` daba la promoción por empezada con que el campo **no fuera `undefined`**,
   y un `0` cumple. Modo automático + sin fecha de término = promoción perpetua a precio cero.

**Chequeo en cualquier tienda:** buscar toda condición `!== undefined` sobre un campo de
precio o descuento opcional — un `0` guardado la satisface. Y comparar el objeto que arma la
VISTA PREVIA con el que arma el GUARDADO: si cada uno normaliza por su cuenta, ya divergieron.
**Arreglo doble:** que ambos lean del mismo objeto, y que el `0` se lea como campo vacío
(nadie hace una promoción gratis; quien quiera regalar algo pone el precio normal en 0). El
segundo arreglo **repara además los documentos ya guardados mal, sin tocar la base**.

### 1.5 El tope de existencias sólo se dibuja, no se aplica *(AirSoft)*
`maxPlayers` alimentaba la barra de ocupación y le declaraba `SoldOut` a Google, pero **ni el
navegador ni el servidor impedían reservar por encima**. No hace falta un atacante: dos
personas mirando «quedan 2» a la vez inscriben cinco. Medido: se llegaba a **96 de 80**.

El equivalente en una tienda es el stock. **Chequeo:** buscar dónde se compara el stock con lo
pedido; si `stock` sólo aparece en componentes de presentación y en el JSON-LD, no hay control.

---

## 2. Privacidad

### 2.1 La censura aplicada a una query no llega a sus hermanas
`orders.getById` censuraba con `redactOrder`; **`orders.listMineWithGuests`, al lado, no**.
Se le pasa un id de pedido y devolvía nombre, correo, teléfono, RUT, dirección y
comentarios de entrega. Los ids circulan en URLs de retorno de pago y en correos.

**Trampa al probarlo:** esa query **excluye los pedidos `pendiente`**. Con un pedido
pendiente parece sana. Hay que usar uno pagado.

### 2.2 Regla general
Por cada función que censure campos, buscar **todas** las que leen la misma tabla. La
censura se añade donde apareció el bug, no donde hace falta.

---

## 3. Caché y renderizado

### 3.1 `generateMetadata` que lee `searchParams` vuelve dinámica la ruta ENTERA
Sin warning ni error de build, y el `export const revalidate` sigue ahí aparentando
funcionar. En `piel-y-trigo-cl` dejaba `/tienda` —la segunda página más visitada— fuera del
CDN. **Señal:** en el build, una ruta de catálogo marcada `ƒ (Dynamic)` cuando debería ser
`○`/`●`.

### 3.2 Al volver cacheable una ruta, el catálogo puede quedar VACÍO sin JavaScript
Si el listado usa `useSearchParams()` dentro de un `<Suspense>`, en ruta **estática** Next
se salta la prerenderización de ese subárbol y sirve **el fallback**. Medido: el markup de
`/tienda` pasó a traer **0 de 26 productos** (viajaban solo en el payload) y ningún `<h1>`.

Importa porque **los agentes de IA son canal de venta declarado del dueño** y varios no
ejecutan JS. Arreglo: que el fallback del Suspense sea el catálogo real renderizado en
servidor.

**Chequeo:** quitar los `<script>` ANTES de contar —
`re.sub(r"<script.*?</script>", "", html, flags=re.S)`. Un grep sobre el HTML entero da
26/26 y parece sano.

### 3.3 ⚠️⚠️ Convex Storage sirve la media con `Cache-Control: private` — ninguna CDN puede cachearla *(añadido 2026-08-29, leon-laser-cl)*
`ctx.storage.getUrl()` devuelve una URL de `*.convex.cloud` que responde
`Cache-Control: private, max-age=2592000`. **`private` prohíbe explícitamente que cualquier caché
COMPARTIDA la guarde**, así que Cloudflare/Vercel no pueden: solo cachea el navegador de cada
persona. Cada visitante nuevo, cada incógnito y cada caché vencida vuelve a bajar el archivo de
Convex, y eso consume **Data Egress**, la cuota más chica del plan gratis (1 GB).

Medido en `leonlaser.cl`: **10,2 MB por visita de escritorio** (video del hero 9,35 MB + 4 fotos).
2,58 GB ÷ 10,2 MB ≈ **253 visitas** para reventar la cuota — y eso fue exactamente lo que pasó.

**Arreglo:** un proxy propio (`/api/media/[id]`) que reemite con `public, immutable`, y que
`storageUrl()` devuelva esa ruta. **El detalle que decide si funciona:** en Cloudflare Workers hay
que guardar A MANO en `caches.default` — el borde **no cachea sola la respuesta de un Worker**, ni
la subpetición a Convex (el origen la marca `private`). Sin eso el proxy solo sirve para la caché
del navegador y no arregla nada. En Vercel el route handler sí lo cachea el CDN.
**Prueba de que funciona:** la respuesta trae cabecera `age` creciente.

**Chequeo en cualquier proyecto Convex con media:** `grep -rn "storage.getUrl" convex/`, y sobre
todo mirar el sitio en vivo:
```bash
curl -s https://<dominio>/ | grep -oE 'https?://[a-z0-9.-]+/[^"]*\.(webp|jpg|png|mp4)' | cut -d/ -f3 | sort | uniq -c
curl -sI <url-de-una-imagen> | grep -i 'cache-control\|x-vercel-cache\|age'
```
**Ojo:** las tiendas con **Cloudinary están bien** (es un CDN, sirve desde su propio borde); el
riesgo ahí es la cuota de créditos, no un bug de caché.

### 3.4 ⚠️⚠️ `fetchQuery` de Convex sin `unstable_cache` vuelve dinámico TODO el sitio *(2026-08-29, truckdiesel-cl; ya estaba en leon-laser-cl)*
`fetchQuery` de `convex/nextjs` hace un fetch **sin caché**, así que Next marca la ruta como
dinámica y **los `export const revalidate` quedan como código muerto**, sin warning. Y si el
**layout raíz** lo usa en `generateMetadata` —cosa habitual para el título y la descripción del
sitio— con eso solo se vuelve dinámico el árbol entero.

Es la segunda causa distinta que produce el mismo síntoma que 3.1. **Arreglo:** envolver las
lecturas públicas en `unstable_cache` con una etiqueta, más una ruta `/api/revalidate` que el panel
llame al guardar. El panel se deja con `fetchQuery` directo a propósito: ahí se quiere el dato
fresco. En Next 16 **`revalidateTag` pide dos argumentos**: `revalidateTag(TAG, "max")`.

### 3.5 Cómo saber QUÉ proyecto se come el CPU cuando la API no da desglose *(2026-08-29)*
En Vercel Hobby no hay uso por proyecto, y **los logs de runtime no sirven como conteo de tráfico**
(la retención los recorta: `since:7d` devolvía 12 líneas para un sitio con tráfico real). Lo que sí
decide el CPU es **si cada visita ejecuta una función o sale del CDN**. Dos peticiones seguidas a la
portada, la 2ª es la que vale:
- `x-vercel-cache: HIT|STALE` y `cache-control: public` → CDN, **cero CPU**
- `MISS`/`BYPASS` o `private|no-store|no-cache` → **función en cada visita**

Aplicado a los 20 proyectos de la cuenta: **solo 2** ejecutaban función por visita
(`piel-y-trigo-cl` y `truckdiesel-cl`), y entre esos dos se llevaban casi todo el Fluid Active CPU
(3 h 34 min de 4 h). **Corolario que ahorra trabajo inútil: apagar sitios estáticos no mueve esa
aguja.** La `age` de la caché delata a los inertes (había portadas con 78 y 80 días).

### 3.6 Antes de optimizar un archivo de `public/`, ver si se entrega DIRECTO o por `/_next/image` *(2026-08-29, AirSoft-cl)*
Si pasa por el optimizador, el visitante recibe la versión optimizada y **nunca el original**
(medido: 136 KB a 640 px contra 341 KB del archivo). Achicar ese origen solo reduce el tamaño del
despliegue, **no los bytes que baja la gente**. Lo que **sí** se entrega tal cual: `og:image` y el
JSON-LD. Ahí un PNG de 2,8 MB se manda entero en cada vista previa de enlace — y **para og:image va
JPEG, no WebP**, que WhatsApp y varios rastreadores aún no lo muestran.

Complemento: sin `deviceSizes`/`imageSizes` propios, Next genera **16 anchos por imagen**. En
AirSoft eran **232 transformaciones distintas de 18 imágenes** en una sola portada. Recortando la
escalera a los anchos que el diseño pide de verdad: **157**.

### 3.7 `naturalWidth` MIENTE cuando hay un loader custom de `next/image` *(2026-08-29, leon-laser-cl)*
Con `loaderFile` custom, Next igual emite `srcSet="<misma-url> 1x, <misma-url> 2x"` (el loader
ignora el `width`, así que las dos candidatas son el MISMO archivo). El navegador elige la `2x` y
**reporta `naturalWidth` a la mitad de los píxeles reales**. Una auditoría hecha así dio "poster de
239×425 estirado" cuando el archivo era **478×850**, y "fotos de 709×950" que eran **896×1200**.
**Regla: para juzgar resolución, medir el ARCHIVO (`ffprobe`/`identify`), no el DOM.**

---

## 3bis. Video de fondo: secuencia de fotogramas vs video *(2026-08-29, medido)*

Pregunta recurrente al ver sitios tipo Apple. **La secuencia de fotogramas pesa ~19× MÁS**, no
menos: cada cuadro se guarda entero y se pierde la compresión entre cuadros. Medido sobre un clip
real de 33 s:

| opción | peso |
|---|---|
| secuencia AVIF 12 fps (396 frames) | **~26 MB** |
| AV1 nativo | 2,75 MB |
| H.264 nativo | 1,80 MB |
| H.264 360 px | 1,37 MB |
| **H.264 nativo, ida y vuelta 16 s** | **0,97 MB** |

Esa técnica existe para **scrubbear con el scroll** (no se puede buscar cuadro a cuadro en un
`<video>` de forma fiable, menos en Safari iOS), no para ahorrar peso. Un hero en bucle automático
no gana nada. **AV1 tampoco ayuda** a resoluciones bajas: salió más pesado que H.264 en las tres
pruebas.

**Lo que sí funciona:** cortar el clip y concatenarlo con su propia versión invertida
(`split` + `reverse` + `concat`): termina donde empieza, así que **el bucle no tiene costura**, y
permite subir la resolución bajando el peso. **Trampa:** el poster hay que regenerarlo del primer
fotograma del video nuevo, o se ve un salto al arrancar. Y el denoise (`hqdn3d`) es lo que más
comprime en tomas con grano o chispas.

---

## 4. ⚠️ Login con Google vs caché — el episodio más caro del día

**El patrón es real, pero NO es universal: depende de cómo esté montado el provider.**
Probado entrando con Google de verdad en las dos tiendas, con el tráfico capturado.

**`beautygangworld.com` — FUNCIONA con las páginas cacheadas:**
```
GET  /              → 307      el middleware canjea el ?code=
GET  / , /tienda    → 200 HIT  desde el CDN
POST /api/auth      → 200      ← el cliente PIDE el token al volver
GET  /api/cart      → 200      ← sesión activa
```

**`piel-y-trigo-cl` sin provider de servidor — NO FUNCIONA:**
```
POST /api/auth      → 200
GET  /              → 307
GET  /              → 200 HIT  ← y ahí se acaba: nadie pide el token
```

**La diferencia:** BGW **conserva** `ConvexAuthNextjsServerProvider` aislado en un
`<Suspense>` con **Cache Components / PPR**, así que esa parte se resuelve **por
visitante** aunque el shell venga cacheado. Piel y Trigo lo tenía en modo cliente puro: de
una página cacheada no llega nada.

**Cómo diagnosticarlo — NO por el `cache-control`** (BGW da `public` y va bien), sino
**capturando el tráfico de un login real**: tras el `307` del canje, ¿aparece un
`POST /api/auth` y llamadas a rutas con sesión? Si el rastro muere en el `HIT`, la sesión
no llegó.

**Para tener caché Y login:** migrar a Cache Components/PPR como BGW (Next 16). Sin eso el
provider de servidor es obligatorio y la tienda no cachea — es el precio correcto.

**Dos formas de entrar, dos sitios distintos para la sesión:**

| Forma | Quién canjea | Dónde queda |
|---|---|---|
| Correo y contraseña | el SDK, en el navegador | `localStorage` |
| Google (OAuth) | el **middleware** | **cookies** |

Por eso el fallo parece intermitente: por correo funciona siempre.

---

## 5. Errores que el cliente ve *(AirSoft)*

### 5.1 El mensaje del backend NO llega: `err.data`, no `err.message`
Ya está registrado para los paneles, pero apareció **en la pantalla del comprador**, que es
peor. El texto de un `ConvexError` viaja en **`err.data`**, y en producción Convex sustituye
el mensaje de cualquier otro error por `"[Request ID: …] Server Error"`. El modal de reserva
hacía `setError(err.message)`, así que **todas** las explicaciones que el backend ya escribía
—falta el nombre, máximo 12 por reserva, ese extra ya no está— le llegaban al cliente como un
error interno.

**Lo revelador:** todo el panel usaba ya el helper correcto; la **única** pantalla de cara al
cliente se había quedado fuera. **Chequeo:** `grep -rn "err.message" components/ app/` y mirar
cuáles son pantallas públicas.

### 5.2 Sin `error.tsx`, una excepción deja la pantalla gris del navegador
Next sirve su «This page couldn't load»: fondo gris, en inglés, sin marca y sin forma de
volver. Apareció en **la pantalla de vuelta del pago** — la peor posible: la consulta del
estado recibe el número de pedido desde la URL y **Convex LANZA si ese valor no es el id de un
pedido real** (no devuelve vacío: lanza). Basta un enlace viejo o cortado al copiarlo. Quien
acaba de pagar ve una pantalla en blanco, y el reflejo es **volver a pagar**.

**Arreglo:** un `error.tsx` por zona (público, panel) y **uno propio para la ruta de retorno**,
con el mensaje que corresponde («si el cobro te salió, no lo hagas de nuevo») y el WhatsApp
sacado de los ajustes, nunca escrito a mano.

### 5.3 Un `not-found.tsx` o `error.tsx` que lee datos llega VACÍO
Escribir uno que consulte la base para pintar el pie lo vuelve **dinámico**: Next deja de
prerenderizarlo y el HTML llega sin cuerpo, con el contenido sólo en el payload de
hidratación. Se ve únicamente ejecutando JavaScript — justo lo que no hacen varios agentes de
IA, que aquí son canal de venta declarado. **Una pantalla de error tiene que ser HTML plano.**
Comprobar en `.next/server/app/_not-found.html` tras el build.

**Matiz medido:** un `notFound()` lanzado desde una ruta **dinámica** (`/eventos/[slug]`) sigue
llegando con el cuerpo vacío por el streaming, aunque el `not-found` sea estático. El status
404 es correcto y una persona lo ve bien; arreglarlo del todo exigiría `dynamicParams = false`,
que rompe el contenido creado desde el panel. Se dejó así a conciencia.

### 5.4 Tras confirmar el pago hay que invalidar la caché, o el comprador no se ve
Con ISR, quien acababa de pagar volvía al inicio y **no aparecía en la lista** hasta recargar
un minuto después. Es el peor momento para que la web parezca no haberse enterado. Se resolvió
con un server action que revalida las rutas afectadas **comprobando antes contra la base que el
pago está confirmado** — sin esa comprobación es una forma barata de forzar regeneraciones.

---

## 6. Móvil y accesibilidad

- **1 rem NO son 16 px** en estas plantillas: en Piel y Trigo la raíz está en **14,4 px**,
  así que cada medida de Tailwind vale un 10 % menos. `h-10` da **36 px**; para ~44 hace
  falta `h-12`. **Solo se ve midiendo el resultado**, no escribiéndolo.
- **`resize_window` no cambia el viewport.** Lo que funciona: inyectar un **iframe del
  mismo origen** de 390×844 y medir dentro — las media queries responden a su tamaño.
- **Los botones de comprar y favorito de la tarjeta medían 29×29 px, pegados.** Fallar el
  toque agrega al carrito lo que se quería marcar como favorito. Es fallo de conversión.
- **La grilla de categorías con `grid-cols-1` en móvil** se comía 1,73 pantallas. A dos
  columnas: de 1.457 a 657 px. Es la queja de diseño #1 del usuario (ver `TRANSVERSALES.md`).
- **30 campos con `<Label>` sin `htmlFor` y `<Input>` sin `id`**: la etiqueta se ve pero no
  está asociada. Un grep decía «34 campos sin label»; al abrirlos, **30 sí tenían** y el
  problema era otro. **Abrir el archivo antes de contar.**

---

## 7. Herramientas — lo que funciona y lo que no

- **`vercel logs --follow` NO entrega las peticiones.** Conecta, dice
  `waiting for new logs...` y no sale nada. Comprobado generando tráfico real y
  contrastando con la API, que sí lo veía. **Usar `vercel logs --json -n 50` en bucle**,
  deduplicando por el `id` de cada línea. Hay un vigía hecho y probado:
  `piel-y-trigo-cl/scripts/qa/watch-pago.mjs --project <proyecto>`.
- **El MCP de Vercel** da errores de runtime pre-agregados sin pasar por la web (bloqueada
  para el navegador): `get_runtime_errors` / `get_runtime_logs` con `projectId` + `teamId`.
- **`npx convex run --prod` lee el deployment de DEV en silencio** si `.env.local` tiene un
  `CONVEX_DEPLOY_KEY` de dev. Anteponer `CONVEX_DEPLOY_KEY= ` al comando.
- **`npx convex export --prod`** es la forma fiable de leer la base (`convex data` trunca
  columnas). **Trae datos personales reales: borrarlo al terminar.**
- **`vercel link` reescribe `.env.local` sin avisar.** No usarlo solo para obtener un
  projectId; `vercel logs --project <nombre>` no lo necesita.
- Leer una query pública como la vería un visitante:
  `POST <convex>/api/query` con `{path, args, format:"json"}`.

---

## 8. Método — lo que costó caro

1. **Dos veces construí un patrón family-wide desde un síntoma y una lectura de código
   plausible, sin observar el flujo real.** La captura de tráfico costó cinco minutos y
   habría evitado dos cambios equivocados en producción, uno en la tienda de una clienta.
2. **Al ver que una tienda funcionaba, generalicé en sentido contrario** y revertí el
   arreglo bueno de la otra, dejando al dueño sin login otra vez. **Dos tiendas del mismo
   linaje pueden diferir en algo tan de fondo como dónde vive la sesión.**
3. **Un grep no sirve para concluir, solo para priorizar.** Falsos positivos y falsos
   negativos en las dos direcciones (queries «sin guardia» que delegaban en un helper;
   campos «sin label» que sí tenían).
4. **La fecha de una variable de entorno no prueba cuándo empezó a cobrar una tienda.**
   Deduje que unos pedidos de prueba «no tenían dinero real» y eran cobros reales del
   dueño. **Antes de calificar un dato de falso, preguntar.**
5. **Verificar en producción SIEMPRE**, y por el camino que el usuario usa de verdad. Un
   arreglo de rendimiento verificado midiendo cabeceras y HTML daba todo correcto — y
   había roto un camino de login que nunca se probó.
6. **Nunca meter una escritura real dentro de un script de sondeo de producción.** *(AirSoft)*
   Escribí un bloque de comprobación que habría creado **12 reservas reales** en el evento de
   dos días después; lo paró el clasificador de permisos, no yo. Un sondeo se escribe para
   LEER; si hace falta escribir, va aparte y se decide a conciencia.
7. **Probar los topes contra el deployment de DEV**, no contra producción. `npx convex dev
   --once` empuja las funciones y se llaman por HTTP directo. Para limpiar después, una
   `internalMutation` temporal que **no se commitea**: se crea, se corre, se borra y se vuelve
   a empujar. Así el repo no se queda con una función de borrado que nadie pidió. *(AirSoft)*
8. **Las capturas a mitad de la animación de entrada salen sin las imágenes**, aunque el DOM
   diga `complete: true` y `opacity: 1`. Ya estaba anotado y **volvió a pasar**: casi reporto
   como rota una foto que se veía perfecta un segundo después. Repetir la captura antes de
   dar por roto nada visual.
9. **Un control de acceso «pasa» si el dato que debía proteger no existe.** Sembrar primero y
   creerle después. Corolario nuevo: probar mutations de escritura con argumentos **válidos** y
   luego **leer la base** — con argumentos vacíos Convex falla en la validación antes de
   ejecutar la guardia, y eso no prueba nada. *(AirSoft)*

## 9. Checklist base pasapalos.cl (2026-10-08) — la tienda más corregida
Auditoría completa de pasapalos-cl (Supabase + Mercado Pago, linaje akim) destilada en un checklist
reutilizable: `~/.claude/cerebro/tiendas-checklist-base-pasapalos.md` (secciones A–L: rutas abiertas,
dinero, RLS, XSS, deps, rendimiento, UX, a11y, SEO/Google, correo/DNS/ops, método, tienda nueva).
Scripts: `Documents/pasapalos-cl/scripts/auditoria/` (rls-anon, contar-render, lh, monitor-pedido).
Patrón nuevo más caro: **escribir un store global durante el render** → navegación cliente de 5-6 s
(React reinicia la transición hasta su vencimiento). Revisar en TODAS las tiendas. Decisión del
usuario: pasapalos será la base de las próximas tiendas.

## 2026-10-14 — Plantilla de tiendas = pasapalos-cl (reemplaza a akim)
Rendimiento Next 16 que se repite en toda tienda:
- `useSearchParams` en página estática vacía el HTML; aislarlo en un componente con su propio `<Suspense fallback={null}>`
  y NO envolver el contenido en otro Suspense (queda en `div hidden S:0` hasta un reveal tardío). Tienda LH 76→91.
- SDK Supabase perezoso (sin cookie de sesión no se descarga); checkout con esqueleto útil en el HTML (LH 66→92-95).
- Admin: `getClaims()` (JWT ES256 local) + caché corta de perfil; funciones Vercel en la región de la BD.
- Lighthouse: comparar LCP observado vs simulado antes de tocar imágenes.
Detalle y lista de restos de mascotas a limpiar al clonar: `~/.claude/cerebro/tiendas-patrones-desde-2026-08-24.md`.

## Pagos fallidos: retornos de pasarela + recuperación (2026-10-23, akim)
- Mapear TODOS los retornos de la pasarela según su doc oficial (Webpay: timeout 4 min vuelve sin token; error de
  formulario trae token_ws+TBK_TOKEN). Un retorno no reconocido = cliente ve "error" y se va.
- Nunca decir "no vuelvas a pagar" sin confirmar con la pasarela que hubo cobro.
- Recuperación estándar: banner WhatsApp con #pedido al volver + correo automático 2×/día (reintentar con carrito
  rearmado + WhatsApp) + resumen al dueño. Detalle: `~/.claude/cerebro/tiendas-patrones-desde-2026-08-24.md`.
