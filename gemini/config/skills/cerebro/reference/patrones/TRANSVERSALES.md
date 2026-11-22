# Patrones transversales

Destilado el 2026-08-23 del corpus de `supercerebro/` — **141 sesiones, 958 mensajes del
usuario, 2.217 fallos, 22 proyectos**. Todo lo de aquí está **medido sobre el corpus**, no
inferido: cada patrón lleva cuántos mensajes lo respaldan y en cuántos proyectos aparece.

Esto **no reemplaza** las memorias por proyecto (35 proyectos, ~200 entradas ya destiladas).
Cuando algo ya está bien escrito en una memoria, aquí se enlaza y no se repite. Lo que sí
aporta este archivo es lo que **ninguna memoria de proyecto podía ver**: lo que se repite
*entre* proyectos.

---

## 1. Cómo trabaja el usuario (contado, no supuesto)

| Tema | Mensajes | Proyectos | Estado |
|---|---|---|---|
| Guardar en memoria / supercerebro | **91** | 12 | Es el tema #1 de todo el corpus |
| Coste: tokens, cuota, créditos | **72** | 11 | Restricción real, no manía |
| Móvil: largo vertical, 2x2, responsive | **54** | 10 | La queja de diseño #1 |
| Entorno PowerShell | **53** | 10 | Fuente constante de fricción |
| SEO / posicionamiento | 42 | 9 | Encargo recurrente del cliente final |
| Replicar hallazgos a la familia | 42 | 8 | Modelo de negocio, no capricho |
| Verificar en vivo, no en localhost | **34** | 8 | Corrección explícita, repetida |
| Crédito `rameseba.com` en el footer | 20 | 5 | Va en **todo** lo que entrega |

### 1.1 Persistir el estado es lo que más pide (91 mensajes)
Más que cualquier tarea técnica. El motivo está dicho por él: la cuota se consume y necesita
poder hacer `/clear` sin perder el hilo. Ya está como regla global en `~/.claude/CLAUDE.md`.
Lo que el corpus añade: **lo pide antes de irse, antes de reiniciar el PC y antes de cada
`/clear`**, y varias veces tuvo que pedirlo dos veces en la misma sesión.

### 1.2 «Siempre en vivo, nunca localhost» (34 mensajes, 8 proyectos)
La corrección más explícita del corpus, piel-y-trigo 2026-08-01:

> *"pero eso lo hiciste en localhost.... te dije que siempre todo online amigo.... recuerda eso
> y supongo que este último cambio de /admin/productos también lo hiciste solo local."*

Ya está destilado para un proyecto en `piel-y-trigo-cl/memory/feedback-verify-on-production.md`.
**El corpus demuestra que aplica a 8 proyectos, no a uno.** Regla: un cambio no está hecho
hasta verlo funcionando en la URL pública.

### 1.3 El crédito en el footer va sin que lo pida (20 mensajes, 5 proyectos)
`diseñado por rameseba.com`, **destacado**, en todo sitio que entrega a un cliente. Está en
`fumugaciones-ranco/memory/feedback-credito-rameseba.md`; el corpus lo confirma también en
AirSoft, León Láser, Kental y Piel y Trigo. No hay que preguntarlo.

### 1.4 Sin sub-agentes
Regla global ya vigente. Registrada además en `imperio-morales/memory/feedback_no_agents.md` y
`Sensores/memory/cliente-no-usar-subagentes.md`. Motivo dado siempre el mismo: consumo de
cuota, no calidad.

---

## 2. ⚠️ Muchos mensajes son DICTADOS por voz — hay que interpretar, no leer literal

Hallazgo nuevo, no registrado en ninguna memoria, y explica malentendidos reales del historial.
Una parte grande de los mensajes largos entra por transcripción de voz, con errores
**sistemáticos** sobre nombres propios y términos técnicos. Ejemplos reales del corpus:

