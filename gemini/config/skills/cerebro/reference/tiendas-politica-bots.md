## ⚠️ POLÍTICA DE BOTS DEL DUEÑO — los agentes de IA SÍ pasan (2026-08-17, decisión explícita)
> **Qué es:** política del dueño sobre bots: los agentes de IA SÍ pasan.
> **Actualizado:** 2026-09-01


**No bloquear crawlers ni agentes de IA en ninguna tienda.** El dueño los quiere: forman parte de
su canal de venta. Caso real que lo motiva — **ChatGPT recomendó `akim-pet-market-web` por tener
buenos precios**, el agente navegó el sitio desde el navegador e intentó comprar. Hubo fallos esa
vez y se arreglaron; el dueño quiere que ese camino siga funcionando. Cuando alguien le pregunta a
ChatGPT/Gemini/Claude "¿dónde compro esto?" o "consígueme el mejor precio", la meta es que estas
tiendas aparezcan y sean navegables.

**Consecuencias prácticas:**
- El ajuste **«AI Bots: Allow»** del Firewall de Vercel **debe quedarse en Allow** en todos los
  proyectos. En la auditoría del 17-ago se anotó que los crawlers de IA eran ~20% de las
  peticiones de gamesgod360 y se sugirió evaluar bloquearlos: **descartado por decisión del
  dueño.** No volver a proponerlo.
- **Ojo con BotID y con Bot Protection**: activarlos a lo bruto puede bloquear justamente a estos
  agentes. Cualquier protección tiene que ser selectiva.
- El `robots.txt` de la plantilla (`src/app/robots.ts`) permite todo salvo `/admin/`, `/cuenta/`,
  `/api/` y `/auth/`. Está bien así — no restringir más.
- Vale la pena que las fichas de producto sigan siendo legibles sin JavaScript (datos
  estructurados JSON-LD, precio y stock en el HTML), porque es de donde leen los agentes.

**PENDIENTE (pedido explícito del dueño el 17-ago, sin empezar): revisar Cloudflare y el Firewall
de Vercel para bloquear lo MALICIOSO sin tocar a los agentes.** Lo que se detectó en la
auditoría del 17-ago y hay que frenar:
- **Escaneo automatizado buscando WordPress** en sitios que no lo son: `/wp-admin/install.php`,
  6 peticiones en 12 h tanto en `piel-y-trigo-cl` como en `gamesgod360`. El mismo escáner
  golpeando ambos dominios con el mismo volumen. Explica parte de los `/_not-found` (24 en
  piel-y-trigo) y `/404` (12 en gamesgod).
- **Sondeo de endpoints de Shopify**: `/services/login_with_shop/buyer/start` en `piel-y-trigo-cl`.
- **Sondeos al webhook de pago**: los 4 "Firma de webhook inválida (mismatch)" de
  `imperio-morales` entre el 17-jun y el 15-ago eran esto (confirmado: un POST anónimo cualquiera
  genera esa línea).
- **Intento real de manipulación de monto** en `akim-pet-market-web` el 11-ago 03:08 (pagar $1 un
  carrito de $43.990, luego $21.995). El servidor lo rechazó las 3 veces, pero **el evento no
  genera ninguna alerta**: queda enterrado entre errores de runtime. Merece alerta propia.
- **Estado actual del Firewall en los 3 proyectos revisados** (akim, piel-y-trigo, gamesgod360),
  ventana de 1 hora que es el máximo en Hobby: Firewall activo, «All systems normal», **Bot
  Protection Inactive**, 0 IPs bloqueadas, 0 eventos, **BotID no habilitado en ninguno**.
  En akim hay además 2 reglas (*Allow Meta Crawlers*, *Allow Facebook Scraper*) con acción
  **Bypass** de una protección que está apagada — si algún día se activa Bot Protection, esos
  bypasses van a seguir ahí.

**Enfoque sugerido para cuando se aborde:** reglas por PATRÓN DE RUTA (bloquear `/wp-*`,
`/services/login_with_shop/*` y demás rutas que no existen en estas tiendas) y límites por IP en
los endpoints sensibles, en vez de una protección genérica de bots por reputación —
las reglas por ruta no pueden confundir a un agente de IA legítimo, que navega el catálogo real.

## Correcciones del dueño a la auditoría del 17-ago (mismo día) — leer antes de priorizar

- **`Games-god` NO cobra en línea.** Corrige lo que dice más arriba en este archivo ("vende
  productos reales con dinero real", "la más urgente por revisar" por MercadoPago). **El cierre es
  por WhatsApp**: el sitio arma un mensaje con los juegos elegidos y listo. No hay pasarela, así
  que la auditoría de checkout/pagos que estaba marcada como urgentísima **no aplica** tal cual.
  Lo que sí hay que revisar es el **flujo de WhatsApp** (que el mensaje se arme completo y
  correcto, precios y títulos incluidos, y que no se pierda el carrito antes de llegar ahí).
- **`akim-pet-market-web` SÍ cobra de verdad** (Webpay/Transbank): hay pagos reales cobrados,
  aunque **a veces fallan** — ver la memoria de ese proyecto, sesión del 10/11-ago. O sea que
  `WEBPAY_ENVIRONMENT` apunta a producción; la duda que dejó la auditoría del 17-ago queda
  resuelta. Lo que sigue vigente ahí: **no tiene captcha en el checkout** (confirmado por el
  dueño).
- **Web Analytics de Vercel: NO habilitarlo alegremente.** En plan Hobby sólo se puede activar en
  **un** proyecto, y en un sitio con tráfico **se come la cuota gratis**. Está desactivado a
  propósito, es una decisión tomada, no un olvido. No volver a recomendarlo sin más — si hace
  falta medir, buscar otra vía (Observability, o los propios logs).
- **Restricción para el trabajo de Firewall/Cloudflare:** no debe dañar la experiencia de nadie
  legítimo — explícitamente los **invitados (sin registrar)**, los **clientes** y el **propio
  staff comprando**. Sumado a la política ya guardada de dejar pasar a los agentes de IA, esto
  descarta protecciones genéricas por reputación y empuja hacia **reglas por patrón de ruta** y
  límites por IP sólo en endpoints sensibles.
- **Turnstile de `imperio-morales`: el widget YA EXISTE.** El proyecto tiene
  `NEXT_PUBLIC_TURNSTILE_SITE_KEY`, y el panel de Turnstile de la cuenta ya listaba 6 widgets
  (Akim, Imperio Morales, Arias-wear, Pasapalos, BeautyGangWorld, rameseba-contacto). **No crear
  uno nuevo** — lo que falta es cargar la secret key de ese widget en Vercel. Y la secret key
  **no la transcribe Claude**: la copia el dueño.

