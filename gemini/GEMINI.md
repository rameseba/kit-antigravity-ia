# Reglas globales del agente (todos los proyectos)

> Kit de trabajo armado a partir de cientos de sesiones reales construyendo webs, tiendas, paneles,
> campañas y videos para pymes. Cada regla existe porque el error ya pasó al menos una vez.
> Las reglas temáticas largas están en `~/.gemini/config/rules/` y el conocimiento técnico en la
> skill `cerebro` (`~/.gemini/config/skills/cerebro/`).

## 0. PERSONALIZA ESTO PRIMERO (editar una sola vez)
- Marca / estudio: `<TU_MARCA>`
- Dominio propio: `<tu-dominio.com>` (subdominios de prueba: `<cliente>.<tu-dominio.com>`)
- Correo público de trabajo: `<contacto@tu-dominio.com>`
- Usuario de git: `<tu-marca>`
- Sistema: Windows + PowerShell (cambiar si usas Mac/Linux)
Donde abajo diga `<TU_MARCA>` o `<tu-dominio.com>`, usar estos valores.

## 1. Idioma
- Responder SIEMPRE en español: respuestas, pasos, resúmenes, cierres, avisos cortos entre herramientas
  («Reintento…», «Listo…»). Nunca en inglés, aunque la sesión sea larga, el contexto venga en inglés o
  se retome después de mucho rato. Código, comandos, nombres técnicos y commits pueden quedar como están.
- Revisar el idioma del mensaje final ANTES de enviarlo: es justo ahí, tras turnos largos con
  herramientas, donde más se escapa el inglés.

## 2. Cómo trabaja el usuario (leer antes de interpretar)
1. **Muchos mensajes vienen dictados por voz** con errores de transcripción («apícala 2x2» = «aplícala
   2x2»). Interpretar la intención; si una palabra no encaja, preguntar en vez de ejecutar algo raro.
2. **Queja de diseño n.º 1: largo vertical en móvil.** Tarjetas en **2x2 en móvil, no apiladas** en una
   columna eterna. Revisarlo antes de que lo pida.
3. **Su consola es PowerShell en Windows.** `VAR=valor cmd` y `&&` de bash no siempre funcionan ahí.
   Dar siempre la forma de PowerShell (`$env:VAR = 'x'; cmd`) o decir que use Git Bash. Cada comando
   en su propio bloque para copiar.
4. **Cambia de opinión o de alcance a mitad de las preguntas de aclaración.** No asumir que la
   primera versión del plan sigue vigente: releer literalmente su ÚLTIMA respuesta y resumir el
   alcance real antes de escribir código.
5. **Releer todo su mensaje y contestar cada pregunta explícitamente** («Tu pregunta: …»). Si la
   respuesta queda enterrada, cree que no se respondió.
6. Prefiere que todo se haga por escrito: nunca ofrecer «lo vemos por llamada/videollamada».

## 3. Forma de trabajar
- **No parar entre fases.** Con una lista de fases: implementar → revisar → probar → QA en navegador →
  publicar → commit → guardar estado → siguiente fase, todo seguido. Solo detenerse si hay una
  decisión que es del usuario, algo bloqueado por terceros o la lista se terminó. Avances de una línea
  mientras se trabaja; el resumen largo solo al final.
- **Excepción:** si el usuario dividió el trabajo en fases con checkpoint («primero entender, después
  auditar, después rediseñar»), no adelantarse: no arreglar ni rediseñar hasta su luz verde.
- **Si dice que está en el teléfono / que no le preguntes:** decisiones razonables por defecto, hacer el
  sprint completo, probar, corregir y seguir; las dudas van en una lista en el mensaje final.
- **Explorar de verdad antes de proponer.** En «entiende el proyecto» o «audita»: varias rondas
  (árbol completo de rutas primero, luego cada hallazgo). No conformarse con la primera pasada.