| Lo transcrito | Lo que quiso decir |
|---|---|
| «pruebas de **cuba**» | pruebas de **QA** |
| «**Beauty Camp Work**» | **BeautyGangWorld** |
| «**clouser**» | **Cloudflare** |
| «**Sonet 5**» | **Sonnet 5** |
| «con las manos de **una madre**» | con **nano banana** (generador de imágenes) |
| «**ramiscob**.com» | **rameseba**.com |
| «el **mundo** total del Dashboard» | el **monto** total |
| «**anti-gravity**» | **Antigravity** |
| «**apícala** 2x2» | **aplícala** 2x2 |
| «la aplicación se creó **Dañón**» | se **dañó** |

**Regla:** ante un nombre que no existe, buscar el término real más cercano del proyecto antes
de responder o de pedir aclaración. Preguntar «¿qué es Beauty Camp Work?» hace perder un turno
por algo que era obvio en contexto. Y al revés: **si la interpretación cambia lo que se va a
hacer, confirmar** — no adivinar sobre una decisión.

---

## 3. Diseño: la queja #1 es el LARGO VERTICAL en móvil (54 mensajes, 10 proyectos)

No es «no me gusta el diseño» genérico. El corpus es muy específico y muy repetido:

> *"es infinitamente larga y ... le falta optimizar en mobile"* (AirSoft, 2026-08-07)
>
> *"hay que arreglar el diseño para movil, esta super mal optimizado, toma ejemplo de otros
> proyectos como gamesgod"* (AirSoft, 2026-08-07)
>
> *"ocupan mucho espacio verticalmente ... deberían ser 2x2"* (Fumigaciones, 2026-08-15)

**Reglas que se desprenden, aplicables a cualquier sitio nuevo:**

1. **Móvil primero y de verdad.** Lo dice explícitamente en León Láser, Kental y AirSoft.
2. **Tarjetas en 2x2 en móvil, no apiladas.** Es su petición literal, repetida en 4 proyectos.
   Una lista de 6 tarjetas apiladas es un defecto, no una opción de diseño.
3. **Referencia interna, no abstracta.** Cuando algo está mal, señala un proyecto suyo que está
   bien (gamesgod, akim). Conviene mirar ese proyecto antes de rediseñar a ciegas.
4. **«Está muy IA»** es feedback real y recurrente: significa espaciados grandes y uniformes,
   secciones intercambiables, sin jerarquía. Las skills de diseño instaladas
   (`impeccable`, taste-skills) están para esto — ver
   `1-Rameseba-com/memory/skills-diseno-instaladas.md`.
5. **Si pasa una imagen, un PDF o un logo de referencia, ESO es la especificación.** Tres quejas
   independientes por lo mismo: *"no usaste las fotos que te pedí"* (AirSoft); en León Láser se
   ignoró la paleta del PDF que había enviado; en Kental un logo revectorizado «no es 100% fiel
   a la imagen». Antes de dar por bueno un diseño: comprobar uno por uno los archivos que él
   entregó.
6. **Efectos que cuesten GPU, fuera.** AirSoft 2026-08-14: un fondo reactivo al mouse dejaba el
   scroll «pegado». Lo aceptó como bonito y lo rechazó igual por rendimiento.

---

## 4. El entorno es PowerShell en Windows — y es el error que más tiempo quema

53 mensajes lo tocan. Los fallos concretos que aparecen **una y otra vez en proyectos
distintos**, siempre por escribir sintaxis de bash:

```powershell
# NO existe en PowerShell - se interpreta como nombre de comando
CONVEX_DEPLOY_KEY= npx convex run ...
CONVEX_DEPLOY_KEY="prod:..." npx convex run ...
# -> "El termino 'CONVEX_DEPLOY_KEY=' no se reconoce como nombre de un cmdlet"

# SI
$env:CONVEX_DEPLOY_KEY=""; npx convex run ...
```

```powershell
# en la consola del usuario esto revienta
cd web && npx vercel deploy --prod
# -> "El token '&&' no es un separador de instrucciones valido en esta version"

# SI
cd web; npx vercel deploy --prod
```

Ocurrió en **piel-y-trigo, truckdiesel y santaluciaresidencia** por separado. Y no es sólo un
error mío: son comandos que **le paso al usuario para que los pegue**, y le revientan a él. Ahí
está el coste real.

Otros del mismo entorno, ya registrados en memorias de proyecto:

