# Lanzar un sitio de servicio local: dominio → Search Console → Business Profile → Ads

Destilado el **2026-08-26** del lanzamiento de `cerrajeria-ok-cl` (hecho de punta a punta ese día)
más las memorias reales de `servi-clima-santiago-cl` (Ads con dinero real, jun–ago 2026) y los
docs del motor de sitios estáticos (`floormasters-cl` → `cerrajeria-ok-cl`).

Aplica a los sitios de **servicio local sin tienda**: cerrajería, aire acondicionado, fumigación,
terminaciones, fletes. No a las tiendas Convex/Next (para eso está `TIENDAS-CONVEX-NEXT.md`).

---

## 1. El orden que importa

1. **Dominio + Cloudflare + Pages** (1 h con las recetas de abajo).
2. **Search Console** — 10 min, gratis, y es lo único que hace que Google mire el sitio.
3. **Google Business Profile** — arrancarlo YA aunque Ads venga después: la verificación tarda
   días y **Ads la necesita** para la extensión de ubicación.
4. **Google Ads** — al final, y **no** requiere que el sitio esté indexado. Se puede lanzar
   campaña con el sitio recién publicado; la indexación solo afecta al tráfico orgánico.

**Error de expectativa que hay que aclararle al usuario:** *enviar el sitemap NO es indexar*.
En cerrajeriaok, minutos después del envío las páginas pasaron de "Google no reconoce esta URL" a
"Descubierta" y luego "Rastreada: actualmente sin indexar". Aparecer toma de días a semanas.

---

## 2. Dominio: la receta que funcionó (NIC Chile + Cloudflare + Pages)

- **El asistente "Connect a domain" del dash de Cloudflare se cuelga** (spinner infinito, la zona
  nunca se crea). Se resuelve creando la zona **por API desde la propia página del dash**:
  `fetch('/api/v4/zones', {method:'POST', credentials:'include', ...})` — usa la cookie de sesión,
  no hace falta token. Lo mismo sirve para DNS, settings y reglas.
- Una zona creada por API queda `initializing` **y sin "core subscription"**: hay que
  `POST /zones/{id}/subscription {rate_plan:{id:'free'}}` y además terminar el onboarding en la UI
  (Select plan → Free → "Continue to activation"). Recién ahí pasa a `active`.
- **`wrangler` NO sirve para escribir DNS**: `wrangler whoami` muestra `zone (read)` y nada más.
- En **clientes.nic.cl** la captura de pantalla se cuelga (CDP `Page.captureScreenshot` timeout)
  aunque el JS siga respondiendo. Se trabaja leyendo el DOM: los servidores son `hosts[N].nombre`
  y el botón es `input[type=button][value="Actualizar datos de dominio"]` (un `.click()` sintético
  SÍ funciona ahí).
- El certificado tarda **~4 minutos** en pasar de `pending_validation` a `active`. Mientras tanto
  el handshake TLS falla con `SEC_E_ILLEGAL_MESSAGE`: **es normal, no es un error de configuración.**
- **Canónico www** + Redirect Rule del apex (ruleset `http_request_dynamic_redirect`, 301 con
  `preserve_query_string`). La regla actúa en el borde, así que el apex funciona aunque figure
  `pending` en los dominios de Pages.
- **Higiene de correo en un dominio que no manda correo** (el cliente usa Gmail): TXT `@` con
  `v=spf1 -all`, `_dmarc` con `p=reject`, y `*._domainkey` con `v=DKIM1; p=` (DKIM nulo).
  Bloquea la suplantación. **Si algún día quiere correo propio, hay que cambiar los tres.**

## 3. El bug de SEO del motor de sitios estáticos: soft 404

**Cualquier URL inexistente devolvía la HOME con estado 200**, porque el motor no generaba
`404.html` y Cloudflare Pages cae a la home. Google indexa direcciones basura y Ads valida
destinos que no existen. Arreglo: escribir **`site/404.html` en la RAÍZ** (no `/404/index.html`,
si no Pages no lo reconoce), `noindex`, fuera del sitemap. Comprobación de 5 segundos:

```bash
curl -sS -o /dev/null -w "%{http_code}\n" https://<dominio>/no-existe/
```

**Revisar esto en cada sitio nuevo que salga del motor de `floormasters-cl`.**

## 4. Search Console: dos sesiones, dos navegadores

Caso típico: la sesión de **Cloudflare** es del usuario (`<correo-personal>`) y la de **Google**
es del cliente. La extensión de Claude in Chrome **solo mantiene un navegador activo a la vez**, y
al cambiar de uno a otro el primero desaparece de `list_connected_browsers` y no siempre vuelve.

**Lo que funcionó:** darle al usuario un **prompt listo para pegar en la extensión de su otro
navegador**, con el registro exacto a crear y la advertencia de no tocar los registros existentes.
Vale la pena repetir ese patrón siempre que hagan falta dos sesiones en navegadores distintos.

Otras notas:
- Propiedad **de Dominio** (no de Prefijo de URL): cubre apex, www, http y https en una sola.
- Google detecta que el DNS es de Cloudflare y ofrece verificar por **OAuth**, que exige iniciar
  sesión de Cloudflare en ESE navegador. Para el TXT manual hay que abrir el desplegable
  "Instrucciones para" y elegir **"Cualquier proveedor de DNS"**.
- **No borrar nunca el TXT de verificación**: si se cae, se pierde la propiedad.
- **Gotcha de automatización:** tras "Solicitar indexación" queda un modal verde y encima
  reaparece un popup azul "¡Novedad! Instagram/TikTok…". Cualquiera de los dos se traga el clic en
  la barra de inspección y el resultado es que **se re-solicita la MISMA URL** en vez de la
  siguiente. Hay que cerrar el modal ("Cerrar") **y** el popup (la X), confirmar con un pantallazo
  que la pantalla quedó limpia, y recién entonces escribir la URL nueva. Cuota ~10 URLs/día.

## 5. Lo que hay que pedirle al cliente ANTES de gastar el primer peso

Sacado de que en **ServiClima la campaña quedó detenida semanas** por algo que solo el dueño podía
resolver. El orden de esta lista no es cosmético: el punto 1 es el que mata campañas.

