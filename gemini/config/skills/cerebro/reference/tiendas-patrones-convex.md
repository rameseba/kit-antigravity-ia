# Familia de tiendas (negocio del usuario)
> **Qué es:** patrones y bugs de las tiendas Convex (auth, público, egress).
> **Actualizado:** 2026-09-01

El usuario arma tiendas online para clientes distintos (nichos distintos: mascotas, ropa,
belleza, etc.), y **la mayoría heredan el código base de `akim-pet-market-web`** (proyecto
original, en `C:\Users\<USUARIO>\Documents\akim-pet-market-web`), cada una con su rebrand,
paleta, catálogo y ajustes propios. Ejemplos confirmados: `arias-wear-cl`, `beauty-gang-world-com`
(ver su memoria en `C:\Users\<USUARIO>\.claude\projects\C--Users-<USUARIO>-Documents-beauty-gang-world-com\memory\`
para el detalle de una migración real Supabase→Convex sobre esta base). Stack típico: Next.js
App Router + Convex (o Supabase en las más viejas) + Stripe/Mercado Pago/Webpay según el país +
Cloudinary + Resend.

**Objetivo del usuario (2026-07-22, no iniciado aún):** no quiere tener que re-explicar el
contexto de este "linaje" de tiendas en cada proyecto nuevo, y a futuro quiere un **repo
plantilla real**: cuando pida "hagamos otra tienda", la idea es clonar el código base entero y
solo completar la info específica (marca, paleta, catálogo, variables de entorno, pasarela de
pago del país) en vez de rehacer/re-derivar cada pieza desde cero. Aún no se construyó esa
plantilla — es la dirección a la que apunta el trabajo, útil tenerlo en cuenta al tocar
cualquiera de estos proyectos (evitar decisiones que hagan más difícil templatizar después).

**Cómo usar esto:** si el usuario pide una tienda nueva, preguntar primero si debe partir de
`akim-pet-market-web` (o de la plantilla, cuando exista) en vez de un proyecto en blanco. Usar
`graphify` (grafo de conocimiento local, ver sección de abajo) para comparar rápido la
estructura entre proyectos de esta familia sin tener que releer cada repo entero.

**⚠️ Patrón de riesgo confirmado — tablas de Convex con datos que el cliente guarda pero el
admin nunca ve (2026-08-02, encontrado y arreglado en `piel-y-trigo-cl`, detalle completo en su
memoria `project-template.md`).** El schema de Convex de esta familia viene de una cadena de
migraciones/clones (Supabase de Arias Wear → Convex de BeautyGangWorld → clonado a Piel y Trigo,
y de ahí a cualquier tienda nueva que parta de ese código). Se encontraron y arreglaron 11 gaps
reales en Piel y Trigo: favoritos/carrito/direcciones de un usuario que no llegaban al panel
admin (bug de merge en frontend, o directamente faltaba el query admin-only — solo había versión
self-service por `getCurrentUser`), un campo (`inventory_log`) que se perdía en cada guardado por
una whitelist de mutation incompleta, un campo de invitados nunca copiado al admin, y una tabla
(`categories`) sin ningún CRUD real. **Antes de tocar a fondo cualquier otra tienda Convex de esta
familia** (`criadero-cachorros`, `Games-god`, `Barberia-cl`, `Picker-Cal`, `ua-antofa-cl`, o una
nueva), vale la pena correr la misma auditoría: pedirle a un sub-agente Explore que lea el
`schema.ts` completo, liste cada tabla, y para cada una confirme qué la escribe, qué la lee, si
hay pantalla admin real que la muestre, y si el formulario cliente que la llena llama de verdad la
mutation (no un stub/`alert()` suelto). Buscar especialmente: queries self-service sin versión
admin por `userId`, campos del doc de `users` que el query de listado admin no expone, frontend
que arma datos "a mano" desde otra fuente en vez de leer la tabla real, y bugs de merge que pisan
un array ya resuelto por el backend.

**⚠️⚠️ Patrón de riesgo CRÍTICO confirmado — checkout/pagos de Convex confían en el navegador,
dinero real en juego (2026-08-02, encontrado y arreglado en `piel-y-trigo-cl`, commit `a89faf5`,
detalle completo en su memoria `project-template.md`).** Mismo linaje de código que el patrón de
arriba, pero esta vez en el flujo de pago. Se encontraron y arreglaron 3 vulnerabilidades reales:
(1) `/api/checkout` nunca recalculaba precio/monto contra la base de datos — cualquiera podía
mandar `price:1` en cada ítem y comprar productos reales por casi nada, o `amount:0` para que el
pedido quedara "pagado" sin pasar por la pasarela; (2) el webhook de pago tenía una rama "mock"
(simulación) que no validaba NADA — cualquiera podía POSTear `isMock:true` y marcar un pedido
como pagado, en producción real, sin pagar; (3) la mutation de Convex que marca pedidos como
pagados no tenía ningún control de acceso — como la URL de Convex es pública (va en el bundle del
navegador), cualquiera podía llamarla directo. **Antes de tocar a fondo o dar por segura cualquier
otra tienda de esta familia con checkout/pagos real** (`Games-god` con MercadoPago/pagos reales es
la más urgente por revisar — vende productos reales con dinero real; luego cualquier otra con
carrito+pasarela propia), correr la misma auditoría: pedirle a un sub-agente Explore que lea la
ruta de checkout, el webhook de la pasarela, y toda mutation de Convex que cambie el estado de un
pedido a "pagado", y confirme para cada una: ¿el precio/monto final se recalcula 100% server-side
desde la base de datos real (no lo que manda el cliente)? ¿el webhook valida firma/autenticidad
real de la pasarela, sin atajos "mock" que un atacante pueda activar desde afuera? ¿la mutation
que marca "pagado" tiene algún control de acceso (rol staff, o secreto compartido server-only),
o es una `mutation` pública callable por cualquiera con la URL pública de Convex? El fix aplicado
acá para el punto 3 fue un secreto compartido (`ORDER_STATUS_SECRET`) seteado tanto en el env de
Convex (`npx convex env set ... --prod`) como en Vercel (Project Settings → Environment
Variables) — **hay que setearlo en AMBOS lados ANTES de pushear el código que lo exige**, si no
el checkout se rompe en producción hasta que Vercel tenga la variable y redeploye.

**⚠️⚠️ Patrón de riesgo CRÍTICO confirmado en 2 tiendas — Convex Auth secuestra cualquier
`?code=` de la URL, lo que ROMPE todo link de verificación de cuenta / reset de contraseña
(2026-08-04, encontrado y arreglado en `piel-y-trigo-cl` commits `1a75786`/`3d68d64` y en
`beauty-gang-world-com` commit `a0cfd50`, ambos en producción y verificados).**
El `AuthProvider` de `@convex-dev/auth/react` (v0.0.94; se monta vía
`ConvexAuthNextjsServerProvider` en `src/app/layout.tsx`) corre un `useEffect` en el montaje
que lee `?code=` de `window.location.search` asumiendo que es un **authorization code de
OAuth**: lo BORRA de la URL con `history.replaceState` y lo canjea con
`signIn(undefined, {code})` contra el provider equivocado. Ver
`node_modules/@convex-dev/auth/dist/react/client.js` ~línea 246.
**Síntoma:** el usuario hace clic en "Activar mi cuenta" / "Restablecer contraseña" del correo,
llega a la página **sin el código** en la URL y siempre ve "El enlace es inválido o ha
expirado" — para siempre, con cualquier código, aunque el backend esté perfecto.
**Fix:** que el correo mande el código en **otro parámetro (`?otp=`)**, y que la página lea
`otp ?? code`. La prop `shouldHandleCode` existe para desactivar el secuestro pero **NO sirve
en Next App Router**: hay que pasarla desde el layout (server component) y una función no
cruza el límite servidor→cliente.
**Chequeo rápido en cualquier tienda Convex de la familia:**
`grep -rn "?code=" convex/ src/` — si un correo de auth arma un link con `?code=`, está roto.
Complementos que se arreglaron junto al bug (revisarlos también en la próxima tienda):
- El correo trae un código de 8 dígitos pero **la web no tiene dónde pegarlo** → agregar campo
  manual + botón "Reenviar código" (`signIn("password",{flow:"email-verification",email})` SIN
  `code` regenera y reenvía; para reset, `flow:"reset"`).
- **Login con cuenta sin verificar:** Convex Auth NO tira error — reenvía el correo y devuelve
  `{signingIn:false}`. Si el front no mira ese valor, cierra el panel como si el login hubiera
  funcionado y el usuario queda deslogueado sin explicación.
- **En producción Convex oculta el mensaje de todo error no-`ConvexError`** y devuelve
  `"[Request ID: ...] Server Error"`. Si el front hace `setError(err.message)`, eso es lo que
  ve el cliente. Traducir siempre.
- Los correos de auth de esta plantilla (`convex/ResendVerify.ts`, `convex/ResendOTP.ts`) traen
  el **rosado `#E6007E`** hardcodeado de la tienda original — no comparten diseño con
  `src/lib/email.ts`. Para reusar el diseño real desde Convex: importar con **ruta relativa**
  (`../src/lib/email` o `../src/config/brand`); el alias `@/` NO lo resuelve el bundler de
  Convex, pero importar archivos fuera de `convex/` sí funciona (validar con
  `npx convex dev --once`, que empuja al deployment de DEV, no a prod).

**⚠️⚠️ Patrones confirmados en el QA del recorrido del CLIENTE (2026-08-04, `piel-y-trigo-cl`,
9 bugs reales encontrados probando en producción; detalle completo en `QA-2026-08-04.md` del
repo y en su memoria `session-2026-08-04-qa-completo-cliente.md`). Todos son de la plantilla,
así que hay que buscarlos en CUALQUIER tienda de la familia:**

1. **El dominio muerto/viejo queda hardcodeado en los CORREOS y en el SEO, no solo en un par de
   archivos de config.** En Piel y Trigo `pielytrigo.cl` (nunca comprado) estaba en **19
   archivos**: el link "Seguir mi compra" del correo de confirmación de pedido, el de
   seguimiento de envío, el correo personalizado al cliente, el del newsletter, el aviso al
   staff, **el JSON-LD de `/tienda` y de cada producto**, `api/seo/indexnow` (notificaba a los
   buscadores el host equivocado) y el botón de compartir producto. Se confirmó en vivo abriendo
   Gmail: un correo real ya enviado tenía el botón apuntando al dominio muerto.
   **Chequeo:** `grep -rn "<dominio-viejo>" src/ convex/` — no basta con revisar `brand.ts`.
   **Fix correcto:** construir los links desde `brand.url` (`src/config/brand.ts`), que es la
   fuente única declarada de la plantilla, no repetir la URL literal.
2. **La trampa de los tipos y componentes GEMELOS — causa crashes de página completa.** La
   plantilla arrastra DOS tipos `Product` con el mismo nombre (`@/types/database` = documento
   crudo de Convex con `price`/`stock`/`category` **string**, vs `@/types/catalog` = mapeado con
   `base_price`/`category` **objeto**) y DOS componentes de tarjeta (`components/ProductCard.tsx`
   legacy, que consume el crudo, y `components/product-card.tsx` nuevo, que consume
   `ProductCardData`). Mezclarlos hace que React reciba un objeto como hijo y tire el
   **error #31**, que en producción se ve como el error boundary genérico ("Algo no salió bien")
   y tumba la pantalla entera. Acá tumbaba `/cuenta/favoritos`.
   **Chequeo:** buscar quién importa `lib/catalog` (`getProducts`/`getProductsByIds`, cuyo
   `mapProduct()` es el que convierte `category` en objeto) y se lo pasa al `ProductCard` legacy.
   **Ojo Windows:** `ProductCard.tsx` y `product-card.tsx` son el MISMO archivo en un filesystem
   case-insensitive pero DOS distintos en el build de Vercel (Linux) — riesgo real de que local
   y producción se comporten distinto.
3. **El botón "Pagar" del resumen lateral se salta el wizard del checkout.** Llama
   `handleProceedToPayment()` directo, así que cualquier campo validado solo "por paso" (en
   Piel y Trigo, las indicaciones de despacho rotuladas **(OBLIGATORIO)**) se guarda vacío. Se
   confirmó creando un pedido real y leyéndolo con `npx convex data orders --prod`
   (`delivery_comments: ""`). **La validación tiene que vivir dentro de esa función**, no en el
   paso del wizard.
4. **El timeline de seguimiento marca el estado `pendiente` como "Pago aprobado".** Está
   duplicado en DOS archivos (`components/account/OrderTrackingDetail.tsx` y
   `(store)/cuenta/nologin/page.tsx`), y la notificación in-app de `convex/orders.ts` dice
   "fue recibido y está en proceso". Resultado: **un cliente que abandonó el pago cree que pagó**.
   En esta plantilla `pendiente` = pago NO confirmado, `procesando` = pagado.
5. **El autocompletado de direcciones deja vacío un campo `required`.** El callback hacía
   `setNewAddrRegion("")` descartando el `data.city` que el propio componente ya resuelve; como
   el campo es `required`, **todo cliente que use el buscador** (el camino por defecto) se traba.
   Ojo al nombre confuso: el campo rotulado **"Ciudad" está ligado a la variable `newAddrRegion`**.
6. **Soporte solo notifica al crear el ticket, no cuando el cliente RESPONDE.** Si el cliente
   escribe de nuevo en un ticket ya abierto, nadie se entera y la consulta muere. Además existe
   una ruta `/api/support/notify` (correo al staff) que es **código muerto: nadie la llama**.
7. **Residuos de marca de la tienda anterior en el punto de pago**: el placeholder del cupón
   decía `BIENVENIDA, GANG10...` (GANG10 = BeautyGangWorld) — lo ve todo cliente que llega a
   pagar. Buscar también links a rutas inexistentes (`/productos` cuando la ruta real es
   `/tienda`) y `title` de páginas que repiten el sufijo que ya agrega el template del layout.

8. **El panel de pedidos esconde los pedidos PENDIENTES y la tarjeta que los cuenta siempre
   marca 0.** `convex/orders.ts::listAll` filtraba `status !== "pendiente"`, así que
   `/admin/pedidos` mostraba "No se encontraron pedidos" aunque existieran, y su propia tarjeta
   "Pagos pendientes · Esperando confirmación" era **matemáticamente imposible** que marcara
   otra cosa (se calcula en el frontend sobre esa misma lista). El staff no puede ver ni
   gestionar el pedido de un cliente cuyo pago quedó a medias, y el cron de limpieza lo cancela
   a las 48 h sin que nadie lo vea. **Ojo:** la query hermana `listMineWithGuests` tiene el
   mismo filtro pero ahí SÍ es intencional (es el "Mis Pedidos" del cliente) — no tocarla.
9. **Un dato malo puede estar guardado en la tabla `settings` de Convex, no en el código.** En
   Piel y Trigo, *después* de arreglar el dominio muerto en los 19 archivos, **Ajustes → Tienda
   General seguía teniendo `contacto@pielytrigo.cl` guardado en la base**, y ese es el valor que
   los correos insertan como contacto (`settings.support_email`). **Regla: tras arreglar un
   dominio/marca/teléfono en el repo, revisar SIEMPRE si el mismo dato vive además en
   `settings`** (`npx convex data settings --prod`) — el fix del código no lo alcanza.
   Y **no puedo cambiarlo yo**: el clasificador bloquea modificar ajustes de cuenta desde el
   panel (correctamente); hay que pedírselo al dueño con los valores exactos.

**⚠️⚠️ Patrón de riesgo CRÍTICO confirmado — la "limpieza" de datos sensibles vive en el server
action de Next y NO en la query de Convex, así que se esquiva llamando a Convex directo
(2026-08-05, encontrado y arreglado en `piel-y-trigo-cl`, commit `a48d0b2`).** Misma familia de
código. `settings.get` es una query PÚBLICA que devuelve el blob `web_content` entero, y la URL
de Convex viaja en el bundle del navegador. Había una función `fetchSettingsFromServer`
(`src/app/actions/settings.ts`) que borraba `notification_config` y las credenciales de pago
antes de devolverlo… **pero solo para quien pasara por ese server action**. Llamando la query de
Convex directo salía todo, incluidos **todos los códigos de cupón vigentes** (cualquiera compra
con descuento sin que se los den) y los correos del staff.
**Regla general que se desprende:** en esta plantilla, cualquier censura/autorización que viva
en `src/app/actions/*` o en una ruta `/api/*` es **decorativa** si la función de Convex por
debajo es `query`/`mutation` pública — hay que moverla DENTRO de la función de Convex.
**Chequeo rápido:** `grep -rn "sanitiz\|delete .*config" src/app/actions/` y, por cada dato que
ahí se borre, confirmar que la query de Convex correspondiente también lo censure.
**Trampa al arreglarlo:** el checkout **validaba el cupón en el navegador leyendo la lista
completa**, así que censurarla a secas deja a los clientes sin poder canjear. El fix correcto es
una query que valida UN código exacto (`findCouponByCode`) — sirve para canjear, no para
enumerar — más una `getFull({secret})` con el secreto compartido para lo que el servidor sí
necesita completo (`/api/checkout` calcula el descuento; los correos necesitan `admin_emails`).
**Mutations de reseñas sin dueño (mismo commit):** `reviews.create` aceptaba cualquier
`order_id`+`product_id`. Los ids de pedido circulan en URLs de retorno de pago y en correos
reenviados → reseñas sobre pedidos ajenos, de productos que el pedido ni traía, y con
`is_verified_buyer` puesto por el navegador. Exigir: pedido existente, **pagado** (`pendiente`
NO lo está), que contenga el producto, y sesión del dueño si el pedido tiene `userId`. Y ojo:
la ruta `/api/reviews` POST **no reenviaba el token de sesión** — sin eso, endurecer el backend
bloquea a todos los clientes registrados.

**⚠️⚠️ Patrón CRÍTICO de dinero — el servidor acepta el cupón sin comprobar sus reglas
(2026-08-05, `piel-y-trigo-cl` commit `18a82a6`).** `/api/checkout` usaba el descuento de los
cupones solo como *"cota superior"* para detectar totales inflados hacia abajo, y el comentario
del código afirmaba que las restricciones "se aplican en el flujo de canje" — **pero ese flujo
vive en la pantalla de pago, o sea en el navegador**. Llamando la ruta directamente se podía
**reusar infinitas veces un cupón de un solo uso** (el de bienvenida que se manda por correo),
canjear uno **vencido**, o usar uno **reservado al equipo**. Lo peor: el panel de esta plantilla
ofrece un tipo de cupón **"Bypass Mercado Pago (Pago Simulado $0)"** — con ese código, productos
reales gratis. **Chequeo en cualquier tienda de la familia:** buscar dónde se calcula el
descuento server-side y confirmar que valide `used`, `startDate`/`endDate`, `roleRequirement` y
`assignedEmail`, **resolviendo el rol desde la sesión** (`users.currentUser` con el bearer token),
no desde el cuerpo de la petición.

**⚠️⚠️ Patrón confirmado — las funciones que avisan al equipo de una VENTA son código muerto
(2026-08-05, `piel-y-trigo-cl` commit `f30329a`).** `sendOrderConfirmationEmail` y
`createNewOrderNotificationsServer` (`src/app/actions/orders.ts`) están completas y funcionan…
pero **ninguna ruta las llama**: ni `/api/checkout` ni el webhook de la pasarela. Resultado: la
tienda no avisa de una compra **por ningún canal** (ni correo al equipo, ni campana del panel),
mientras la pantalla Ajustes → Notificaciones promete literalmente "reciben un duplicado del
correo de confirmación de cada pedido". **Chequeo:**
`grep -rn "sendOrderConfirmationEmail\|notifyNewOrder" src/` y confirmar que haya un llamador
real FUERA del propio archivo de acciones. Es el mismo patrón que
`/api/support/notify` (ver arriba): en esta plantilla hay varias piezas terminadas y nunca
cableadas — **buscar siempre el llamador, no basta con que la función exista**.

**⚠️⚠️ Dos bugs de dinero/inventario del mismo linaje, encontrados SOLO al mover un pedido real
(2026-08-05, `piel-y-trigo-cl`, commits `9037531` y `ffc126e`):**
1. **Cancelar un pedido pagado desde la PASARELA no devuelve el stock.**
   `orders.setOrderStatus` (la del webhook) descuenta al pasar a `procesando` pero no restaura al
   cancelar — y un rechazo/devolución/contracargo llega como `cancelado`. El panel
   (`orders.update`) y el borrado sí restauraban, así que **el resultado dependía de por dónde se
   cancelara** y el inventario se encogía solo. Chequeo: comparar las ramas de cancelación de
   TODAS las mutations que cambian estado, no solo la del panel.
2. **Abandonar el pago quema el cupón de un solo uso.** `consumeCoupons` se llamaba al **crear**
   el pedido, aunque quedara `pendiente`. El cupón de bienvenida que se manda por correo es de un
   solo uso → un cliente que cierra el checkout lo pierde para siempre. Y es **invisible desde el
   panel**, porque el contador "usado N veces" solo cuenta pedidos PAGADOS. Debe quemarse cuando
   el pago se confirma (webhook / flujo de costo cero), y la lista debe marcar "Agotado" usando
   la bandera `used`, no el contador.

**⚠️ Cloudflare confirma el patrón del captcha en OTRAS tiendas del usuario (2026-08-05).** En el
panel de Turnstile de la cuenta hay 6 widgets (Akim, Imperio Morales, Arias-wear, Pasapalos,
BeautyGangWorld, rameseba-contacto) y **Cloudflare avisa solo**: *"Siteverify isn't being called
for rameseba-contacto — the forms these widgets protect remain open to bots"*. Ese aviso del
propio panel es la forma más rápida de auditar todas las tiendas de una: si dice que no se llama
a siteverify, el captcha de ese sitio es decorativo.

**⚠️ Gotcha del clasificador (2026-08-05):** editar un registro DNS en Cloudflare **vía
`javascript_tool` se bloquea**, pero hacerlo por la UI normal (clic en Edit → `computer type` →
Save) **sí funciona** cuando el usuario lo autorizó. No es un rodeo: es usar la herramienta que
corresponde. Lo que NO se hace nunca es transcribir o pegar una clave secreta (ej. el
`TURNSTILE_SECRET_KEY` recién generado) — eso queda para el dueño.

**⚠️ El captcha (Turnstile) de esta plantilla es decorativo — verificarlo en CADA tienda
(2026-08-05, `piel-y-trigo-cl`).** Dos problemas independientes: (1) `verifyTurnstile()` devuelve
`true` si falta `TURNSTILE_SECRET_KEY` ("no configurado → no bloquear"), y en Piel y Trigo la
variable **no estaba puesta en producción** → un POST a `/api/verify-captcha` con un token basura
responde `{ok:true}`. **Prueba de 10 segundos para cualquier tienda de la familia.** (2) Aunque se
configure, **sigue siendo esquivable**: el login/registro llama al SDK de Convex Auth directo
desde el navegador, así que el atacante simplemente no llama a la ruta de verificación. Para que
proteja de verdad habría que enrutar la autenticación por el servidor.

**⚠️⚠️ Patrón CRÍTICO de dinero — un método de despacho inventado deja el envío GRATIS
(2026-08-05, `piel-y-trigo-cl` commit `4c5b95e`).** `computeShippingCost` (`src/lib/shipping.ts`)
busca el método por id contra `settings.web_content.shipping_methods`; si no lo encuentra
devolvía `{cost:0, blocked:false}`. Mandando cualquier `shippingType` inventado a
`/api/checkout`: despacho **$0** y, de yapa, **el bloqueo de zonas sin cobertura nunca se
evalúa**, porque ese control vive dentro de la rama del método "variable". Confirmado con
pedidos reales en producción (quedaron guardados sin el despacho). **Chequeo en cualquier tienda
de la familia:** POST a la ruta de checkout con `shippingType:"loquesea"` y mirar el total que
queda GUARDADO en la base, no el que responde la API. **Trampa al arreglarlo:** el checkout de
esta plantilla arranca con `shippingType: "nextday"`, que **tampoco existe** entre los métodos
configurados (los reales suelen ser `domicilio` y `retiro`), así que *rechazar* el pedido rompe
compras legítimas — hay que caer al primer método de entrega activo y dejar un aviso en el log.

**⚠️⚠️ Patrón CRÍTICO — censurar una query pública ROMPE en silencio a los llamadores del
SERVIDOR, que no mandan sesión (2026-08-07, `piel-y-trigo-cl` commit `149119b`).** Es el reverso
exacto del patrón "la limpieza vive en el server action" (ver más arriba): al mover la censura
DENTRO de la función de Convex, `orders.getById` empezó a devolver el pedido **sin
`customer_email`** a todo el que no sea el dueño del pedido o staff… **incluido el webhook de la
pasarela**, que llama a Convex con un `ConvexHttpClient` sin token de nadie. Su
`confirmOrderEmail` arrancaba con `if (!order?.customer_email) return;` → **se salía siempre**.
Resultado invisible: al confirmarse un pago **no salía el correo "¡Pago confirmado!" al cliente,
no se quemaba el cupón de un solo uso y el equipo no se enteraba de la venta** — o sea, volvieron
a romperse tres arreglos anteriores sin que nada fallara ni apareciera en los logs.
**Chequeo en cualquier tienda de la familia:** por cada query de Convex que censure campos según
`getCurrentUser`, listar TODOS sus llamadores del servidor
(`grep -rn "convex.query(api\.\|fetchQuery(api\." src/app/api src/app/actions src/lib`) y
confirmar que cada uno use la variante completa con el secreto compartido
(`getAnyByIdFull({id, secret})`) y no la pública. Prueba de 10 segundos, sin leer código:
`npx convex run <tabla>:getById '{...}' --prod` — el CLI tampoco manda sesión, así que si vuelve
`redacted: true`, eso es exactamente lo que ve el webhook.
**Regla de diseño:** cuando la censura depende de la sesión, un llamador server-to-server sin
sesión es indistinguible de un desconocido. La verificación tiene que ser un **secreto
compartido**, no "confiar en que el servidor es el servidor".

**⚠️⚠️ Comprobar SIEMPRE si la tienda está corriendo con la pasarela SIMULADA (2026-08-07,
encontrado en `piel-y-trigo-cl`, en producción y con dominio propio).** Esta plantilla trae un
portal de pago falso (`/pagos/mercadopago`) que **pide número de tarjeta, vencimiento y CVV**, los
descarta, y decide el "pago" con un botón Aprobar/Rechazar; el pedido igual queda `procesando`
(pagado), descuenta stock y dispara el correo "¡Pago confirmado!". Se activa solo con que
**falte** `MERCADO_PAGO_ACCESS_TOKEN` (`isMockGateway()` en `src/lib/mercadopago.ts` devuelve
`true` si el token no está), así que una tienda puede llevar meses "vendiendo" sin cobrar un peso
sin que nadie lo note. **Prueba de 10 segundos contra producción, sin efectos secundarios:**
POST a `/api/mercadopago/webhook` con `{"isMock":true}` y **sin `orderId`** → `403 Modo mock no
habilitado` = pasarela real; `400 Falta orderId` = **está en modo simulado**. Confirmarlo mirando
Vercel → Environment Variables (que existan `MERCADO_PAGO_ACCESS_TOKEN` y
`MERCADO_PAGO_WEBHOOK_SECRET`, y que NO esté `NEXT_PUBLIC_MOCK_GATEWAY`). Activar el cobro real
exige credenciales del dueño: es un aviso, no un arreglo que se pueda hacer solo.

**⚠️⚠️ Patrón CRÍTICO de dinero — omitir un dato opcional del checkout salta el cobro Y el
control (2026-08-06, `piel-y-trigo-cl` commits `fdbd73d` y `461503a`).** Tercera vez que aparece
la misma forma en esta plantilla: **una rama que sale antes de tiempo devolviendo
`{cost:0, blocked:false}`**. Acá era la regla de **envío gratis**: se evaluaba al principio de
`computeShippingCost`, antes de resolver método y cobertura, y trataba una **comuna vacía** como
si fuera comuna urbana de Santiago. Como `shippingCommune` es **opcional** en el esquema de
`/api/checkout`, bastaba con no mandarla: despacho $0 a cualquier punto del país **y** el bloqueo
de zonas sin cobertura nunca se evaluaba (vive más abajo, en la rama del método variable).
Confirmado con un pedido real: total 33.260 a Magallanes con $0 de despacho, cuando esa región
cobra 6.990. Variante encontrada al probar el propio fix: la **comuna mandaba sobre la región**,
así que "Providencia" + región "Magallanes" seguía dando envío gratis.
**Chequeo para cualquier tienda de la familia:** en el cálculo de despacho, buscar todo `return`
que entregue costo 0 **antes** de haber resuelto la cobertura, y probar la ruta de checkout
**omitiendo los campos opcionales** (comuna, región, método), no solo mandando valores inválidos.
Mirar el total que queda **GUARDADO en la base**, no el que responde la API.
**Y probar siempre el caso legítimo después del fix** (compra que SÍ debe llevar envío gratis):
el riesgo real de endurecer esto es rechazar compras buenas.
**Nota aparte:** la misma regla suele estar **duplicada en el checkout del navegador** con el
mismo fallo — la pantalla promete "Gratis" y el servidor después cobra.

**⚠️⚠️ Patrón CRÍTICO — un INVITADO no puede comprar: el carrito se vacía al navegar
(2026-08-07, `piel-y-trigo-cl` commit `58ff614`).** El componente `SessionSync` corre en cada
carga de página y llama `syncForUser(sessionId)` sobre los stores de carrito y favoritos
(zustand + localStorage). Para un invitado ese id es **siempre null**, y la rama "logout"
(`if (!userId) { set({items: [], ownerId: null}) }`) borraba el carrito **sin comprobar si antes
había sesión**: el cliente agregaba un producto y al ir a cualquier otra página el carrito
quedaba vacío. Comprobado en producción leyendo `localStorage` antes y después de navegar.
**Fix:** limpiar solo si había `ownerId`, y no reconciliar nada mientras `useConvexAuth().isLoading`
(en ese lapso un usuario logueado también se ve como invitado). **Chequeo de 30 segundos en
cualquier tienda de la familia:** agregar un producto sin iniciar sesión, navegar a otra página y
mirar `localStorage.getItem('<tienda>-cart-storage')`.

**⚠️⚠️ Patrón CRÍTICO — fuera de Santiago no se puede completar la dirección, y las tarifas por
región son decorativas (2026-08-07, `piel-y-trigo-cl` commit `076b8f9`).** El formulario de
dirección (checkout y Mi cuenta) ofrecía **solo las 52 comunas de la Región Metropolitana** en un
`select` obligatorio, sin ningún campo de región: un cliente de otra región no podía terminar la
compra aunque el sitio anuncie "Envíos a todo Chile". Peor: el campo **rotulado "Ciudad" era el
que se guardaba como `region`**, y `region` es lo que decide la tarifa (`region_costs`), así que
`findRegionCost` nunca encontraba nada y caía al costo base del método — **las 16 tarifas por
región que el dueño configura en el panel no se aplicaban NUNCA**. **Chequeo:** abrir el
formulario de dirección y contar las opciones de comuna; si son ~52 y todas son de Santiago, está
roto. Y confirmar qué variable guarda el campo "Ciudad".

**⚠️ Patrón — la hora de corte del despacho APAGA la venta media tarde (2026-08-07,
`piel-y-trigo-cl` commit `581dabe`).** `cutoff_time` de cada método no avisaba: **desactivaba** el
método (candado, `alert` al hacer clic, y un `useEffect` que auto-seleccionaba otro). Con el envío
a domicilio cortando a las 18:00, desde esa hora hasta medianoche la única opción era "Retiro en
tienda" — y quedaba elegida sola, con costo $0, así que un cliente distraído compraba un retiro
que no quería. Lo correcto es que el corte **avise** ("Sale mañana") y que el método por defecto
sea el primero de ENTREGA, no el primero que no haya pasado su corte.

**⚠️ Falta la lista del newsletter: el formulario manda el cupón y tira el correo a la basura
(2026-08-07, `piel-y-trigo-cl` commit `1a9ae65`).** En esta plantilla `/api/newsletter` envía el
código de bienvenida por Resend y **no guarda al suscriptor en ninguna parte** — no hay tabla ni
pantalla, así que el dueño nunca tiene lista para una campaña. Se resolvió con una tabla
`newsletter_subscribers`, una mutation `subscribe` que **exige el secreto compartido** (pública
sería un formulario para llenar la lista con correos ajenos), baja por marca y no por borrado (si
se borra, la misma persona vuelve a pedir el cupón de bienvenida), y una pantalla
`/admin/newsletter` con exportación a CSV. **Recordatorio:** al agregar cualquier archivo nuevo en
`convex/` hay que correr `npx convex codegen` o `tsc` falla con "Property 'x' does not exist".

**⚠️ Comprobar SPF/DKIM/DMARC sin tocar el panel de nadie:** consulta DNS-over-HTTPS a
`https://cloudflare-dns.com/dns-query?name=<host>&type=TXT` con `accept: application/dns-json`
para `<dominio>`, `_dmarc.<dominio>`, `resend._domainkey.<dominio>` y `send.<dominio>`. En Piel y
Trigo salió todo correcto (SPF de recepción por Cloudflare, SPF de envío por `amazonses` —Resend
usa SES—, DKIM publicado y DMARC en `p=quarantine`), y como el `From` es del dominio y el DKIM
firma con `d=<dominio>`, **DMARC alinea por DKIM**. Vale la pena verificarlo antes de dar por
hecho que hay que configurarlo.

**⚠️ Patrón de dinero — elegir "Retiro en tienda" pinta GRATIS el envío a domicilio (2026-08-07,
`piel-y-trigo-cl` commit `cdfc0f8`).** La bandera que el paso 3 usa para rotular las tarjetas era
`shippingQuote.free`, o sea *"lo que cuesta el método ELEGIDO es 0"*. Retiro cuesta $0 siempre, y
**queda elegido por defecto después de la hora de corte del envío a domicilio**, así que todas las
tarjetas —incluida la de domicilio— decían "Gratis". El cliente elige domicilio creyendo que no
paga. La promoción hay que evaluarla contra un método de **entrega**, nunca contra el elegido.

**⚠️ Patrón — el catálogo ofrece "Más vendidos" y no ordena por ventas (mismo día, commit
`9200952`).** Ordenaba por `b.id.localeCompare(a.id)`, el id de Convex. No hay contador de ventas
por producto en esta plantilla, así que o se lleva la cuenta o se cambia por "Novedades"
(`created_at`), que sí es un dato real.

**⚠️ Patrón — las queries PÚBLICAS de productos devuelven el documento entero (mismo día).**
Incluye `inventory_log`: historial de inventario con el número de cada pedido, cantidades y las
notas que escribe el equipo. Viaja al navegador de cualquier visitante y queda guardado en su
`localStorage` al agregar el producto al carrito. **Chequeo:**
`npx convex run products:list '{}' --prod` y mirar si aparece algún campo interno. El panel lee
por `listAll` (staff), así que censurar las públicas no lo afecta.

**⚠️⚠️ Patrón CRÍTICO — el checkout reusa la sesión del comprador ANTERIOR (2026-08-07,
`piel-y-trigo-cl` commit `8416543`).** `/api/checkout` creaba el `ConvexHttpClient` en el ámbito
del MÓDULO y hacía `convex.setAuth(bearerToken)` dentro del handler, sin limpiarlo nunca. La
instancia se reutiliza entre invocaciones y entre peticiones simultáneas, así que el token del
último cliente logueado seguía puesto cuando entraba la compra de un **invitado**: el pedido
quedaba a nombre de un desconocido y, peor, las reglas de cupón por rol se resuelven con
`users.currentUser` desde esa misma sesión — o sea, un cupón `roleRequirement:"owner"` (el de
"Bypass Mercado Pago", total $0) se valida contra el rol ajeno. **Chequeo:**
`grep -rn "new ConvexHttpClient" src/` y ver cuál de esos módulos llama `setAuth`; si el cliente
no se crea DENTRO del handler, está roto. Mismo riesgo con cualquier cliente HTTP cuyo estado de
autenticación se declare a nivel de módulo.

**⚠️ Rutas del panel que mandan correo con destinatario libre (mismo commit).**
`notificar-tracking`, `enviar-custom-email` y `reviews/request` tomaban `customerEmail` del
cuerpo de la petición. Cualquier cuenta con rol staff —incluido `mod`, que es el rol que se le
da a un empleado— podía mandar texto libre a cualquier dirección desde el dominio verificado de
la tienda. El destinatario tiene que salir del pedido (`orders.getAnyByIdFull` + secreto
compartido). El panel ya mandaba siempre el correo del propio pedido, así que el fix no rompe
nada. **Chequeo:** buscar rutas que hagan `sendEmail({ to: <algo del body> })`.

**⚠️ Endpoints públicos que responden sobre una persona concreta y no tienen tope (2026-08-07,
commits `8416543` y `4eefc29`).** `/api/pedidos/consultar` entrega nombre, teléfono, RUT y
dirección al acertar la pareja (número de pedido + correo) — y el número corto viaja en todos los
correos; `/api/auth/rut-check` responde sí/no a "¿este RUT es cliente?". Ambos hay que limitarlos
por IP con `failClosed: true`. Ojo también con los topes que solo cubren UNA RAMA:
`/api/support/notify` limitaba únicamente `kind:"reply"`, así que **omitiendo ese campo** se le
mandaba al equipo un correo por petición (y se quemaba la cuota de Resend). Y `/api/seo/indexnow`
era un POST público que empujaba las URLs del sitio a los buscadores sin que nadie lo pidiera.

**⚠️ Soporte: dos fallas gemelas de la plantilla (2026-08-05, `piel-y-trigo-cl`, commits
`50fe4cc` y `01cd0c6`).** (1) El aviso por correo al equipo se dispara **solo al crear el
ticket**: si el cliente RESPONDE en una conversación abierta, solo suena la campana del panel, y
si nadie está mirando el panel la consulta muere igual. Hay que llamar la ruta de aviso también
al responder, **agrupando** (1 correo cada ~10 min por ticket) para no llenar la bandeja con una
ráfaga. (2) La tabla `support_tickets` **no guarda nombre ni correo del cliente**: todo va
apretado dentro de `subject` (`"Invitado: Ana | Email: a@b.cl | Tel: ..."`), así que el correo de
alerta llega como **"Cliente (sin correo)"** y el equipo tiene que descifrar el asunto a ojo.
Agregar campos propios y, para los tickets ya existentes, extraer del asunto como respaldo.

**⚠️⚠️ Patrón CRÍTICO de usabilidad — el panel MIENTE en producción porque ningún archivo de
`convex/` usa `ConvexError` (2026-08-06, `piel-y-trigo-cl` commit `34e4c94`).** Convex **oculta
el mensaje de todo error que no sea `ConvexError`** y responde `"[Request ID: …] Server Error"`.
En esta plantilla los 42 `throw new Error(...)` de `convex/*.ts` son validaciones escritas para
el usuario ("El código/SKU ya está registrado", "Solo puedes valorar productos de un pedido
pagado", "Cuenta protegida"), y **ninguna llegaba**: el dueño veía "Server Error" y creía que el
panel estaba roto. Fue exactamente lo que hizo fracasar un alta de producto en una sesión
anterior sin dejar rastro. **Chequeo de 5 segundos en cualquier tienda de la familia:**
`grep -rn "throw new Error" convex/` — si hay resultados y no aparece `ConvexError` por ningún
lado, ese panel miente. **Fix:** pasar las validaciones a `ConvexError` (el texto viaja en
`err.data`, NO en `err.message`) + un helper `convexErrorMessage(err)` en los server actions que
lea `err.data` y **nunca** devuelva el "[Request ID: …] Server Error" crudo.

**⚠️ Truco de automatización que destraba el panel entero (2026-08-06, repetible):** un `alert()`
nativo **congela el renderer** y hace fallar screenshots y JS con timeouts de CDP. En vez de
cerrarlo a ciegas con `key: Return`, **parchear `window.alert` ANTES de enviar el formulario**
(`window.alert=(m)=>{window.__alerts.push(String(m))}`; igual `window.confirm=()=>true`) y leer
`window.__alerts` después: cero congelados y se lee el mensaje exacto. **Gotchas hermanos:** los
menús/pestañas de **Radix (`DropdownMenu`, `Tabs`) NO se abren con `.click()` sintético** —
necesitan un clic real del `computer` tool (coordenada vía `getBoundingClientRect()`), y un
segundo clic sobre el mismo trigger lo **cierra**. El contenido dentro de un `Tabs` está
**desmontado** hasta que se selecciona la pestaña: "el campo no existe" suele ser "está en otra
pestaña del modal".

**⚠️ Patrón de la plantilla — "Ver en Tienda" del panel siempre da 404 (2026-08-06, commit
`e26ecbb`).** El enlace se arma con el id de Convex, pero la ficha pública resuelve por **slug**
(con el SKU como respaldo). Estaba en las dos vistas del catálogo y en el listado de reseñas.
**Chequeo:** `grep -rn "producto/\${" src/app/admin/`.

**⚠️ Patrón de la plantilla — el alta de producto no tiene campo de stock (2026-08-06).** Guarda
un valor fijo (10 en Piel y Trigo) y corregirlo obliga a reabrir el producto y justificar un
ajuste de inventario de 10+ caracteres → **la tienda ofrece existencias que no hay**, y el
asiento "Inventario Inicial" del historial miente. Ojo: el comentario del código que dice que
los precios van **en centavos es falso**, van en pesos.

**⚠️ Patrón de la plantilla — borrar una categoría "funciona" y la categoría vuelve sola
(2026-08-06, commit `f5939a0`).** La lista pública se arma con lo configurado **más** las
categorías que los productos usan de verdad, así que borrar una en uso muestra el visto de éxito
y no cambia nada visible. Hay **dos pantallas** que editan categorías (Ajustes → Categorías y
Editar Web → Categorías): arreglar una y no la otra es lo que había pasado acá. Chequear también
que comparen **sin distinguir mayúsculas** ("Alimentos"/"alimentos" = mismo slug) y que avisen de
cambios sin guardar.

**Truco de QA muy útil — comprar de verdad sin mover dinero:** el panel trae "GENERAR BYPASS
M. PAGO" (cupón `type:"bypass"`, `roleRequirement:"owner"`, un solo uso) que deja el total en $0.
Con la sesión del dueño se crea un pedido REAL en producción y eso permite verificar de una sola
pasada: descuento de stock, `delivery_comments`, vinculación al usuario, consumo del cupón,
correo al cliente y correo al equipo. Al terminar, cancelar el pedido (restaura el stock) y
borrar el cupón.

**⚠️ Lección de método al verificar controles de acceso (2026-08-05):** el primer chequeo dio
"CENSURADO ✅" pero era **falso positivo**: el deployment de dev no tenía ningún cupón, así que
la query no ocultaba nada — simplemente no había nada que ocultar. **Un control de acceso
siempre "pasa" si el dato que debía esconder no existe: sembrar el dato primero y recién ahí
creerle.** Forma barata de probar sin tocar producción: `npx convex dev --once` empuja las
funciones al deployment de DEV y se prueban con `npx convex run <fn> '{...}'`. Para ver qué
variables de entorno tiene Convex prod sin exponer valores:
`npx convex env list --prod | cut -d= -f1`.

**Verificación de stock que vale la pena repetir en cualquier tienda con inventario** (en Piel
y Trigo confirmó de una sola pasada tres fixes que llevaban 2 días sin probarse): mover UN
pedido real por los estados desde el panel y medir el stock contra la base en cada paso con
`npx convex run products:getByIds --prod`. Lo correcto es
20 → confirmar pago → **19** → marcar enviado → **19** (idempotencia: no debe descontar dos
veces) → cancelar → **20** (restaura sin inflar el inventario). Los tres números importan: el
segundo detecta el doble descuento y el tercero detecta el inventario inflado.

**Método de QA que funcionó (repetible):** probar sobre PRODUCCIÓN real con la sesión de un
cliente, confirmar cada hallazgo leyendo el código antes de declararlo bug, y cruzar contra la
base real con `npx convex data <tabla> --prod`. Distinguir siempre **fallo del sitio** de
**fallo de la automatización**: los clics sintéticos del `computer` tool fallan seguido en
botones de React (un botón que "no abre nada" suele abrir bien si se dispara con
`javascript_tool` o con `ref`), y las imágenes con `naturalWidth === 0` normalmente son solo
lazy fuera del viewport, no rotas — verificar con un `fetch(HEAD)` antes de reportarlas.

**⚠️ Restricción operativa a planificar de antemano:** no puedo ingresar contraseñas en un
login **aunque el usuario me las pase por el chat** (regla dura). O sea: **si se cierra una
sesión, no puedo volver a abrirla**. Antes de empezar un QA multi-rol hay que acordar el orden
(probar primero el rol cuya sesión ya está abierta, dejar "invitado" para el final, y pedirle al
dueño que deje iniciada la sesión de owner/Google para el bloque de admin).

**Nota de proceso — auditorías grandes de "revisa todo el código" se hacen mejor con varios
sub-agentes Explore EN PARALELO, cada uno con un foco acotado** (ej. "rutas API + seguridad",
"flujo de checkout completo", "resto del panel admin no auditado aún", "residuos de plantilla en
todo el código"), lanzados todos en background en la misma tanda — mucho más rápido que uno solo
intentando cubrir todo el repo secuencialmente, y cada reporte llega por separado para ir
priorizando mientras los demás siguen corriendo.