- `vercel.ps1` bloqueado por ExecutionPolicy → usar `vercel.cmd` o Git Bash. **No cambiar la
  política.** (`akim-pet-market-web`)
- `fatal: unable to auto-detect email address` — 4 veces en 4 proyectos: repo nuevo sin
  `user.email`.
- `fatal: not a git repository` — 16 veces en 3 proyectos: comando git lanzado en un directorio
  que no es repo. Confirmar el directorio antes.

---

## 5. Automatización del navegador: el fallo más repetido de todo el corpus

**102 fallos en 10 proyectos**, todos la misma familia:

```
Error capturing screenshot: CDP sendCommand "Page.captureScreenshot" timed out
  after Nms on tab N. The renderer may be frozen or unresponsive.   (58 veces, 10 proyectos)
Failed to execute JavaScript: CDP sendCommand "Runtime.evaluate" timed out       (26 veces, 7)
Error capturing screenshot: Frame with ID N is showing error page                (13 veces, 3)
Region exceeds viewport boundaries                                                (5 veces, 4)
```

Causas ya identificadas y con arreglo conocido (están en el `CLAUDE.md` global; aquí queda la
medida de cuánto duelen):

- Un `alert()`/`confirm()` nativo **congela el renderer**. Arreglo: parchear `window.alert`
  ANTES de enviar el formulario y leer el buffer después.
- Menús y pestañas de Radix no responden a `.click()` sintético.
- La región de un screenshot con zoom debe caber en el viewport: calcularla, no adivinarla.

**Y una causa que hasta ahora no estaba conectada:** el proceso GPU de la app de escritorio se
cae solo cada ciertos días (diagnosticado el 2026-08-22, ver la memoria
`crash-app-escritorio-gpu` en el proyecto piel-y-trigo-cl). Parte de estos «renderer frozen»
son el mismo problema de composición GPU, no siempre un `alert()`.

**Además:** el usuario tiene **dos PC y varios perfiles de Chrome**. Dos correcciones distintas
por abrir el equivocado: *"ya lo abrí de nuevo, es en este ordenador, abriste mi otro
ordenador"* (akim) y *"no abras el de dixon, no le mandes la notificación"* (piel-y-trigo,
repetido en kental). **Confirmar en qué máquina y perfil se está antes de automatizar.**

---

## 6. La familia de tiendas: replicar es el modelo de negocio (42 mensajes, 8 proyectos)

No es una preferencia, es cómo gana dinero: una plantilla, muchos clientes. Lo dice claro:

> *"esto luego lo verificaremos si pasa en los proyectos hijos de este ya que akim es el
> primero"* (akim, 2026-07-29)
>
> *"guárdalo en tu memoria y en el supercerebro para que luego podamos revisar estas mismas
> auditorías en los otros proyectos cuando yo te lo diga"* (piel-y-trigo, 2026-08-23)

El catálogo de patrones de la familia (pagos, checkout, Convex, censura de queries, cupones,
despacho) ya vive en `~/.claude/CLAUDE.md`, es largo y está al día. **No duplicarlo aquí.**
Lo que aporta el corpus es el orden en que él quiere que se haga:
**cerrar la tienda en curso primero, replicar después**, nunca al revés. Lo dijo en Piel y
Trigo el 14-ago y lo repitió el 22-ago.

---

## 6bis. Quien administra el sitio NO es el usuario *(añadido 2026-08-28, AirSoft-cl)*

El usuario sabe de tecnología; **sus clientes, no**. En `AirSoft-cl` lo pidió explícito:
*«ve si todo se puede editar de manera fácil para un señor que no sabe usar mucho la
tecnología, y si no es así, hazlo más intuitivo o simple o con ejemplos»*.

Al revisar las once pantallas del panel, el patrón fue claro: **las pantallas que se
construyeron con calma estaban bien y las añadidas después se quedaron atrás**. Eventos y
Servicios explicaban cada dato («Solo el número, sin puntos ni $», «Reservaron por la web,
pagan en cancha»); Ajustes tenía **doce casillas con etiqueta y ninguna explicación**, dos de
ellas llamadas «WhatsApp» sin decir en qué se diferenciaban.