1. **Verificación del anunciante.** Google la exige antes de publicar. Banner *"Cuenta detenida —
   complete el proceso de verificación del anunciante"*, campaña en estado **"No apta"**, y el
   crédito intacto porque Google dejó de publicar. La tarea "Envía tus documentos" **la tiene que
   hacer el dueño** (Claude no sube documentos de identidad). Pedir de entrada: razón social y RUT,
   tipo de sociedad, representante, inicio de actividades del SII, patente municipal.
2. **Tipo de ficha de Business Profile:** ¿local con atención de público, o solo oficina y servicio
   a domicilio? Si es a domicilio, la dirección **no se publica** y se configura por zona. Decide
   la ficha y **no se cambia cómodo después**.
3. **Fotos reales.** Los sitios de este motor salen con fotos de banco. Las propias convierten
   mejor y además alimentan la ficha.
4. **Precios base.** No hay que publicarlos, pero sí tenerlos. En el relevamiento de cerrajería,
   de 5 competidores solo uno publica precios y es el mejor posicionado.
5. **Capacidad real de atención** (cuántos servicios al día aguanta). En rubros de urgencia, traer
   más llamadas de las que atiende quema la ficha con malas reseñas. **Esto no estaba en ningún
   doc; se agregó al cuestionario el 26-ago.**
6. **Presupuesto y medio de pago.** Google Ads en estas cuentas va con **prepago manual**: si se
   acaba el saldo los anuncios se apagan solos. En ServiClima el saldo llegó a CLP 4.751 con
   5.000/día de presupuesto — menos de un día.
