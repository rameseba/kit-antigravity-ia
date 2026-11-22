## ⚠️⚠️ AUDITORÍA DE PIEL Y TRIGO (2026-08-22) — 13 patrones para revisar en TODA la familia
> **Qué es:** auditoría de piel-y-trigo (ago-2026): hallazgos que aplican a la familia Convex.
> **Actualizado:** 2026-09-01


Sesión larga activando el cobro real de Mercado Pago en `piel-y-trigo-cl` y arrancando una
auditoría completa. Todo lo de abajo se encontró **en producción, con la tienda cobrando**, y casi
todo es de la plantilla, así que hay que buscarlo en las demás. Detalle en la memoria del
proyecto (`mercadopago-pago-real-2026-08-22.md` y `auditoria-fase1-2026-08-22.md`).

### Pasarela Mercado Pago

1. **⚠️⚠️ El webhook lee `data.id` solo del CUERPO → ningún pago se confirma NUNCA.** Mercado Pago
   firma el `data.id` que viaja en la **query string**: así lo leen todos sus SDK oficiales
   (`req.query["data.id"]`, `$_GET["data_id"]`). Con el valor del cuerpo la firma no cuadra y se
   responde 401: el pedido queda `pendiente` para siempre, sin correo al cliente, sin aviso al
   equipo y sin quemar el cupón. **Chequeo:** mandar una notificación firmada con `data.id` SOLO
   en la query; si da 401, está roto. Arreglo: probar ambas fuentes y también la variante en
   minúsculas (MP la exige con ids alfanuméricos).
2. **El `ts` de la firma puede venir en MILISEGUNDOS.** La doc muestra segundos. Si se asume
   segundos, la comprobación de frescura falla siempre y **se rechazan todas** las notificaciones.
   Normalizar solo para comparar; el manifiesto usa el `ts` literal.
3. **`back_urls` y `notification_url` armadas con el header `Origin`.** Lo controla quien llama:
   con un `Origin` falso se obtiene un enlace de pago REAL de la tienda que devuelve al comprador
   a un sitio ajeno. Y apex vs `www` generan URLs distintas. Usar `NEXT_PUBLIC_SITE_URL`.
4. **⚠️⚠️ "Anular compra y volver" deja el pedido colgado en `pendiente`.** Doble causa, las dos de
   la plantilla: (a) `buildPreferenceBody` escribe `status=cancelado` en `back_urls.failure` pero
   el manejador de retorno solo reconoce `rechazado|rejected|failure|null|anulado|error` — **la
   palabra que escribe el propio código no está en la lista**; (b) la cancelación se hacía con un
   **server action lanzado sin `await`**, y el `replaceState` que limpia la URL **aborta los
   server actions** (el propio archivo ya lo documentaba para el comprobante). **Chequeo
   portable:** comparar la cadena de `back_urls.failure` contra la lista que acepta el manejador,
   y buscar server actions sin `await` en el efecto de retorno de pasarela.
5. **Falta `statement_descriptor`** → en la cartola de la tarjeta aparece el nombre de la cuenta de
   MP, no el de la tienda. Causa habitual de contracargo. Máx. 13 caracteres.
6. **El nombre del comercio en la pantalla de pago sale de la cuenta MP** (nombre de fantasía), no
   del código, y **afecta a toda la cuenta**. En Piel y Trigo decía "Estilofuzion". Lo cambia el
   dueño; Claude no puede (el panel de MP pide verificación por SMS).
7. **Mínimo de Mercado Pago Chile: $1.000** para todos los medios… **pero se vieron dos pagos de
   $50 aprobados.** No tomarlo como explicación cerrada de un botón "Pagar" gris.

### Control de acceso

8. **⚠️⚠️ El tope por IP vive en la ruta de Next y la función de Convex es PÚBLICA → se salta.**
   Reverso del patrón ya conocido de la censura. En Piel y Trigo: `users:rutTaken` (oráculo de
   RUT chilenos, que son enumerables) y `orders:lookupGuest` (devuelve nombre, teléfono, RUT y
   dirección al acertar pedido+correo). **Comprobado: 20 llamadas directas sin sesión, 0
   bloqueadas**, mientras la ruta de Next sí respondía 429. **Chequeo:** por cada ruta con
   `checkRateLimit`, mirar si la función de Convex que hay debajo es pública. Arreglo: exigir el
   secreto compartido (ninguna se llamaba desde el navegador).

### Dinero