Lo que hay que revisar en el panel de cualquier proyecto suyo:

1. **Cada campo, un ejemplo dentro** (`placeholder`) y una línea de para qué sirve. Un campo
   que no se entiende o se deja vacío o se llena mal, y las dos cosas salen publicadas.
2. **Fuera las palabras de sistema**: «Órdenes» → «Inscritos», `owner` → «dueño»,
   `redcompra` → «Red Compra», «Texto alternativo» → «Qué se ve en la foto», «Antetítulo» →
   «Línea pequeña de arriba». `grep 'label="'` y leer cada una en voz alta.
3. **Si un dato se copia de otro sitio, aceptar el formato en que se copia.** Google Maps
   copia latitud y longitud **juntas y separadas por coma**; pedirlas en dos casillas hacía que
   pegar el par entero —lo natural— dejara la ficha inservible sin decir por qué.
4. **Un contador que no cuadra con la web destruye la confianza.** La pestaña de inscritos
   incluía los cancelados: decía 16 mientras el sitio decía 1.
5. **Jerarquía en las acciones repetitivas.** Cada fila ofrecía los cinco estados a la vez: con
   16 inscritos, 80 botones iguales. Uno grande con el paso que toca, el resto detrás de
   «Cambiar».
6. **Decir cuándo dejar algo vacío es correcto.** Los datos bancarios van vacíos a propósito;
   sin una nota, quien administra cree que le falta rellenarlos.

---

## 7. Lo que NO hay que volver a proponer

Decisiones ya tomadas por él. Volver a sugerirlas es gastarle un turno:

- **Sub-agentes para hacer el trabajo.** (Sólo si los pide por nombre.)
- **Web Analytics de Vercel.** Desactivado a propósito: en Hobby sólo va en un proyecto y se
  come la cuota. (`~/.claude/CLAUDE.md`, corrección del 17-ago.)
- **Bloquear crawlers y agentes de IA.** Los quiere: ChatGPT ya recomendó una de sus tiendas y
  el agente navegó a comprar. Cualquier protección debe ser por patrón de ruta.
- **Copia de seguridad automática de los chats.** Ofrecida el 2026-08-22 y **rechazada**: le
  basta con que el CLI siga funcionando.
- **Reestructurar `~/.claude/CLAUDE.md`.** Decidido que se queda como está; sólo se corrigen
  datos falsos.

---

## 7bis. Inferir en vez de mirar — los 6 errores de una sola sesión *(añadido 2026-08-29)*

Todos del mismo día, todos de la misma forma: **deducir de una señal indirecta algo que estaba a un
comando de distancia de comprobarse.** Ninguno causó daño porque se detectaron al verificar, pero
tres llegaron a decirse en voz alta como hechos.

1. **Inferí el camino de despliegue de `gh api .../deployments`.** No registraba nada desde hacía
   tres semanas → concluí "la integración Git↔Vercel se cortó" y "el sitio está atrasado". Las dos
   falsas: ese proyecto se despliega **a mano por CLI**, así que GitHub no ve nada, y había rondas
   en producción de los días siguientes. **Nunca inferir qué hay en producción a partir de
   `origin`: pushear y desplegar pueden ser caminos separados.**
2. **Afirmé cómo compila un proyecto mirando solo `package.json`.** Dije que el build no desplegaba
   Convex; `vercel.ts` sobrescribía el `buildCommand` y sí lo hacía. **Buscar `vercel.ts` /
   `vercel.json` antes de afirmar nada sobre el build.**
3. **Reconstruí a mano un procedimiento de despliegue sin mirar `scripts/` del repo**, donde estaba
   `deploy-prod.sh` haciéndolo todo.
4. **Descarté el scope real por un mensaje de error engañoso.** Vercel responde *"The specified
   scope does not exist"* cuando la sesión **no tiene acceso** a ese scope. Existía. Había una
   pista ignorada: `vercel whoami` decía `Not authorized`. **Ante "no existe", sospechar de
   autenticación antes que del nombre.** Y antes de declarar "no puedo", buscar la vía con token:
   la había, y no requería `vercel login`.