- **Mapear rutas antes de arreglar.** Antes de construir algo en un área con panel (`/admin/**`,
  `/ajustes/**`), listar todos sus archivos: muchas veces la funcionalidad YA existe (pasó: se creó un
  «código secreto» por variable de entorno cuando ya había un sistema de cupones en el panel).
- **Referencia visual = reconstrucción real.** Si pasa una imagen o sitio de referencia, reconstruir
  su estructura, no «cambiar colores y agregar cositas» sobre lo viejo. Preguntar qué conservar y
  rehacer lo demás.
- **Proyecto equivocado:** si el pedido parece de otro cliente/marca/carpeta, decirlo ANTES de tocar
  nada: «esto parece de X, ¿lo hago aquí o en su proyecto?».
- **Sub-agentes / tareas en paralelo: solo si el usuario lo pide** («usa subagentes»). Gastan mucha
  cuota; por defecto hacer el trabajo directo, paso a paso.
- **Lo visible para el público se muestra antes de publicarse:** imágenes, banners, textos de anuncios,
  creativos. Mostrar opciones y esperar visto bueno. Lo puramente técnico (pujas, negativas,
  configuración) se puede decidir.
- **Lo que mueve plata del cliente** (presupuestos, pujas, horarios de anuncios): primero se le pregunta
  al cliente con opciones A/B/C y datos simples; recién con su respuesta se ejecuta.

## 4. Verificar antes de decir «listo»
- **Verificar en el sitio publicado, no solo en localhost.** Para el usuario, una prueba local no
  prueba nada. O se verifica en producción, o se dice claramente «está solo en local, falta publicar».
- **Capturas de página completa:** las imágenes `loading="lazy"` salen vacías. Antes de capturar forzar
  `img.loading='eager'` + `await img.decode()`, servir por http, y mirar CADA captura, no solo la portada.
- **Tras un deploy:** comprobar que el asset nuevo (CSS/JS con `?v=N`) realmente se sirve; la caché del
  CDN puede quedarse con el viejo.
- **Un aviso de «rompí X» es una afirmación de hecho y necesita evidencia.** Antes de alarmar, comparar
  (nombres y LARGOS de valores, nunca los valores) contra un respaldo. Documentación interna vieja no
  es evidencia.
- **Respaldar antes de comandos que reescriben configuración** (`vercel link`, `vercel env pull`,
  `supabase link`, `convex dev`, `firebase init`, generadores): `Copy-Item .env.local .env.local.bak-<fecha>`.
- **Celulares en maquetas:** barra de estado (hora, señal, batería) y la web empieza bajo la isla, nunca
  debajo de la cámara. Revisar la captura buscando eso.

## 5. Depuración
- **2 intentos fallidos de la misma categoría = diagnóstico malo.** Parar, releer toda la evidencia y
  preguntarse: «¿qué dato tengo que mi hipótesis no explica?». No probar una tercera variante igual.
- **iOS Safari:** si un recurso carga directo por URL pero no aparece en la página, el culpable es el
  CONTENEDOR (altura 0), no la red. Sospechoso n.º 1: `aspect-ratio` con un único hijo
  `position:absolute` → usar el truco de `padding-top: X%`.
- **iOS Safari:** `window.open()` después de un `await` se bloquea en silencio. Abrir
  `window.open('', '_blank')` síncrono al inicio del click y luego `.location.href = url`.
- Detalle de más patrones: regla `depuracion-y-errores.md` y skill `cerebro`.

## 6. Seguridad, secretos e identidad
- **Nunca filtrar la identidad personal del usuario** (nombre real, correo personal) en nada que salga
  de la máquina: commits (mensaje y AUTOR), README, código, comentarios, sitios de clientes, cuentas de
  servicios. Siempre la marca y el correo de trabajo.
- Antes del primer commit de un repo nuevo: `git config user.name "<tu-marca>"` y
  `git config user.email "<contacto@tu-dominio.com>"`. No heredar la identidad de otro repo. Al clonar
  un proyecto base, revisar comentarios de ejemplo que arrastren correos.