7. **Claims que la web afirma** y hay que poder respaldar ("empresa autorizada", "sin recargo
   nocturno", "garantía por escrito", tiempos de llegada).

## 5.bis. El cliente SIN empresa registrada — sí se puede, y aquí está el detalle

Caso `cerrajeria-ok-cl` (27-ago-2026): *"esto es un oficio, aún no se puede inscribir, nadie
respalda las cerrajerías de Chile"*. **Todo se puede hacer igual**, verificado contra la
documentación de Google, no de memoria:

- **Google Ads.** La página de requisitos **de Chile** dice que las *personas físicas* solo deben
  enviar **un documento de identidad chileno con foto** (cédula, pasaporte o licencia). Escritura,
  certificado tributario y licencia comercial **solo se le piden a las organizaciones**.
  → El perfil de pagos hay que crearlo como **"Personal" DESDE EL PRINCIPIO**: Google avisa que si
  queda mal elegido hay que contactarlos **antes** de iniciar la verificación.
  → La etiqueta pública del anunciante mostrará **el nombre personal**, no la marca. Avisarlo.
- **Cerrajería en Chile NO está restringida.** La política "Otros negocios restringidos: servicios
  locales" exige *verificación avanzada* para cerrajeros en **EE.UU. y Canadá**, y **prohíbe** los
  anuncios en **España, Países Bajos, Alemania, Suecia y Bélgica**. Para el resto: "pueden
  publicarse". **Comprobar esta página antes de vender una campaña de un rubro sensible.**
- **Business Profile no exige empresa constituida.** Verificación por video o llamada.
- ⚠️ **El problema real no es Google: es lo que la web promete.** En cerrajeriaok el sitio decía
  "boleta o factura" y "Empresa autorizada" en **19 puntos**, y la mitad NO estaba en el contenido
  sino incrustada en las plantillas (`scripts/lib/pages.js`, `build-site.mjs`, incluido el
  `llms.txt`). Sin inicio de actividades eso es falso, choca con la política de tergiversación de
  Ads, y sobre todo espanta al cliente que sí paga: administraciones de edificio y flotas **exigen
  factura**.
  **Y lo peor estaba en el BLOG:** el artículo "cómo reconocer un cerrajero formal" le decía al
  lector, tres veces, que desconfiara de quien no emite boleta. Publicado tal cual, **el sitio
  descalificaba a su propio dueño**. Se reencuadró el criterio a "garantía por escrito".
  **Chequeo:** `grep -rni "boleta\|factura\|autorizada" src/ scripts/` — **con `-i`**, que un grep
  sensible a mayúsculas dejó pasar dos `"Factura para empresas"` — y **comprobar contra el HTML
  generado**, no solo contra el fuente.

**Dos advertencias que conviene darle por escrito al cliente:**

- **Que NO acepte las recomendaciones de la app móvil de Google Ads.** En ServiClima el cliente
  aceptó recomendaciones a ciegas: se llevó 3 keywords de frase que convertían, metió ~11 de
  concordancia **amplia**, y subió el presupuesto de 5.000 a **9.900/día**. Los términos de
  búsqueda distintos pasaron de **22 a 2.102** y entró tráfico de gente que quería *comprar
  equipos*, no contratar servicio.
- **WhatsApp Business.** El WhatsApp del cliente de ServiClima estuvo bloqueado (jul 2026) con el
  volumen que trae la publicidad. Se recuperó, pero el riesgo es real.

## 6. Ads: configuración que ya se probó y funciona

- **Socios de búsqueda OFF.** Medido dos veces en ServiClima: 252 impresiones, 1 clic,
  **0 conversiones**. Apagarlo no pierde nada y sube el CTR reportado de 4,2% a 6%.
- **Segmentación a nivel Región Metropolitana**, modo **"Presencia"** (no "Presencia o interés"),
  y excluir las regiones vecinas como red de seguridad. Cargar comuna por comuna da el mismo
  resultado con más trabajo.
- **Puja:** Maximizar clics con tope de CPC mientras no haya historial; pasar a Maximizar
  conversiones a las ~15-30 conversiones/30 días.
- **La conversión que importa es el clic a WhatsApp y el clic a llamar**, no el formulario: en
  estos rubros la venta se cierra hablando. En ServiClima WhatsApp fue el **93%** de los contactos.
- **Negativas desde el día uno.** Son las que más ahorran, y el patrón se repite por rubro: en
  cerrajería, gente que quiere *aprender a abrir* (`curso`, `tutorial`, `ganzúa`, `cómo abrir`);
  en aire acondicionado, gente que quiere *comprar equipo* (`sodimac`, `btu`, `precio`); en todos,
  buscadores de empleo (`empleo`, `trabajo`, `sueldo`, `curriculum`).
- **CPA de referencia real:** ServiClima quedó en **CLP ~2.600 por contacto de WhatsApp** con CPC
  promedio ~CLP 430 y CTR ~6% en Búsqueda pura. Sirve de vara para el próximo rubro.

---

## 7. Crear las cuentas: la secuencia real, con los gotchas medidos (27-ago-2026)

Todo esto se hizo de punta a punta en `cerrajeria-ok-cl`. Son las trampas que cuestan tiempo.

### Antes de tocar nada: dos decisiones de medición
- **Google Tag Manager: NO**, para un sitio estático que ya trae los eventos escritos a mano
  (`data-cta` en cada botón). GTM es un contenedor más que mantener para hacer lo mismo. Se agrega
  el día que entre un píxel de terceros.
- **⚠️ Revisar el Consent Mode ANTES de activar la medición.** El motor de estos sitios trae
  `gtag('consent','default', {...:'denied'})` **y ningún banner que lo levante**. Así GA4 mide sin
  cookies y, sobre todo, **las conversiones de Ads no se atribuyen**: se pagan clics sin saber
  cuáles traen llamadas. Chile no exige banner (Ley 19.628 ≠ RGPD) → pasarlo a `granted` y
  **actualizar el texto de la página de privacidad para que diga la verdad**.
- **Dos etiquetas de conversión, no una.** El motor mandaba la misma etiqueta para el clic a
  WhatsApp y para el clic a llamar. Con una sola nunca se sabe cuál canal cierra. Son dos acciones
  de conversión y una línea de código.

### Google Business Profile
- Responder **"No"** a *"¿ubicación que los clientes puedan visitar?"* convierte la ficha en
  **negocio de área de servicio** y la dirección deja de publicarse. Es lo correcto para un oficio
  a domicilio, y **no se cambia cómodo después**.
- Las áreas se buscan escribiendo **"Comuna, Chile"**: con solo "Santiago" salen primero México y
  España. El clic en la opción del desplegable **falla por coordenada**; usar `find` + clic por
  `ref`. ~10 áreas bastan para arrancar; el resto se agrega luego desde el panel.
- Horario 24 h: al activar el día, el selector de "Abre a la(s)" trae **"24 horas"** como primera
  opción. Cada día suma ~51 px a la coordenada del siguiente.
- **Chat por SMS: dejarlo apagado.** Si nadie lo contesta, Google castiga la ficha y el dueño
  pierde el lead igual.
- **Fotos: omitirlas si no hay reales.** Subir banco perjudica justo cuando Google mira la ficha
  para verificarla.
- ⛔ **No lanzar la verificación uno mismo.** Dispara una carta física o un video que solo puede
  grabar el dueño. Usar **"Verificar más tarde"**: la ficha queda creada y guardada, marcada
  "no es públicamente visible", y el dueño elige el método.

### Google Analytics 4
- ⚠️ **El asistente viene en hora de Los Ángeles y dólares**, y al elegir Chile **salta a Isla de
  Pascua (GMT-06)**. Hay que bajar y elegir **"(GMT-04:00) hora de Chile"** y **peso chileno**.
  Con campañas nocturnas, una zona horaria mal puesta arruina todos los informes por hora.
- El campo "Sector" es cosmético y su buscador no encuentra "hogar" ni "negocios": elegir de la
  lista y seguir.

### Google Ads — la cuenta nace trabada en "Campaña inteligente"
- Una cuenta nueva **se queda en el asistente express** y `/aw/overview` **redirige de vuelta**.
  En esa pantalla **no existe** el enlace "Cambiar al modo experto" (comprobado en el árbol de
  accesibilidad, no solo a ojo).
- **La salida que funciona** (ya usada en ServiClima): **completar el asistente con una campaña de
  prueba, con el presupuesto en el mínimo (CLP 1/día), y pausarla o eliminarla apenas se libere el
  panel.** No se publica ni se cobra mientras no haya tarjeta.
- Conviene responder **"No, no utilizar esta información"** al vincular el Perfil de Negocio, para
  no dejar la ficha amarrada a una campaña que se va a botar.
- ⚠️ **El paso de imágenes bloquea el avance sin decir por qué**: el error ("Corrige los errores
  para continuar") sale arriba, fuera de pantalla. Exige **1 logo** + **1 imagen cuadrada y 1
  horizontal**. Cada imagen sugerida necesita **tres acciones**: clic → aparece el botón
  "Seleccionar" → clic en "Seleccionar" → diálogo "Recorte la imagen" → "Listo". Un clic solo no
  selecciona nada y el botón Siguiente queda mudo.
- **La pantalla de pago fija la ZONA HORARIA DE TODA LA CUENTA y avisa que no se puede cambiar
  después.** Verificar que diga la del país antes de seguir.
- Suele haber una **promoción "invierte USD 350 y obtén USD 350"** para cuentas nuevas, con fecha
  límite. Se aplica sola al completar la facturación: vale avisarle al cliente, es medio
  presupuesto regalado.
- ⛔ **Parada obligatoria en "Cree un perfil de pagos nuevo".** Ahí se elige **Personal vs
  Organización** (ver 5.bis) y se ingresa la tarjeta. **Claude no ingresa datos de tarjeta ni sube
  documentos de identidad**: ese tramo lo hace el dueño. Conviene mandarle una guía paso a paso con
  el enlace, qué botón va a ver, que el cobro chico de prueba es normal, y que **nunca mande el
  número de la tarjeta por WhatsApp, tampoco a quien le está armando la campaña**.

### Presupuesto por día de la semana: no existe
Si el cliente pide "5.000 entre semana y 10.000 el fin de semana", Ads **no acepta presupuesto por
día**. Tres caminos, y conviene que el cliente elija por escrito:
- **A (recomendada):** un presupuesto diario con el promedio (≈7.100) + **ajuste de puja al alza**
  el fin de semana. Google gasta hasta el doble en un día de alta demanda y compensa dentro del
  mes, así que el efecto es el pedido. **Avisar que en pantalla verá 7.100, no 5.000.**
- **B:** subirlo y bajarlo a mano cada semana. Hace lo pedido, pero cada cambio reinicia parte del
  aprendizaje.
- **C:** dos campañas con programación distinta. Es literal, pero con presupuestos chicos parte el
  aprendizaje en dos y sube el costo por contacto.

## 8. Conversiones y campaña real: lo medido el 28-ago-2026 (CerrajeriaOK)

### 8.1 "Pago rechazado" recien cargada la tarjeta suele ser el PRIMER intento, no un problema del banco
Antes de mandar al cliente a llamar a su banco, **reintentar desde el panel**: Facturacion ->
Configuracion -> boton rojo **"Solucionar el problema"** bajo la tarjeta -> dialogo *"Actualizar la
forma de pago"* -> dejar marcado **"Mantener <tarjeta> como forma de pago principal"** -> Continuar.
Sale *"Forma de pago actualizada"* y al recargar el banner rojo desaparece. **Ese dialogo NO pide
reingresar el numero de tarjeta**, asi que lo puede hacer quien administra la cuenta.
Como distinguirlo de una deuda real: si el saldo es 0 y dice "Todavia no realizo ningun pago", lo
que reboto fue el **cargo de verificacion**, no un cobro.
Queda un aviso naranja aparte, "No hay ninguna forma de pago alternativa": es una recomendacion, no
bloquea. Agregarla exige el numero de otra tarjeta -> lo carga el dueno.

### 8.2 Las dos acciones de conversion (WhatsApp y llamada) van MANUALES, no automaticas
Ruta: Objetivos -> Conversiones -> **Crear accion de conversion** -> "Conversiones en un sitio web"
-> URL del sitio -> marcar **Etiqueta de Google** -> Listo -> Guardar y continuar -> categoria
**Contacto** ("Ver todas" para encontrarla) -> **"Manualmente con codigo"** -> nombre -> Listo ->
Guardar y continuar -> **Finalizar**.
- El `AW-XXXXXXXXXXX/<etiqueta>` se lee en **"Ver fragmento de evento"**.
- ⚠️ **Leer la etiqueta de un screenshot es un error esperando pasar** (`5ls3` vs `51s3`, O vs 0).
  Extraerla del DOM, recorriendo shadow roots, con una regex `AW-\d+\/[A-Za-z0-9_\-]{10,}`.
- **Conversiones avanzadas: dejarlas DESACTIVADAS** salvo que el dueno lo pida. Exigen aceptar las
  Condiciones del Tratamiento de Datos de Google en su nombre.
- El asistente **se congela de forma reproducible al crear la SEGUNDA conversion en la misma
  pasada**. Solucion: crear UNA, terminar el asistente completo, y volver a entrar para la otra.
- Si la cuenta venia de una campana inteligente, la categoria Contacto **ya trae 3 acciones
  automaticas** (`Clicks to call`, `Smart campaign ad clicks to call`, `Smart campaign map clicks to
  call`). No estorban, pero al montar la campana real conviene saber que estan.

### 8.3 Verificar la medicion en vivo, no de oido
Con la etiqueta ya desplegada, en el sitio real: envolver `gtag` con un espia
(`const g=window.gtag; window.gtag=function(){__ev.push([...arguments]); return g.apply(this,arguments)}`),
prevenir la navegacion con un listener en captura, y hacer clic en un boton de WhatsApp y en uno de
telefono. Tiene que salir `event contacto {method,ubicacion}` **y** `event conversion {send_to:
AW-.../<etiqueta correcta>}`, distinta para cada canal. Confirmar ademas que salieron peticiones
reales: `performance.getEntriesByType('resource')` filtrando `googleadservices|doubleclick`.
⚠️ **El espia hay que instalarlo y probarlo en llamadas separadas**: si se instala y se hace clic en
la misma tanda, a veces no captura y parece que el sitio no dispara nada.

### 8.4 ⛔ El muro final: "Confirme su identidad" (y la passkey del cliente)
Al publicar la campana, Google abre **"Confirme su identidad"**. La primera vez ofrece **Omitir**
(con el aviso *"No podra omitir este paso despues del <fecha>"*), pero **al publicar ya no lo
ofrece**: solo Cancelar / Confirmar.
- Confirmar exige autenticarse con la cuenta -> **quien arma la campana no puede hacerlo si no es
  el dueno**, y menos si implica escribir una contrasena.
- ⚠️⚠️ **Si el cliente abrio su Gmail en el TELEFONO, lo mas probable es que Google le haya dejado
  una passkey ligada a ese telefono.** En ese caso **tener el Gmail abierto en el computador no
  alcanza**: la confirmacion pide el dispositivo fisico. La campana queda parada hasta que el dueno
  este disponible, aunque haya dado acceso a la cuenta.
- **Leccion para la proxima cuenta nueva: pedirle al dueno que complete "Confirme su identidad"
  APENAS se crea la cuenta**, mucho antes de armar nada. Es el unico paso que no se puede delegar y
  siempre aparece al final, cuando ya se invirtieron horas.

### 8.5 El borrador de campana NO guarda lo que uno cree
Ads crea el borrador (`draftId`) recien al pasar del paso de Ofertas al de Configuracion. Pero
**palabras clave, anuncios y presupuesto viven en el estado de la URL (`cmpnInfo`), no en el
servidor**: al reabrir el borrador desde "Borradores en curso" aparecen **vacios**, y el resumen
pide "Crear un anuncio / Agregar palabras clave / Agregue un presupuesto".
**Regla: no dar por guardado nada hasta publicar.** Y al retomar, verificar el paso real, no el
resumen — el resumen tambien miente al reves: mostraba **"Anuncios: Ninguno"** con el anuncio ya
cargado y visible en su paso.

### 8.6 Ajustes de la campana de busqueda que hay que tocar a mano (vienen mal por defecto)
- **Red de socios de busqueda y Red de Display: ambas vienen MARCADAS.** Desmarcarlas.
- Ubicacion: viene **"Todos los paises y territorios"**. Poner la region y, en **Opciones de
  ubicacion**, cambiar a **"Presencia"** (por defecto es "Presencia o interes", que trae turistas).
- Idioma: agrega espanol solo, pero **sugiere agregar ingles**. No aceptar.
- **IA Max / Search Max, personalizacion de texto y expansion de URL final: apagados.**
- Horario que cruza medianoche: **dos filas** (20:00-00:00 y 00:00-04:30). Verificar la linea
  "Segun la zona horaria de la cuenta" — debe decir la del pais.
- Las palabras clave que sugiere la IA mezclan intencion de **compra** con intencion de
  **servicio** ("chapas de puertas", "cambio de cerradura precio"). Reemplazarlas por frases de
  alta intencion en concordancia de frase.
- El presupuesto propuesto suele ser ~60% mas alto que el acordado. Poner el acordado; el aviso de
  "tu presupuesto es inferior al de otros anunciantes" es normal.

### 8.7 Automatizar el panel de Ads: dos cosas que ahorran horas
- **`form_input` con `ref`, nunca teclear.** Los campos de Ads ignoran el tecleo sintetico: el texto
  se ve en pantalla, el componente no lo registra y el boton no reacciona. Paso con la URL del sitio
  y con las horas (quedo "00:0020:00" -> "Hora no valida").
- **Los `label` no son el campo.** `find` devuelve el `<label>`; el `textbox` real suele estar 2
  refs mas abajo (`ref_1732` -> `ref_1734`). Leer el subarbol con `read_page` antes de escribir.
- El panel **congela el renderer con frecuencia** (screenshots con timeout de CDP de 1 a 3 minutos).
  No es la maquina: se recupera solo, o se abre pestana nueva y se retoma.

## 9. Rubro restringido, reseñas y fraude de clics: lo medido el 28-ago-2026 (CerrajeriaOK)

### 9.1 ⛔ Cerrajería es un rubro RESTRINGIDO: la campaña se bloquea sola al publicar

> ⚠️ **CORRECCIÓN del 2026-08-29 — leer antes que el resto de este apartado.** Lo de abajo
> describe bien el **filtro que marca las palabras clave**, pero la conclusión que se sacó de ahí
> ("el rubro está bloqueado y por eso no publica") **quedó desmentida**: se activó una campaña
> **Smart** de la misma cuenta, mismo sitio y mismo rubro y Google la dejó en **"Apto"**; el
> Administrador de políticas declara **cero infracciones**; y la política, en *"Otros países"*,
> dice literalmente que estos anuncios **sí se pueden publicar aunque la empresa no haya
> completado ninguna verificación**. El bloqueo real es **específico del asistente de campaña de
> Búsqueda** y sigue sin explicación de Google (ver el apartado del final de este documento).
> **La casilla "Solicitar una excepción" nunca llegó a aparecer en esta cuenta.**

Al pulsar Publicar, Google marcó **8 de 12 palabras clave** — **todas las que contenían la palabra
"cerrajero"** — bajo *Otros negocios restringidos: **servicios locales***
(`support.google.com/adspolicy/answer/13527633`). El asistente pasa a *"casi lista para
publicarse"* y **desaparece el botón Publicar**.
- **Verificación avanzada obligatoria: sólo EE.UU. y Canadá.**
- **Prohibido del todo: España (desde el 4-nov-2024), Países Bajos, Alemania, Bélgica y Suecia.**
  España cayó por fraude masivo del rubro. **Chile NO está en ninguna lista.**
- **No es un problema de calidad del sitio ni de la cuenta**: es un filtro automático a
  anunciantes nuevos del vertical.
- **Solución: marcar "Solicitar una excepción"** en *Detalles de la política → Corregir o
  solicitar una excepción*.

🚨 **La excepción SÓLO se puede pedir ANTES de publicar.** Si se publica y los términos quedan
rechazados, ya no hay exención: hay que borrarlos. **Nunca intentar publicar "a ver qué pasa" en
un rubro restringido sin mirar antes si aparece esa casilla.**
**Rubros con el mismo riesgo:** cerrajería, puertas de garaje, y en general urgencias a domicilio.
**Comprobación de 2 minutos ANTES de venderle la campaña al cliente:** buscar las keywords del
rubro en `google.cl` y ver si hay anunciantes activos. Si los hay, el país está abierto y la
excepción debería aprobarse.

### 9.2 Cómo consultar el estado de una excepción (y el falso positivo)
**No hay vista de cuenta donde mirarlo** si cuelga de un borrador sin publicar: el Administrador
de políticas (`/aw/policymanager`) da **404**, y "Ver todos los problemas de la campaña" del
Resumen habla de otras campañas.
🚨 **Falso positivo:** navegar directo a `.../draft?...&currentStep=campaign-summary` carga el
asistente **vacío** y muestra **"lista para publicarse" con 0 errores**. Es mentira. **La pista es
"Tipo de campaña: —".**
**Camino válido:** Campañas → expandir *Borradores en curso* → **Finalizar** → *Siguiente/Omitir*
hasta el resumen → esperar a que termine *"Comprobación de errores en curso…"*.
**Pendiente** = avisos genéricos *"Este elemento no cumple con las normas editoriales"* con icono
de llave inglesa, sin botón Publicar. **Rechazado** traería lenguaje explícito de apelación.

### 9.3 El borrador SÍ se guarda… menos un campo
Corrige la nota de la sección 8.5. **Una vez que se INTENTA publicar, Google guarda el contenido
en el servidor**: sobrevivieron palabras clave, URL final, 15 títulos, 4 descripciones,
presupuesto, horario y exclusiones al cerrar la pestaña.
⚠️ **La excepción es el VALOR del tope de CPC**: al reabrir, la casilla sigue marcada pero **el
número aparece vacío**. **Reponerlo SIEMPRE justo antes de publicar**, o la campaña sale sin techo
de puja.
⚠️ La **estimación lateral** (clics/semana, CPC prom.) se vuelve absurda al reabrir un borrador
(pasó de 199 clics / CPC 250 a 582 clics / CPC 85 sin tocar nada). Es ruido del estimador.
**No tomar decisiones con ese número.**

### 9.4 Detectar reseñas compradas: mirar la DISTRIBUCIÓN, no los perfiles
Los servicios que venden reseñas publican **~1 cada 2 días** desde **cuentas reales verificadas**.
Eso **derrota los dos detectores clásicos**: no hay pico temporal y los perfiles tienen historial.
**Lo que no pueden falsificar es la banda intermedia, porque sólo venden 5★.**
Medición real en Santiago:

| | 5★ | 4★ | 3★ | 2★ | 1★ | banda 4+3+2 |
|---|---|---|---|---|---|---|
| Sospechoso (355 reseñas, 4,8) | 337 | 2 | 0 | 1 | 15 | **0,85 %** |
| Competidor real de 50 años (61, 3,6) | 35 | 5 | 1 | 1 | 19 | **11,5 %** |

Con 355 reseñas, la tasa natural daría ~41 en esa banda. Había 3, y **cero de 3★**. Los 1★ sí
suelen ser orgánicos: nadie compra estrellas bajas.
**Truco barato para leerlo** (cargar las reseñas congela el renderer; esto no):
```js
[...document.querySelectorAll('[aria-label]')].map(e=>e.getAttribute('aria-label'))
  .filter(x=>/estrella/i.test(x) && /reseñas?/i.test(x))
// → ["5 estrellas, 337 reseñas","4 estrellas, 2 reseñas", ...]
```
**Qué hacer con el hallazgo:** NO denunciar en masa (difícil de sostener, puede volverse en
contra). Sirve para (a) no desmoralizarse comparándose con un 4,8/355, y (b) fijar una meta
realista. **Apuntar a 20-30 reseñas reales con 4,4-4,7 y banda intermedia visible**: es el rango
del rubro y es defendible. Un 4,9 sin banda intermedia es justo lo que delata.
📌 Desde **abril 2026 Google Maps marca públicamente** los perfiles con reseñas falsas detectadas
y pausa la publicación de nuevas. Argumento práctico extra contra comprarlas.

### 9.5 Pedir reseñas: mecanismo y las 3 reglas
Montarlo **apagado** hasta que la ficha esté verificada — pedir reseñas de una ficha que no está
en Maps no lleva a ninguna parte. En un sitio estático: una variable `reviewUrl` en la config, un
bloque que devuelve cadena vacía si está vacía, y una fila en el pie. Encenderlo es **una sola
edición**. El enlace sale del propio Perfil de Negocio → **"Solicita opiniones"**
(`https://g.page/r/.../review`).
**Reglas para el dueño:** (1) mandar el mensaje **el mismo día** del trabajo; (2) **nunca** ofrecer
descuento ni regalo a cambio (reseña incentivada = Google la borra y castiga la ficha);
(3) **mandarlo a todos, no filtrar a los contentos** — filtrar es lo que produce la distribución
sin banda intermedia que acabamos de usar para detectar al de al lado.

### 9.6 🚨 Bug de medición al agregar un botón que NO es de contacto
Si el tracking clasifica por prefijo con un `else` implícito (`empieza por "wa" ? whatsapp :
telefono`), **cualquier `data-cta` nuevo cuenta como conversión de TELÉFONO**. Un botón
"Califícanos en Google" habría inflado las llamadas de Ads con clics que no son llamadas.
**Regla: clasificar explícitamente** — `wa-*` → WhatsApp + conversión, `tel-*` → teléfono +
conversión, **cualquier otra cosa → sólo evento de GA4, nunca conversión**.
**Auditoría barata sobre el sitio construido** (no sobre el código): recorrer el HTML generado,
listar todo `<a>` cuyo `href` sea `tel:` o `wa.me`, y comprobar que cada uno tenga `data-cta` y
que el prefijo **coincida con el tipo de href**. En CerrajeriaOK: 936 CTAs, 0 sin etiqueta,
0 mal clasificados.

### 9.7 Fraude de clics de la competencia: lo que sí se puede hacer gratis
Preocupación real del rubro (se buscan entre ellos y hacen clic para quemar presupuesto).
1. **Google ya filtra clics no válidos y no los cobra.** Lo que hay que hacer es **verlo**:
   Columnas → Modificar columnas → Rendimiento → **"Clics no válidos"** y **"Porcentaje de clics
   no válidos"**, y dejarlas fijas. 10-15 % es normal; **>20-25 % sostenido merece mirada**.
   ⚠️ Google **no entrega las IP**.
2. **Exclusiones de IP**: existen a nivel de campaña y **también de cuenta** (500 por campaña,
   comodín `*` en el último octeto). **Sólo sirven contra una IP fija.** Los celulares salen por
   **CGNAT del operador**: bloquear ese rango **deja fuera a clientes reales**. **Nunca bloquear
   un rango de operador móvil.**
3. **Para ver las IP hay que registrarlas uno mismo**: en un sitio en Cloudflare Pages, una
   Function que registre IP/ASN/hora en cada visita con **`?gclid=`** (llega solo si *Etiquetado
   automático* está en Sí — verificarlo). Ojo: una IP es dato personal; retención corta, finalidad
   declarada y mención en la página de privacidad.
4. **Herramientas de pago (ClickCease y similares): ~USD 50-60/mes.** Con presupuestos de
   ~USD 200/mes se comen un cuarto de la inversión. **No convienen a esta escala.**

⚠️ **Antes de culpar a la competencia, descartar lo aburrido:** presupuesto que se va en búsquedas
malas. **Primero el informe de términos de búsqueda, después la teoría del sabotaje.**

### 9.8 ⛔ Grabación de llamadas en Chile: NO activarla
Google Ads ofrece *Anuncios de llamada → **Grabación de llamadas*** ("la IA grabará y evaluará las
llamadas"). **Dejarla sin activar.**
- Chile exige **consentimiento previo y explícito**; no basta un aviso en la web. El Código Penal
  (art. 161-A / 161-C) sanciona grabar comunicaciones privadas sin autorización.
- **La Ley 21.719 de protección de datos entra en vigencia el 1-dic-2026**, crea la Agencia de
  Protección de Datos con potestad de multar (hasta 20.000 UTM o 4 % de ingresos; las PYMEs sólo
  reciben amonestaciones hasta dic-2027).
- En urgencias el contenido es especialmente sensible (dirección de alguien que quedó fuera de su
  casa de madrugada).
- **El beneficio es nulo con Maximizar clics y presupuesto chico.**

### 9.9 Palabras clave negativas: cargarlas a nivel de CUENTA
Configuración de la cuenta → *Palabras clave negativas* (tope **1.000**). Ventajas sobre hacerlo
por campaña: aplican a todo, **no dependen de que se destrabe la campaña** y **sobreviven si hay
que rehacerla**.
**Las que NO conviene poner aunque suenen obvias** (se llevan clientes reales por delante):
- **`gratis`** → mata "cotización gratis" / "presupuesto gratis".
- **`comprar`** → "comprar cerradura" suele ser alguien que quiere que se la instalen.
- **`trabajo` a secas** → mata "trabajos de cerrajería"; usar sólo frases de búsqueda de empleo
  ("ofertas de trabajo", "busco trabajo").

Y la regla ya conocida: **no bloquear marcas ni modelos** — en ServiClima fueron de lo que mejor
convirtió.

### 9.10 Notas sueltas que ahorran tiempo
- **Los `<material-button>` y los `<input>` de Google Ads SÍ responden a eventos sintéticos de
  JS** (setter nativo de `value` + `input`/`change`/`blur`; para botones, la secuencia
  `pointerdown/mousedown/pointerup/mouseup/click`). Corrige la nota de la sección 8.7: es **mucho**
  más rápido y fiable que `computer type`, y esquiva los congelamientos.
- **El clasificador bloquea pulsar "Publicar campaña" por JavaScript** (compromete dinero), y hace
  bien. Con el `computer` tool y un `ref` sí deja.
- **La calidad del anuncio se recalcula con ~6 s de retraso**: justo después de escribir dice
  "Agregue títulos" con 15/15 puestos. Esperar antes de creerle.
- **En el desplegable de ubicaciones, los botones Incluir/Excluir de TODAS las filas comparten la
  misma coordenada** (sólo se revelan al pasar el mouse). Clic por coordenada = ruleta: una vez
  **incluyó un municipio en vez de excluir la Región**. Localizar la fila por su texto y despachar
  el clic sobre ese elemento.
- **El aviso "Su sitio web necesita una etiqueta de Google" es esperable** mientras no haya
  tráfico de anuncios, aunque la etiqueta esté puesta y disparando. No perseguirlo hasta tener
  clics reales.
- **Medir móvil de verdad:** `resize_window` **no cambia el viewport**. Inyectar un **iframe del
  mismo origen de 390×844** y medir dentro.
- **Verificación del Perfil de Negocio:** el aviso **no sale en Ads, ni en Maps, ni al buscar el
  negocio** — sólo en `business.google.com/locations`. Y **el primer paso no es el video: pide una
  dirección postal** (que no se publica). El menú de métodos aparece después. Hay botón
  **"Verificar más tarde"** para salir sin comprometer nada.
- **Ask Advisor** (asistente Gemini en Ads, beta): inútil sin datos, y es de la misma familia que
  la *Aplicación automática* que conviene dejar **desactivada**. Si se usa, **sólo para preguntar,
  nunca para que aplique cambios**.

---

## ⚠️ La campaña que NO se deja publicar: 8 avisos de "normas editoriales" sin elemento

Ampliado el **2026-08-29** con la sesión larga de `cerrajeria-ok-cl`. Vale para cualquier sitio de
servicio local que quede trabado al pulsar *Publicar campaña*.

### El síntoma
En el resumen del asistente aparecen **N avisos idénticos**: *"Este elemento no cumple con las
normas editoriales"*, con icono de llave inglesa, **sin nombrar ningún elemento**, **sin botón
Editar ni Apelar**, y **desaparece el botón Publicar campaña**.

### Lo primero: contar en el DOM, no en una captura
La lista **se renderiza progresivamente**. Una captura sacada a medio pintar muestra 3 avisos
cuando en realidad hay 8, y de ahí sale la conclusión falsa de que "la revisión avanza".
`find` / `querySelectorAll` sobre el texto del aviso, siempre.

### Las 4 sospechas que se descartaron con prueba (no repetir el camino)
1. **"El rubro está bloqueado en el país."** Se comprueba en 2 minutos **sin borrar nada**:
   activar una campaña **Smart** de la misma cuenta (basta con presupuesto mínimo) por
   Resumen → *Ver problema* → **Reactivar**. Si queda **"Apto"**, ni la cuenta ni el rubro ni el
   sitio están bloqueados, y el problema es **específico del asistente de Búsqueda**.
   ⚠️ Pero una Smart **no se convierte** en campaña de Búsqueda: sirve de diagnóstico, no de
   destino. Y **no hace falta borrar el borrador para probar** — nunca borrarlo, es irreversible.
2. **"Falta confirmar identidad."** Es un bloqueo **real de ESCRITURA** (el asistente acepta el
   cambio en pantalla y el servidor lo descarta; abajo a la izquierda pasa de *"Se guardaron todos
   los cambios"* a **"No se pudieron guardar los cambios"**). Resolverlo **no mueve los avisos**.
   ⚠️ **Nunca pulsar "Omitir"** en ese diálogo: el cambio se pierde.
3. **Símbolos decorativos en un título** (p. ej. un punto medio `·`). Corregirlo no cambia nada.
4. **Certificación de anuncios** (Administrador → Política → Cuenta). **Sólo cubre criptomonedas,
   productos financieros especulativos y apuestas.** Para cualquier otro rubro, vía cerrada.

### La razón de fondo por la que las guías no sirven
Todas las listas editoriales de Google (Centro de ayuda, vídeo oficial, resumen por IA) describen
**anuncios RECHAZADOS**. Con la campaña en **borrador el anuncio no existe todavía**, así que
**Administrador → Política → Anuncios dice "No tiene ningún problema de política"** y la columna
**"Detalles de la política"** —la vía documentada para leer el motivo— **no tiene ninguna fila**.
Es un callejón: Google no puede decir por qué hasta que se publique, y publicar es lo bloqueado.

### Checklist que sí conviene correr igual (barato, y deja el caso cerrado)
Sobre los títulos/descripciones reales: MAYÚSCULAS completas, signos repetidos, símbolos
decorativos, espaciado, frases cortadas, ortografía, y **ningún teléfono en el texto** (va en el
recurso de llamada). Y **leer la landing** para confirmar que cada promesa del anuncio
(precio "desde", años de experiencia, cobertura, garantía) **aparece literal en el destino**.

### El único canal real para preguntarle a Google
**Ayuda ? → Enviar un mensaje → categoría "Anuncio rechazado" → Correo electrónico.**
⚠️ **La categoría manda:** *"Los anuncios no se publican"* sólo ofrece **Comunidad** (foro).
Trampas del formulario, todas comprobadas:
- El campo manual de campaña exige **`Nombre (ID)` con ID numérico puro**; `(borrador 123…)` se
  rechaza con *"Ingresa la información de la campaña en el formato requerido"*.
- El error de validación **sólo se ve abajo del todo**, junto al botón: *"Aún no pudimos enviar tu
  formulario"*. Hay que subir a buscar el campo en rojo.
- **El panel vive en un IFRAME**: `javascript_tool` sobre el documento principal no lo ve y `find`
  no lo lista. Sólo `computer` por coordenadas.
- ⚠️ **Un clic fuera de un campo convierte lo tecleado en atajos de Google Ads**: `?` abre
  "Accesos directos de teclado" y `G`+`T` navega de página, perdiendo el formulario. **Confirmar
  con captura que el campo tiene el borde azul antes de escribir.**
- El panel **no responde a la rueda del ratón**: arrastrar su barra de scroll o pulsar su flecha.

### Datos de la cuenta que conviene mirar de paso
- **Promociones** (Facturación → Promociones) suele traer un crédito del tipo *"invierte X y te
  damos X"* **con fecha límite** (60 días). Cada día bloqueado consume ese margen: es el mejor
  argumento de urgencia en el reclamo, y hay que avisárselo al cliente.
- El **Nombre de la empresa** del anuncio suele estar **vacío** (`0/25`). Es opcional —sin él se
  publica con un marcador sacado de la URL— pero conviene ponerlo, y debe **coincidir con el
  dominio**.
- URLs que dan **404** en estas cuentas: `/aw/settings/preferences`, `/aw/accountsettings`,
  `/aw/advertiserverification`. Navegar por el menú, no adivinando URLs.
- **No abrir el borrador por URL directa**: el `cmpnInfo` se vacía, el riel sale con círculos y la
  optimización marca `--.-%`. Camino válido: **Campañas → *Borradores en curso* → Finalizar**.

### Qué decirle al cliente
Que la web está lista y el bloqueo es de la publicidad; que **el propio panel de Google declara
que la cuenta no tiene ninguna infracción** y que una campaña de prueba sí se aprueba, así que
apunta a una traba del sistema y no a un error propio; que ya se escribió al soporte (**1-2 días
hábiles es lo habitual, pero Google no compromete plazo**); que la ficha está en verificación y
**debe avisar si le piden vídeo o llamada**; y que **no se ha gastado nada**. El detalle técnico
se omite: sólo genera preguntas.

---

## Anexo 2026-10-09 — Vender servicios por Meta (Marketplace vs Página + Ads) y reels con voz

Destilado de `1.Rameseba-com` (08-09 oct 2026). Detalle completo: `~/.claude/cerebro/marketing-meta-y-reels.md`.

- **Marketplace prohíbe servicios** por política oficial (solo catálogo WhatsApp Business o Citas FB/IG).
  No hay palabras «seguras». Rechazos se aceleran con 1.ª persona («te hago», «la arreglo»), boost y
  grupos sin relación. Las rechazadas no se editan ni se borran desde PC. Meta avisa «access at risk»
  antes de suspender.
- **Vía legal:** Página de Facebook + anuncio en Ads Manager (mensajes a Messenger; WhatsApp exige
  WhatsApp Business). Puede salir en la ubicación Marketplace, que es la más barata.
- **Revisar SIEMPRE los defaults de Ads Manager antes de Publish:** presupuesto (vino US$6), ubicación
  (vino Venezuela = país del perfil), chat en inglés, 5 mejoras IA + 5 textos IA activados, traducción,
  multi-advertiser. Con US$2/día: «Learning limited» normal, no tocar 5-7 días.
- **Automatización:** Claude in Chrome necesita la pestaña AL FRENTE para Ads Manager/Business Suite.
- **Reels:** edge-tts (es-CL-CatalinaNeural) + subtítulos karaoke por WordBoundary + HTML render(t) →
  playwright → ffmpeg. Capturas reales, gancho 3 s, sin música en el archivo, 1 cada 2 días.

## Anexo 2026-10-25 — Clima Frío (Venezuela): dominio + correo corporativo gratis + indexación por DNS

Medido de punta a punta en `Documents/Clima-ven` (sitio estático en Worker, cuenta Cloudflare del usuario).

**Dominio (Spaceship, cuenta del cliente):** cupón de primera compra (COM67) → .com a US$9,08. Al agregar la zona en
Cloudflare (plan Free) importa 2 registros A de "estacionamiento" de Spaceship: **borrarlos** o chocan con el Custom Domain
del Worker. Nameservers cambiados en Spaceship → zona activa en minutos, certificado en ~90 s.
**No activar la redirección 301 del subdominio de prueba al dominio nuevo hasta que la zona esté activa y el certificado
emitido:** se hizo antes y por 2 minutos el sitio redirigía a un dominio que no resolvía.
Ojo con el correo del cliente: puede venir con letras cruzadas (climafrio**anazotegui** vs anzoategui); Spaceship exige
verificarlo en ~14 días o suspende el dominio. Confirmar en "Contactos del dominio".

**Correo corporativo a costo cero (contacto@dominio):**
1. Recibir: Cloudflare Email Routing → "Add missing records" (3 MX + SPF + DKIM) → destino = Gmail del cliente
   (debe aceptar el correo de verificación; sin eso Cloudflare no deja crear la regla).
2. Enviar: cuenta **Resend del cliente** (plan gratis = 1 dominio por cuenta, por eso no la del usuario), región São Paulo
   para Latinoamérica, configuración **manual** (no "Auto configure", que pide permisos sobre Cloudflare):
   TXT `resend._domainkey`, CNAME `rsend`/`send` (DNS only), TXT `_dmarc` "v=DMARC1; p=none;". No activar "receiving"
   de Resend (su MX chocaría con Email Routing). Verificó en ~3 min.
3. Gmail → Cuentas → "Enviar como": smtp.resend.com:587 TLS, usuario `resend`, contraseña = API key de **solo envío,
   restringida al dominio** (créala después de verificar el dominio). Dejar contacto@ predeterminado + "responder desde la
   misma dirección". Filtro `to:contacto@…` → nunca spam + importante + etiqueta de color.
4. Prueba real a otra cuenta: SPF, DKIM y DMARC = pass, llegó a Recibidos.
Gotchas: Claude no puede pegar la API key (la pega el usuario); Gmail abre "Agregar otra dirección" en una ventana popup
fuera del grupo de pestañas de Claude in Chrome (no se controla; interceptar `window.open` congeló la pestaña).

**Indexación sin tocar el código:** Search Console propiedad de **Dominio** con TXT `google-site-verification` (elegir
"Cualquier proveedor de DNS" para no dar OAuth a Google sobre Cloudflare); sitemap; "Solicitar indexación" ~5-10 URLs/día
(entrar por la caja de inspección desde la Descripción general; si ya estás en una URL inspeccionada, la caja no cambia).
Bing Webmaster: verificación por CNAME `<hash>` → verify.bing.com (sin importar desde GSC). IndexNow: archivo
`/<clave>.txt` + script que manda las URLs del sitemap al final de `npm run deploy` (202 la primera vez, 200 cuando Bing ya
validó la clave). Bing alimenta ChatGPT Search y Copilot → cuenta como GEO.