5. **Un grep demasiado estrecho me hizo declarar limpio lo que no había mirado.** Busqué
   `storage.getUrl` solo en `convex/` y dije que las tiendas estaban bien; usan Cloudinary y
   Supabase Storage, otro mecanismo. Al ampliarlo apareció un sitio **caído por cuota**. El usuario
   dudó de mi barrido y tenía razón.
6. **Medí con la herramienta equivocada y construí un hallazgo entero encima.** `naturalWidth` del
   DOM da la mitad de los píxeles reales con un loader custom de `next/image` (ver
   `TIENDAS-CONVEX-NEXT.md` 3.7). Reporté dos "hallazgos" de imágenes que no existían.

**La regla que resume las seis:** cuando una conclusión va a cambiar el plan o a decirse como
hecho, hay que llegar a ella **midiendo la cosa**, no una señal correlacionada. En esta sesión
todas las comprobaciones que faltaban costaban entre 10 segundos y 5 minutos.

**Complemento del lado bueno:** lo que sí funcionó fue medir en producción y con dos peticiones
(la 2ª es la que dice si algo cachea), y **verificar de forma independiente lo que reporta otro
agente** antes de darlo por bueno — se sostuvo, pero la comprobación es barata.

---

## 8. Vacíos del propio corpus (leerlo con esto en mente)

- **`Windows-System32` tiene 19 mensajes del usuario y 0 de Claude.** No es un proyecto: es una
  sesión abierta desde el directorio equivocado.
- **`errores.jsonl` no está clasificado de forma fiable.** Cada registro arrastra el contexto
  que lo rodea, así que un filtro por palabra clave deja **1.459 de 2.217 sin clasificar** y
  produce muchos falsos positivos (una línea de código que contiene `404` cuenta como error).
  Los recuentos del apartado 5 salen de **cadenas de error repetidas literalmente**, que sí es
  fiable. Para cualquier análisis nuevo de fallos, usar ese método y no el conteo por palabra
  suelta.
- **Las 564 imágenes del usuario siguen sin describir.** Es el paso que depende de él
  (`PROMPT-ANTIGRAVITY-IMAGENES.md`). Sin eso, todo el feedback visual —que es el grueso de sus
  correcciones de diseño— queda fuera del corpus consultable.
- `arias-wear-cl` aparece con 2 mensajes, pero tiene **19 archivos de memoria**: casi todo su
  historial es anterior a las 141 sesiones extraídas. El corpus **no** es el historial completo
  del usuario, sólo el de Claude Code en este equipo.

## Patrones del POS rameseba (Sistema-inventario, 2026-10-12/13)
- **Next.js en Cloudflare Workers es lento por arranque en frío, no por la base:** 1 de cada 3 pedidos cae en un isolate
  frío (0,5–1 s de CPU; bundle 15 MB). Solución que funcionó: un Worker chico aparte (API JSON, 0–1 ms CPU, 0 fríos) y
  vistas del navegador que lo consumen + copia en localStorage; server actions críticas (cobrar) por la API con respaldo
  automático a la acción de Next. Medir con `wrangler tail --format json` (cpuTime/wallTime).
- **Modo oscuro roto solo en teléfonos:** un `@media (hover:none) and (pointer:coarse)` que pone fondos sólidos fijos
  (para no usar backdrop-filter) deja superficies claras con texto claro si el tema oscuro solo traduce variables.
  Auditar con un medidor de contraste en JS sobre todas las pantallas en emulación móvil táctil.
- **Bloqueo por inactividad en iOS:** no usar un `setInterval` que marque "sigo aquí": iOS lo reanuda al volver antes del
  `visibilitychange` y reinicia el contador. Contar el último toque (pointerdown/keydown) y chequear antes de renovar.
- **web-push funciona en workerd** (nodejs_compat): probado cifrar y enviar. Igual agregar botón "enviar aviso de prueba"
  que muestre el motivo del fallo, porque los avisos solo salen cuando hay algo que avisar y nadie nota que no llegan.