9. **⚠️⚠️ La comuna anula la tarifa de la región.** `resolveShippingCost` busca la comuna ANTES que
   la región sin comprobar coherencia, y las tarifas por comuna son por construcción de la RM.
   Medido: Magallanes + comuna "Providencia" cobraba **$3.000 en vez de $6.990**. No hace falta
   manipular nada: basta con que el formulario conserve una comuna de Santiago al cambiar de
   región. La regla de envío gratis ya tenía el control ("la región no puede contradecir a la
   comuna"); **faltaba en el costo**.
10. **Repetir el mismo código de cupón duplica el descuento.** La lista separada por comas se
    recorre sin deduplicar: `"BIENVENIDO,BIENVENIDO"` aplica dos veces. Y
    `coupons_config.allowMultiple` suele respetarlo solo el navegador.

### Panel y datos

11. **⚠️⚠️ Guardar un producto lo saca de "prueba" y le borra el historial.** `products.upsert` usa
    `args.X ?? <literal>` **también al editar**: un guardado que no incluya `is_test` apaga la
    marca y el producto aparece en el catálogo, en el sitemap y sin `noindex`. Pasó de verdad. Con
    `inventory_log` es peor: Convex **borra el campo** cuando el valor es `undefined`, así que se
    pierde el historial completo. **Chequeo:** en la mutation de guardado, todo `args.X ?? literal`
    debe caer al valor previo del documento cuando hay `args.id`.
12. **El webhook pide a MP el medio de pago, los últimos 4 dígitos y el código de autorización…
    y no los guarda.** Estaban hasta declarados en el tipo. Es justo lo que hace falta para
    conciliar un cobro o responder un reclamo. Otras tiendas de la familia sí los muestran.
13. **El formulario del checkout se guarda con debounce (400 ms) → el ÚLTIMO campo escrito se
    pierde** al volver de la pasarela. Se nota con el RUT, que se completa al final. Forzar el
    guardado antes de redirigir.

### Técnicas de auditoría que valen para cualquier tienda de la familia

- **Auditar el dinero contra producción SIN crear pedidos:** mandar a `/api/checkout` un `amount`
  menor al real; responde **400 `TOTAL_MISMATCH`** con su propio `{shipping, discount, subtotal,
  expectedTotal}` y no crea nada. Es la forma barata de medir despacho y descuentos en vivo.
- **Probar si una función de Convex está expuesta de verdad:** sacar la URL pública de los bundles
  (`/_next/static/chunks/*.js`, **no** del HTML) y hacer
  `POST <convex>/api/query` con `{path:"modulo:funcion", args:{}, format:"json"}`. Es exactamente
  lo que puede hacer cualquier visitante.
- **Leer la base sin sesión ni secreto:** `npx convex data <tabla> --prod --limit N` (usa la deploy
  key). Sirve para comprobar `stock_deducted`, totales y estados reales.
- **Inventario del repo antes de auditar:** contar páginas, rutas API, funciones de Convex y
  clasificarlas por guardia. En Piel y Trigo dio 40 páginas, 30 rutas, 103 funciones (85 públicas).

### ⚠️ Lecciones de método (errores propios de esta sesión)

- **Una prueba local que pasa NO prueba que el arreglo funcione en producción cuando lo que falla
  es una carrera contra la latencia.** El arreglo de la cancelación pasó en local (1 ms) y estaba
  roto en producción (el abort ganaba). Los efectos de retorno de pasarela hay que probarlos en
  producción.
- **Comparar dos respuestas de error da "iguales" y parece un éxito.** Comparé dos `429` y concluí
  que un arreglo funcionaba. **Mirar el `status` antes que el valor.**
- **Un grep de "¿tiene guardia?" da falsos positivos y falsos negativos.** Marqué 7 rutas
  `/api/admin/*` como "sin control" y en realidad todas mandan el token de sesión; y marqué como
  "sin guardia" funciones que delegan en un helper (`canAccessTicket`, `canSeeFullOrder`). Hay que
  abrir el archivo antes de afirmar.
- **Cuidado con las utilidades de QA propias.** Una utilidad que reescribía precio y stock de un
  producto existente devolvió el stock a su valor inicial a mitad de una prueba y borró el
  descuento de una compra real; parecía un bug de la tienda y era mío.
- **Las pruebas agotan los topes por IP de la propia tienda** y luego los controles legítimos dan
  429. Dejar ventana (15 min) antes de concluir que algo está roto.

### Cómo revisar esto en otra tienda de la familia

Orden sugerido, de más barato a más caro: (1) sonda del modo simulado de la pasarela; (2) firma
del webhook por query string; (3) `grep` de `args.X ?? literal` en la mutation de productos;
(4) por cada `checkRateLimit`, comprobar si la función de Convex de debajo es pública; (5) sonda
`TOTAL_MISMATCH` con comuna y región contradictorias; (6) cupón repetido; (7) anular en la
pasarela y mirar si el pedido queda `cancelado`.


## ⚠️ AUDITORÍA COMPLETA DE PIEL Y TRIGO (2026-08-23) — 6 fases cerradas

Detalle en la memoria del proyecto (`fase1-verificada-2026-08-23.md` … `fase6-infra-2026-08-23.md`
y `barrido-familia-2026-08-23.md`). Lo que sirve para las demás tiendas:

**⚠️⚠️ El JSON-LD de la ficha puede publicar a Google un precio 100 veces menor que el feed.** En
`piel-y-trigo-cl`: base de datos **12.350 CLP**, JSON-LD **123,50 CLP**, `/api/google-feed` y
`/api/seo/google-merchant` **12.350**. Dos precios contradictorios para la misma ficha → rich
snippets falsos y desajuste feed↔página de destino, que es motivo de sanción en Merchant Center.
Causa: un comentario que afirmaba que los precios están en centavos, la convención de la tienda de
la que salió la plantilla. **OJO, NO es «quitar el ÷100» en todas partes:** en
`beautygangworld.com` el ÷100 es CORRECTO porque esa tienda sí cobra en centavos de CAD
(comprobado: declara 38,03 y muestra 38,03). **La regla es que el JSON-LD, el precio visible y el
feed digan el MISMO número.** En el mismo bloque suele haber un `shippingDetails` con valor `0`
hacia `"CA"` (Canadá) — las dos cosas falsas fuera de esa tienda.

**⚠️ `generateMetadata` que lee `searchParams` vuelve dinámica la ruta ENTERA, sin aviso.** En
Piel y Trigo `/tienda` era la única página que nunca salía del CDN (`private, no-store`, MISS
siempre) pese a tener su `export const revalidate = 3600`, que quedaba como código muerto. Chequeo:
en el build, una ruta de catálogo marcada `ƒ (Dynamic)` cuando debería ser `○`/`●`.

**⚠️⚠️ Al volver cacheable una ruta, el catálogo puede quedar VACÍO para quien no ejecuta
JavaScript.** Si el componente de listado usa `useSearchParams()` dentro de un `<Suspense>`, en
ruta **estática** Next se salta la prerenderización de ese subárbol y sirve **el fallback**. En
Piel y Trigo el markup de `/tienda` pasó a traer **0 de 26 productos** (los 26 viajaban solo en el
payload de hidratación) y ningún `<h1>`. Importa por la política de dejar pasar a los agentes de
IA: varios no ejecutan JS. Arreglo: que el fallback del Suspense sea el catálogo real renderizado
en servidor. **Chequeo:** quitar los `<script>` del HTML ANTES de contar
(`re.sub(r"<script.*?</script>", "", html, flags=re.S)`) — un grep sobre el HTML entero da 26/26 y
parece sano.

**⚠️ `orders.listMineWithGuests` devolvía el pedido SIN censurar.** Query pública: se le pasa un id
de pedido y entregaba nombre, correo, teléfono, RUT, dirección y comentarios de entrega. Es el
mismo agujero que `getById` ya cerraba con `redactOrder`, dejado abierto en la query de al lado.
Los ids circulan en las URL de retorno de la pasarela y en los correos. **Ojo al probarlo:** la
query excluye los pedidos `pendiente`, así que hay que usar uno pagado o parece que no hay bug.

**⚠️ `NEXT_PUBLIC_MOCK_GATEWAY` en Production es una bomba.** Aunque `isMockGateway()` compare con
`=== "true"` estricto, basta cambiar el valor para que la tienda **deje de cobrar sin que nada
avise**. Borrada en `piel-y-trigo-cl` el 23-ago. **`imperio-morales` la tenía** (auditoría del
17-ago): revisar. Claude no puede borrarla — el clasificador bloquea modificar variables de
entorno, y hace bien; la corre el dueño.

**⚠️ `vercel logs --follow` NO entrega las peticiones.** Conecta y dice `waiting for new logs...`
pero no sale nada; comprobado generando tráfico real y contrastando con la API, que sí lo veía.
Para seguir algo en vivo: `vercel logs --json -n 50` **en bucle**, deduplicando por el `id` de cada
línea. Hay un vigía ya hecho y probado en `piel-y-trigo-cl/scripts/qa/watch-pago.mjs` (+
`PAGO-REAL.md`), portable a cualquier tienda con `QA_CONVEX_URL` y `QA_SITE_URL`.

**⚠️ En estas plantillas 1 rem NO son 16 px.** En Piel y Trigo la raíz está en **14,4 px**, así que
cada medida de Tailwind vale un 10 % menos de lo que sugiere su nombre: `h-10` da **36 px**, y para
un objetivo táctil de ~44 hace falta `h-12`. Sólo se ve **midiendo el resultado**, no escribiéndolo.

**⚠️ Medir el móvil de verdad:** `resize_window` **no cambia el viewport** (`innerWidth` se queda
en el del escritorio). Lo que sí funciona: inyectar un **iframe del mismo origen** de 390×844 y
medir dentro — las media queries responden al tamaño del iframe y el DOM es legible.

**Restos de OTRAS tiendas escondidos en los datos de ejemplo.** `src/lib/locations.ts` de Piel y
Trigo traía cargada una sucursal **real de Arias Sport** (dirección, coordenadas, horario y enlace
al mall). No la renderizaba nadie, pero bastaba montar esa sección para publicar una tienda ajena.
Chequeo: `grep -rn` del nombre de las otras tiendas sobre `src/lib/` — no sale en una revisión
visual porque no se muestra.

**Textos de la tienda anterior en sitios que SÍ se ven:** la meta description de **todas** las
fichas («cosmética y skincare con actitud»), el eslogan del panel de sesión («Tu belleza, tus
reglas») y el placeholder del giro en facturación. Y `/tienda` sin `og:image` porque su layout
declaraba un `openGraph` **parcial**, que **no se fusiona con el del layout raíz: lo reemplaza**.