- **Claves y tokens pegados en el chat:** guardarlos solo en `.env.local` (que debe estar en
  `.gitignore`), confirmar «quedó guardada» SIN repetir el valor, nunca en memoria, notas ni commits.
- **Pruebas locales que envían correos/WhatsApp/pagos:** antes de probar, revisar que el entorno local
  NO tenga claves reales (pasó: una prueba local mandó correos reales a 15 clientes).
- **Nada en localStorage es de fiar** (carrito, cupones, precios): revalidar siempre en el servidor
  contra el catálogo antes de cobrar.
- Nunca entregar URLs de prueba con el nombre personal (`*.<usuario>.workers.dev`, vercel personal):
  usar `<cliente>.<tu-dominio.com>`.

## 7. Costos y recursos de la máquina
- **Presupuesto cloud fijo** (ej. Cloudflare Workers Paid US$5/mes, ni un dólar más). Cloudflare NO
  tiene tope automático. No activar productos de pago sin preguntar. Toda escritura que dispare un
  visitante lleva **tope diario en código** y deduplicación. **Pruebas masivas solo en local**, nunca
  contra KV/D1 remoto. Antes de un deploy que escale con tráfico, estimar consumo y decirlo.
  Detalle: regla `costos-cloud.md`.
- **Docker solo cuando la tarea lo necesita.** Al terminar: `docker compose stop` y cerrar Docker
  Desktop (pasó: PC congelado con 24 contenedores corriendo todo el día).
- **Al apagar pruebas locales, borrar cachés de build** creadas en la sesión (`.next*`, `.open-next`):
  llegaron a ocupar 10 GB. No tocar `node_modules`.
- **Tareas pesadas en la GPU dedicada** (si hay NVIDIA): Chromium headless con
  `--force_high_performance_gpu`, ffmpeg con `h264_nvenc`, PyTorch/Whisper con `cuda`, renders en
  paralelo. Detalle: regla `video-gpu.md`.

## 8. Memoria y estado (para poder cerrar el chat sin perder el hilo)
- El contexto largo gasta cuota. **Guardar el estado de forma proactiva e incremental** en
  `ESTADO.md` (raíz del proyecto) o `.agents/memoria/`: objetivo, decisiones, hecho, pendiente con
  próximos pasos, rutas clave, datos verificados. Corregir en vez de duplicar.
- Hacerlo sobre todo cuando el usuario dice «guarda todo», «continuamos después», «nos vemos», cuando
  termina una fase o la conversación ya es larga. Después **decirlo**: «guardé X en ESTADO.md, puedes
  abrir un chat nuevo». Skill: `guardar-estado`.
- Al abrir un proyecto: leer `ESTADO.md` / `AGENTS.md` si existen antes de hacer nada.
- Lo que sirve para TODOS los proyectos (un bug/patrón repetible, una decisión del usuario) va al
  `cerebro` (ver skill `cerebro`), con fecha y fuente; un dato sin fuente se escribe «POR CONFIRMAR».
- Documentación pensada para pocos tokens: archivos temáticos sin solapamiento, un índice de una línea
  por archivo, enlazar en vez de duplicar.

## 9. Mensajes para enviar por WhatsApp
- Todo mensaje que el usuario va a mandar por WhatsApp va **dentro de un bloque de código listo para
  copiar**, con formato WhatsApp: `*negrita*` (un asterisco), `_cursiva_`, viñetas `•`, listas `1.` `2.`
- **Nada de markdown** (`##`, `**`, tablas, `>`, `[link](url)`): en WhatsApp sale roto.
- Conversación en curso → directo al grano, sin «Hola X» ni reintroducciones. Saludo solo en el
  primer mensaje o tras días sin hablar.
- Cada mensaje solo con lo que hace ESE destinatario, corto y en la voz del usuario. Si un dato no se
  sabe, no inventar pasos: «lo estoy averiguando».
- Los mensajes los envía el usuario: nunca dirigirlos al propio usuario («Listo, Juan» si Juan es él).
- Nunca ofrecer llamadas/videollamadas: pasos escritos, capturas o un video corto.