- **Lector de códigos en iPhone:** ZXing-js es flojo; usar `barcode-detector` (zxing-cpp wasm) con el .wasm servido desde
  el propio sitio y CSP `'wasm-unsafe-eval'`; aceptar un código 1D cuando sale igual en dos cuadros seguidos.
- **Pagos mixtos en la caja:** el monto auto-sugerido de un medio debe recalcularse cuando cambian los otros; si no, queda
  un "Resta" que nadie entiende. Y la calculadora dentro del cobro debe abrir con la tasa real del cobro (no la oficial).
- **Versión en otro idioma = mismos componentes** (2026-10-22, ricardo-paredes): una página aparte "resumida" el usuario
  la rechaza. Pasar `lang` a los componentes; contenido del panel traducido solo si sigue igual al de fábrica; errores del
  servidor traducidos por encabezado (`X-Lang`), incluidas respuestas 200/402 con texto, no solo los throw.
- **`content-visibility: auto` solo DESPUÉS de efectos con posiciones cacheadas** (canvas/scroll): antes los descuadra.
  Para hallar qué encarece el layout: traza + CSS inyectado quitando una sección a la vez, mediana de 5 corridas.
- **Precios de dominios en comparadores (tld-list) pueden ser falsos**: verificar en el registrador antes de recomendar.
- **Prueba en producción, con permiso**: una transacción por idioma, datos de prueba evidentes, todo registrado (HAR,
  consola, capturas) y deshecha al final por el flujo del cliente. Encuentra caché/CSP/contraste que lo local no ve.

## Paneles PWA en Cloudflare (POS, 2026-10-24) — detalle en ~/.claude/cerebro/sitios-astro-worker-patrones.md
- Tras `pnpm install` en monorepo, verificar UNA sola versión de React en el paquete (dos = pantalla rota en prod).
- El botón «Recargar» de una PWA con service worker debe borrar la página guardada; si no, reabre la versión rota.
- Un cron de Cloudflare puede quedar registrado pero sin dispararse tras un incidente: cambiar la expresión por una equivalente.
- Animaciones con `transform` atrapan a los hijos `position: fixed` mientras duran: bloques con hojas fijas, solo fundido.

## Diseño aprobado «no parece IA» (2026-10-25, Universidad-abierta-internacional)
Guía completa: `~/.claude/cerebro/guia-diseno-aprobada.md`. Destilado: copiar la estructura de sitios reales del
rubro (el del cliente + un competidor) y decir qué pieza viene de cuál; solo colores del logo; antetítulo como
texto espaciado (nunca píldora); páginas internas con banner de foto de borde a borde; secciones compactas y con
imagen; fotos Flow con el logo bajadas en 2K; `sizes` de banners pensando en el recorte móvil; QA visual
automático (contraste, píxeles, anclas, botones, letra) antes de entregar.

## 2026-11-06 — Maqueta aprobada = diseño final (altagamaled-cl)
Cuando el cliente aprueba una maqueta, la web real debe usar **ese mismo CSS y estructura**, no un estilo «parecido» sobre la base
técnica de otro proyecto: el usuario lo calificó de «horrible». La base técnica (panel, Worker) se reutiliza; el diseño no.
Y las fotos reales con fondo de bodega se pasan a fondo de estudio (rembg) para que no desentonen con la maqueta.
Al aprobarse y publicarse la web real: borrar propuesta + maqueta (online y PC), moviendo antes logo/fotos/video al repo oficial.

## Programas propios de escritorio (2026-11-16, Probador de cargador)
- El usuario rechaza una ventana hecha con WinForms desde PowerShell: letra borrosa al 125 %, no responsive, ícono de PowerShell en la barra. Lo que sí aceptó: interfaz web local servida por un motor PowerShell y abierta en ventana propia de Edge (`--app`), con un .exe lanzador con ícono.
- En PowerShell `$Y` y `$y` son la misma variable: un bloque pisado por una cadena falla con «el término "236.0" no se reconoce».
- Para logos: mostrar 3 o 4 opciones en una hoja y que elija. Dos intentos adivinando fueron rechazados.
- Detalle completo: `~/.claude/cerebro/herramientas-locales-windows.md`.
