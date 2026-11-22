## ⚠️⚠️ AUDITORÍA DE PAGOS DE AKIM (2026-08-10/11) — checklist para TODAS las tiendas hijas
> **Qué es:** pagos (Webpay/MP) en la familia akim: bugs de dinero confirmados y cómo evitarlos.
> **Actualizado:** 2026-09-01


Sesión de ~5 h sobre `akim-pet-market-web`, **el proyecto ORIGEN del linaje** (Next.js +
Supabase + Webpay/Transbank). Todo lo de abajo se encontró y arregló ahí, en producción, con
pagos reales. Como Akim es el padre, **estos patrones hay que buscarlos en cada hijo** —
`3.pasapalos-cl` (clon casi literal, prioridad máxima), `imperio-morales`, `arias-wear-cl`
(Mercado Pago), `autotronicagama-cl`, y los de Convex (`beauty-gang-world-com`,
`criadero-cachorros`, `Games-god`, `piel-y-trigo-cl`, `Barberia-cl`, `Picker-Cal`,
`ua-antofa-cl`). Detalle completo en la memoria del proyecto
(`.../akim-pet-market-web/memory/webpay-pagos-fallidos-2026-08-10.md` y
`qa-pago-real-y-dashboard-2026-08-11.md`).

**Síntoma que lo destapó:** clientes reales necesitaban 2–4 intentos para pagar. 11 de 43 pedidos
colgados en `pendiente`. Una clienta hizo 4 intentos del mismo carrito en 40 min; otra falló y
pagó 2 min después con el mismo monto sin cambiar nada.

### El bug raíz (aplica a CUALQUIER pasarela, Supabase o Convex)
**Al pulsar "Anular compra y volver" en el portal de pago, el pedido NO se cerraba.** El callback
recibía la anulación y la registraba en el log, pero el pedido seguía `pendiente`. El cliente
volvía al sitio, **no veía ningún mensaje**, el carrito seguía lleno → reintentaba. **Prueba de
2 minutos en cualquier tienda:** hacer un checkout de invitado, llegar al portal, pulsar anular,
y mirar si el pedido quedó `cancelado`. Si sigue `pendiente`, está roto.

### ⚠️ La causa fue una COLUMNA QUE NO EXISTE — el patrón más transferible de todos
En esta plantilla `orders` **NO tiene columna `notes`**: `encodeResilientOrder` empaqueta las
notas dentro del JSONB `items.metadata`, y `decodeResilientOrder` las **reconstruye al leer**.
Resultado: el panel las muestra, uno jura que la columna existe, y todo código de servidor que
haga `order.notes`, `.select("...,notes")` o `.like("notes", ...)` sobre el registro CRUDO
**falla en silencio**. Un `.select()` con una columna inexistente devuelve `data: null`, y la
guarda `if (!order) return;` sale **sin registrar nada**. Tropecé con esto TRES veces en la misma
sesión.
**Regla general:** en esta familia, cualquier campo que aparezca al leer un pedido puede ser
**sintético**. Antes de usarlo en un `select`/`update`/`filter` server-side, confirmar que existe
de verdad. Y **toda guarda `if (!x) return` debe registrar el motivo**, nunca salir muda.
En Convex el equivalente es el mismo riesgo con distinta forma: campos que el frontend arma a
mano o que el `decode` reconstruye, y que no están en el `schema.ts`.

### Checklist de dinero para cada tienda hija
1. **El navegador puede marcar un pedido como PAGADO.** `/api/orders/create` aceptaba
   `status: "procesando"` tal cual venía del cliente, y ese es el estado que el dashboard suma
   como venta. Cualquiera podía inflar las ventas totales posteando pedidos falsos (el `total`
   sólo se validaba por rango). **Fix:** aceptar el estado pagado sólo si el total es 0 o si la
   sesión es staff. **Chequeo:** buscar el `ALLOWED_STATUS`/whitelist de la ruta que crea pedidos.
2. **El `amount` final lo manda el navegador.** Los precios por ítem se validaban contra la BD,
   pero no el total: se podía mandar `amount: 1` con ítems legítimos. **Fix que NO rompe compras
   buenas:** validar como **cota inferior** — `amount >= subtotal_real − descuento_máximo`, con
   los cupones resueltos desde la BD, no del cuerpo. Despacho y comisiones sólo SUMAN, así que
   ninguna compra legítima cae bajo ese piso. **Probarlo con `amount:1` Y con el monto legítimo.**
3. **Fallback automático al SANDBOX de la pasarela.** Ante cualquier respuesta no-ok de
   producción, el código reintentaba contra el ambiente de integración → el cliente aterrizaba en
   el portal de pruebas y su tarjeta real siempre sería rechazada. **En Akim nunca se disparó**
   (verificado: 0 pedidos en sandbox), pero el riesgo era real. **Nunca hacer fallback de
   ambiente en producción: fallar con error visible.**
4. **Un F5 en la pantalla de retorno cancelaba un pago aprobado.** La pasarela permite UN solo
   commit por token; el segundo falla y el código marcaba `cancelado`. **Fix:** nunca degradar un
   pedido ya pagado, y consultar el estado real antes de cancelar.
5. **Nada reconcilia los pendientes.** El pedido se crea ANTES de ir al portal; si el cliente
   cierra la pestaña, nadie vuelve a mirarlo. **Fix:** un endpoint/cron que consulte el estado
   real en la pasarela (el endpoint de *status* es de sólo lectura e idempotente, a diferencia
   del commit) y cierre según la respuesta oficial. Hacerlo **con `dryRun` por defecto**.