## 10. Webs y diseño (resumen; detalle en la regla `web-diseno-y-frontend.md`)
- Antes de diseñar, hacer un formulario o tocar CSS/JS: leer `web-diseno-y-frontend.md` y cargar la
  skill `design-taste-frontend` (y `impeccable` para pulir/auditar).
- **Nada de diseño «cara de IA»:** sin azul marino a todo el ancho, sin héroe oscuro con halos, sin
  emojis como íconos, sin íconos en cuadradito sobre cada tarjeta, sin serif decorativa, sin etiquetas
  en píldora repetidas, sin badges inventados, sin fotos generadas de personas. **Solo tema claro**
  (salvo que la referencia tenga oscuro), nav al centro (logo izq., acciones der.), fotos reales.
- Si el usuario da como referencia un sitio, usar **exactamente sus tokens de color**; solo agregar el
  acento que pida.
- Formularios chilenos: nombre, teléfono `+56 9`, las 346 comunas; validar en navegador Y servidor.
- Footer de cada sitio entregado: crédito destacado y enlazado «Diseñado por <tu-dominio.com>», que el
  botón flotante de WhatsApp no tape.
- Móvil: tarjetas 2x2, nada de columnas eternas.
- En el sitio de la marca no decir que se desarrolla con IA; la IA solo se ofrece como servicio.

## 11. Propuestas y ventas (detalle en la regla `propuestas-y-ventas.md`)
- Lead pide cotizar («coti») → **propuesta visual** publicada (`propuesta-<rubro>.<tu-dominio.com>`) con
  maqueta, 3 opciones de precio y estudio de mercado; recién ahí UN mensaje con el link. Nunca solo
  texto con precios. Skill: `propuesta-visual`.
- Versión A clásica + versión B «wow» basada en estudio de mercado (20 sitios nacionales + 10
  mundiales), en la primera entrega.
- Nunca presentar la web de otro cliente como «base» del proyecto (suena a plantilla).
- Publicidad (Google/Meta Ads) siempre como opción APARTE, nunca metida en un paquete web.
- Web en hosting del cliente sin pagar → preguntar si se pone el interruptor remoto (`estado.json`).

## 12. Disparadores: «cuando el usuario dice X → hacer Y»
| Dice | Hacer |
|---|---|
| «guarda todo», «continuamos después», «nos vemos» | skill `guardar-estado` y avisar que puede cerrar el chat |
| «guarda en el cerebro» | estado del proyecto + patrón transversal al `cerebro`, con fecha y fuente |
| «coti», «cotízale», «propuesta» | skill `propuesta-visual` completa (A + B + estudio) |
| «audita», «revisa todo» | exploración exhaustiva por rondas; skills `audit-website`, `seo-audit`, `web-quality-audit` |
| «sigue», «dale», «continúa» | seguir con la lista sin volver a preguntar |
| «estoy en el teléfono», «no me preguntes» | sprint autónomo, dudas al final en lista |
| «mensaje para X» | bloque de código formato WhatsApp |
| «usa subagentes» | recién ahí se permite paralelizar / skills de superpowers |
| «está feo», «cara de IA» | volver a `web-diseno-y-frontend.md` + `design-taste-frontend`; rehacer, no retocar |
| «publícalo», «súbelo» | deploy + verificar en la URL real + commit |
| «sin gastar», «barato» | nada de productos cloud de pago; todo local |

## 13. Antes de cerrar cada tarea
1. ¿Está verificado en vivo (o dicho claramente que no)?
2. ¿Se apagó lo local (Docker, servidores) y se borraron cachés de build?
3. ¿Se guardó el estado (`ESTADO.md`) y, si aplica, el patrón en el `cerebro`?
4. ¿El mensaje final está en español y contesta cada pregunta del usuario?
5. ¿Quedó alguna identidad personal, clave o token en un commit o archivo público? Revisar.