6. **Búsqueda de la orden por token limitada a N filas** (50 en Akim, escaneo en memoria). Con
   más pedidos que N en el rango, un pago aprobado no encuentra su pedido → cobrado sin
   registrar. Filtrar en la BD, no escanear.
7. **En la anulación, buscar por el NÚMERO DE ORDEN, no por el token.** El `TBK_TOKEN` de la
   anulación puede no ser el mismo que se guardó al crear.
8. **Hora de corte del despacho con el reloj del CLIENTE** (`new Date().getHours()`). Estaba
   **triplicada** (2 copias en `checkout/page.tsx` + 1 en `ShippingForm.tsx`, esta última es la
   que pinta el candado). Resolver en la zona de la tienda (`America/Santiago`).

### ⚠️ Cómo auditar las "ventas totales" sin equivocarse (me equivoqué DOS veces)
- **La ausencia de registro en la pasarela NO es prueba de impago.** Transbank sólo mantiene
  consultables las transacciones recientes (~1 semana). Al consultar pedidos viejos devuelve
  "token desconocido", y tratar eso como impago marcó **21 pedidos y $1.221.603 como venta falsa**
  — todos legítimos. **Señal de que es retención y no fraude: el corte es puramente por fecha.**
  Sólo cuenta como impago una respuesta explícita de "no autorizado".
- **Clasificar por el texto de las notas es poco fiable:** hay pagos reales con redacciones
  distintas ("Webpay Plus Aprobado" vs "Webpay Acreditado Real").
- **Resultado final en Akim: 0 pedidos impagos.** Los $1.714.303 eran facturación real. Antes de
  alarmar al dueño con una cifra, verificar por dos caminos independientes.

### Gotchas de herramientas (ahorran mucho tiempo)
- **Un cron inválido rompe el deploy ENTERO y en silencio.** Se agregó `*/30 * * * *` a
  `vercel.json` y Vercel dejó de crear deployments: el push llegaba a GitHub, no aparecía nada en
  `vercel ls`, ningún error en ninguna parte. El motivo sólo se ve corriendo **`vercel --prod` a
  mano**: *"Hobby accounts are limited to daily cron jobs"*. **En Hobby el cron debe ser máximo
  diario.** Si un push no genera deploy y no hay error visible → `vercel.json` + `vercel --prod`.
- **Los crons de Vercel necesitan `CRON_SECRET`**; sin esa variable la invocación programada
  recibe 401 y **el cron nunca corre** (en Akim el de cumpleaños llevaba meses así, y sólo
  funcionaba por un `?secret=` hardcodeado en el propio archivo, o sea abierto a cualquiera).
  Setearlo sin que el valor pase por el chat:
  `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" | vercel env add CRON_SECRET production`
- **PowerShell del usuario no puede correr `vercel`** (ExecutionPolicy bloquea `vercel.ps1`,
  `UnauthorizedAccess`). **No cambiar la política.** Usar Git Bash, o `vercel.cmd` en PowerShell.
- **`vercel logs --follow` corta a los 5 minutos**; el histórico `--since` no alcanza eventos de
  hace una hora en sitios con tráfico (5.000 registros cubrían 4 minutos); y **`--query` se ignora
  en silencio** (CLI 58.9.1). Para capturar un evento, tener el stream corriendo ANTES.
- **`vercel link` reescribe `.env.local` sin avisar** (sólo dice "✓ Updated"). Copiarlo antes.
- **Leer datos del panel sin raspar el DOM:** las páginas admin tienen los documentos completos en
  el estado de React. Se recorre el fiber desde el `<table>` buscando un `memoizedState` que sea
  un array de objetos con las claves esperadas (`status`+`total` para pedidos, `stock`+`price`
  para productos). Mucho más barato y fiable.
- **Menús Radix necesitan clic REAL del `computer` tool**, no `.click()` sintético. Y **las
  coordenadas del screenshot NO son las del DOM**: hay que escalar por `anchoScreenshot/innerWidth`
  (en esta sesión 1568/1707 = 0.9186). Calcularlo, no adivinar. Un segundo clic en el mismo
  trigger lo cierra.
- **Parchear `window.alert`/`confirm` ANTES de enviar un formulario** del panel: un `alert()`
  nativo congela el renderer y hace fallar screenshots con timeout de CDP.
- **La sesión de owner se cae sola** cada cierto rato (401 en `/api/admin/*`). Claude **no puede**
  reabrirla (OAuth de Google). Planificar el QA multi-rol asumiendo eso.
- **`vercel.com` está bloqueado** para las herramientas de navegador. Todo lo de Vercel se hace
  por CLI.

### Restricción que hay que planificar de antemano
**Claude no puede completar un pago real** (ingresar datos de tarjeta está prohibido). El tramo
tarjeta→banco→aprobación lo tiene que hacer el dueño. Lo que SÍ se puede verificar solo: que el
traspaso llegue al portal de **producción** (no sandbox), el monto, el logo del comercio, la
anulación, y después el estado del pedido, el stock y los correos. **Método que funcionó:** crear
un producto de prueba de $50 + bajar temporalmente el mínimo de compra, con el dueño pagando
mientras Claude mira los logs en vivo. **Restaurar el mínimo apenas termine** (mientras esté bajo,
un cliente real podría pasar un pedido de ese monto).

