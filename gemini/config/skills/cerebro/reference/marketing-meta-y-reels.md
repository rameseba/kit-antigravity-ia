# Marketing en Meta (Marketplace, Página, Ads) y reels con voz — patrones
> **Qué es:** Meta Ads, reels y videos: cuentas, método y lo que funcionó.
> **Actualizado:** 2026-11-22


Archivo vivo creado el **2026-10-09** desde el proyecto `Documents/1.Rameseba-com` (rameseba.com,
sesiones del 08 y 09-oct-2026). Aplica a rameseba y a cualquier cliente que quiera vender un
SERVICIO por Facebook/Instagram/TikTok. Detalle de sesión: memorias `marketplace-fb-2026-09-24.md`
y `reels-proceso.md` del proyecto rameseba.

## 1. Marketplace NO admite servicios (no es un tema de palabras)
- Política oficial (facebook.com/policies_center/commerce/services): los servicios solo pueden
  ofrecerse por **catálogo de WhatsApp Business** o **Citas de FB/IG**; *«may not be offered
  through other commerce surfaces»*. Ninguna redacción lo vuelve permitido; las palabras solo
  cambian la probabilidad de detección. La competencia que sigue arriba aún no ha sido revisada.
- Lo que más dispara el rechazo: lenguaje en 1.ª persona de servicio («te hago», «la arreglo»,
  «mantención mensual», «oficina presencial», «escríbeme») + **promocionar** la publicación
  (el boost la manda a revisión de anuncios) + compartirla en **grupos sin relación** (punk,
  odontología…) que generan denuncias. Rameseba: 2 bajadas confirmadas + 2 probables.
- Si se insiste: 1 sola publicación, formato **«Pack …»** (producto), sin primera persona, sin
  grupos y **sin promoción**. Las publicaciones rechazadas **no se pueden editar** (el enlace de
  edición redirige) ni borrar desde el computador (solo desde la app).
- Doc oficial (facebook.com/help/<ID>): Meta **avisa «access at risk»** antes de
  suspender Marketplace; 1.ª vez se puede quitar el aviso (app → Estado del perfil → Marketplace
  → Fix it now). Casos reales: cuando llega el bloqueo suele ser permanente y sin revisión.
- Cuenta sana = profile_status «No restrictions» + Marketplace «full access».

## 2. La vía legal: Página de Facebook + anuncio en Ads Manager
- Las normas de **publicidad** sí permiten servicios. El anuncio puede salir en la ubicación
  Marketplace (la más barata: rameseba sep-2026 US$0,51/conversación en Marketplace vs US$1,53 total).
- Anuncios «Click to WhatsApp» **exigen WhatsApp Business** desde marzo 2024 → sin él, a **Messenger**.
- Ads Manager por defecto metió **cosas malas** que hay que revisar SIEMPRE antes de publicar:
  presupuesto US$6/día (no el pedido), **ubicación Venezuela** (la del perfil), saludo del chat
  y seguimiento en **inglés**, preguntas sugeridas que ofrecen servicios que no se venden,
  **5 «AI creative enhancements»** activados (música, retoques, animación, overlays, cambios de
  texto), **5 textos generados por IA** marcados, **traducción al inglés** activada,
  **multi-advertiser ads** activado (sale junto a la competencia).
- Meta ya no deja excluir Instagram por conjunto (solo exclusiones de cuenta: Audience Network,
  columna derecha). Sin cuenta IG en el anuncio igual puede salir; en rameseba IG se llevó ~3 %.
- Buenas prácticas oficiales (facebook.com/business/help/<ID>): ubicaciones Advantage+,
  público amplio, 1 solo conjunto, objetivo alineado, varias creatividades. Con US$2/día no se
  llega a 50 resultados/semana → «Learning limited» es normal; **no tocar 5-7 días**.
- Página nueva: llenarla ANTES del anuncio (logo, portada con texto ARRIBA porque la foto de
  perfil tapa el centro en la vista previa, ciudad, especialidades, respuesta automática de
  Messenger, 3-6 publicaciones de proyectos reales, una fijada). No invitar amigos (notifica a
  su nombre). Rechazar el botón «Call Now» si el objetivo son mensajes.
- Username de Página nueva: NO está en Accounts Center → solo desde la app.

## 3. Automatizar Facebook con Claude in Chrome (gotchas)
- **Chrome tiene que estar al frente**: en segundo plano Ads Manager/Business Suite se congelan
  (capturas con timeout, la página se recarga y borra lo escrito). Con la pestaña visible va fluido.
- En el composer de publicaciones **no apretar Escape** (cierra la ventana; el borrador se
  conserva). Si la página se traba al escribir, el texto sale solo con tildes/emojis → verificar.
- En Ads Manager, Escape/Tab pueden abrir el menú lateral o un **«Publish draft items?»** → Close.
- Campos contenteditable de Ads Manager: Ctrl+A no siempre selecciona todo; seleccionar con JS
  (`Range.selectNodeContents(el)`) y luego escribir.
- Reels/videos subidos por el `file_upload` de la extensión se quedan en «Posting»; funciona si
  el usuario arrastra el archivo y Claude completa texto y publica.
- Anonimizar nombres/correos de clientes al capturar paneles (cambiar el DOM solo en pantalla,
  recargar después).

## 4. Reels con voz (pipeline reutilizable para cualquier cliente)
- Repo de referencia: `Documents/1.Rameseba-com/scratch/reels/` (`guiones.json`, `voz.py`,
  `reels.html`, `../_reels-render.mjs`).
- Voz: `pip install edge-tts` → voces neuronales gratis; Chile: **es-CL-CatalinaNeural** (la que
  eligió el usuario) / es-CL-LorenzoNeural, rate +8 %. `boundary="WordBoundary"` da el tiempo de
  cada palabra → subtítulos karaoke sincronizados. Reemplazos de subtítulo («cuarenta mil pesos»
  → «$40.000»). Voces Windows SAPI = solo es-ES, robóticas.
- Render: HTML 1080×1920 con `render(t)` determinista → playwright-core + Edge headless captura
  30 fps → ffmpeg con la voz. ~2-3 min por reel de 20 s. Revisar con hoja de miniaturas en los
  cambios de escena.
- Contenido: gancho en 3 s, subtítulos grandes (se ven sin sonido), una idea por reel,
  capturas REALES de proyectos (el usuario rechaza el «look IA»), sin música en el archivo
  (se agrega audio en tendencia desde la app al 10-20 %). 1 cada 2 días, mismo día en IG+TikTok+FB.
- Voces más realistas (ElevenLabs, Higgsfield) = pago y cuenta del usuario.

## 2026-10-10/11 — Cuenta publicitaria: moneda, IVA, ubicación (rameseba; vale para clientes)
- **Moneda/zona horaria** no se editan: Configuración de pago → «Moneda y zona horaria» crea una CUENTA NUEVA y cierra la actual para siempre (facebook.com/business/help/<ID>). Hacerlo cuando no haya campañas activas. Para Chile: CLP + America/Santiago (las cuentas nacen en USD/PST o en la zona del perfil; la de rameseba quedó GMT-4).
- **IVA Chile** (es-la.facebook.com/business/help/<ID>): Meta cobra IVA en cada pago salvo que se agregue un RUT inscrito en IVA. Preguntar al cliente si tiene inicio de actividades.
- **Ubicación**: ya no existe «solo viven en»; siempre «viven o estuvieron recientemente» → llegan contactos de otros países con perfil viejo. Apagar «Llegar a más personas con probabilidad de responder» y revisar Desglose → Región.
- **Idioma de Ads Manager** = idioma de la cuenta de Facebook (Configuración → Idioma y región).
- **Borradores fantasma**: abrir «Editar» en un anuncio activo crea borradores («Unpublished edits»), a veces convirtiéndolo en carrusel con errores de ubicaciones. Para mirar usar «Revisar»; si aparece, «Descartar borrador» (lo publicado no cambia).
- **Creativos**: no mezclar 10 servicios distintos en un mismo anuncio (mismo texto/chat; Meta empuja el más barato). Estáticos que funcionan 2026: formato nativo (notas, chat, publicación), antes/después, nosotros vs ellos, reseñas reales, cifras; poco texto, sin botón dentro de la imagen, 1:1 + 4:5 + 9:16. Generador HTML→JPG: rameseba `scratch/ads/` (render.mjs, playwright msedge).

## 2026-10-11 — Copiar una campaña ganadora + cuenta publicitaria (rameseba, repo 1.Rameseba-com)
- **Estructura que funciona en Chile (fletes MatCris, cuenta 828283230376249, sep-oct 2026):** clic a WhatsApp, objetivo Interacción (presupuesto de campaña 5.000/día → ~$530/conv) o Ventas (conjunto 8.000/día → ~$620/conv), «Maximizar conversaciones» + puja volumen más alto, Advantage+ audiencia sin intereses, radio ~25 km Santiago, destino manual SOLO WhatsApp, ubicaciones manuales sin Audience Network. Anuncio «un solo video o imagen» con 2-6 imágenes + 5 textos + 5 títulos + 3 descripciones (Meta combina). Video vertical = más barato (~$475). Gana la OFERTA: precio ancla «desde $X» + prueba social «+500» + bienvenida que pide datos para cotizar. Calidad visual «bajo la media» no impidió convertir. Casi nada entre 02:00 y 07:00. Más baratos: Marketplace, Reels FB, Búsqueda FB.
- **País de facturación ≠ IVA:** revisar siempre Configuración de pago → Información del negocio. Rameseba tenía país Venezuela → Meta NO cobraba IVA (cobros exactos al umbral). El «FBADS-413-…» es solo el ID de factura. País Chile ⇒ +19% IVA (Ley 21.210), en USD o CLP igual.
- **MACH:** sin comisión internacional, pero dólar con spread ~2,9% (Chócale 2024) → CLP ahorra solo eso.
- **Recuperar IVA** solo si el titular es contribuyente de IVA (RUT propio + casilla «registrado para IVA» → Meta no cobra, se declara con factura de compra/F29 y obliga a cobrar IVA a clientes). Boleta de honorarios NO es contribuyente IVA → no marcar casilla ni usar RUT de un tercero.
- **Cambiar país/moneda/zona** (Información del negocio → Editar) crea cuenta NUEVA y cierra la vieja (cierre hasta 2 días hábiles, «Cancelar cierre» disponible). BUG visto: dio «Se produjo un error» pero igual creó la cuenta nueva con país PANAMÁ y sin dirección; corregir el país pidió OTRA cuenta → repetir sobre la cuenta vacía funcionó. Métodos de pago predeterminados NO pasan a la cuenta nueva; el cliente los agrega. Verificar siempre en el selector de cuentas.
- **Conector oficial Meta Ads** (beta desde 29-04-2026, gratis): claude.ai → Conectores → personalizado → `https://mcp.facebook.com/ads` (OAuth detectado, registro automático, HTTP). Lee métricas/benchmarks/biblioteca y crea campañas que nacen pausadas; no sube imágenes del PC. Lecturas «permitir siempre», escrituras «pedir permiso». Las herramientas aparecen recién en sesión nueva. Al crear cuentas nuevas hay que reconectar marcándolas.
- **claude-ads** (AgriciDaniel, MIT): `claude plugin marketplace add agricidaniel/claude-ads` + `claude plugin install claude-ads@ai-marketing-hub-claude-ads` (skills `claude-ads:*`, solo lectura por defecto).
- **Ads Manager por Chrome:** cuentas ajenas compartidas cargan solo con `...campaigns?act=<id>&nav_entry_point=am_global_scope_selector` (sin eso se queda en «Cargando tu cuenta publicitaria»).

## 2026-10-11 — Video «Top 5» animado con mascota y voz open source (rameseba, aprobado «perfecto»)
Repo: `Documents/1.Rameseba-com/scratch/reels/` (sin commit; carpeta scratch).
- **Formato ganador visto en TikTok** (@iadeguardia, el usuario lo eligió de referencia): gancho de curiosidad que anticipa el #1 («…y ni siquiera es la número uno de esta lista») → cuenta regresiva 5→1, una frase corta por ítem → cierre «GUÁRDALO» + CTA. Estética: fondos negro/crema con trama de puntos, acento lima, tarjetas con borde negro y sombra dura, subtítulos en etiqueta negra que saltan palabra por palabra, transición de puntos que tapa/destapa. TODO debe moverse siempre (zoom lento de cámara, fondo que se desliza, elementos flotando, entradas con rebote); si algo queda quieto, se ve «raro».
- **Mascota propia > persona de banco de fotos** (la licencia Unsplash no permite implicar respaldo; además no es auténtica). En Chile el personaje publicitario más recordado es Spike, el quiltro de Lipigas → mascota «Tito», quiltro con pañoleta lima y la R, en SVG animado: parpadeo, orejas, cabeza, boca según la amplitud de la voz (RMS por cuadro a 30 fps), pata saluda/señala/pulgar.
- **Voz open source más humana**: Qwen3-TTS (Apache 2.0) en GPU local (RTX 4060 8 GB, venv aparte con torch cu128, `attn_implementation="sdpa"` en Windows). VoiceDesign crea la voz desde una descripción pero cambia entre frases → generar 1 muestra, elegirla y CLONARLA con el modelo Base 1.7B (`create_voice_clone_prompt`). Subtítulos: texto del guion + tiempos de faster-whisper repartidos por caracteres (Whisper solo oye mal palabras). Fish Audio = no comercial; Chatterbox (MIT) alternativa para clonar la voz del dueño con 5 s.
- **Capturas de webs para el celular**: Playwright móvil 390 px, ocultar overflow-x, scrollbar y elementos fixed (globos de chat), recortar a 390; para animaciones reales (logo girando) grabar con `recordVideo` y usar `<video>` buscando el cuadro exacto en cada render (render async esperando `seeked`). No pasar el scroll muy rápido: 1 s quieto en la portada y bajar ~1 pantalla.
- Herramientas útiles: `yt-dlp --impersonate chrome` (pip `yt-dlp[default,curl-cffi]`) para bajar un TikTok de referencia; faster-whisper falla con `av` nuevo → pasarle el audio como numpy; rembg con `birefnet-general-lite` recorta mucho mejor que isnet (isnet borró un gato gris sobre fondo gris).
- La Biblioteca de anuncios de Meta ordena por impresiones (los primeros = los más vistos). Instagram en Chile: flyers con precio dominan; innovaweb26 «desde $40.000 pago único» seguía recibiendo «info» 24 semanas después.

## 2026-10-12 — Ads Manager con Claude in Chrome: trucos verificados (rameseba)
- **Subir imágenes/videos sin el diálogo de Windows**: FB crea el `<input type=file>` al pulsar «Subir» y abre el selector nativo (que bloquea). Antes, parchear por JS: `HTMLInputElement.prototype.click = function(){ if(this.type==='file'){ this.setAttribute('data-up','cap'); if(!this.isConnected){this.style.display='none';document.body.appendChild(this)} return } … }`, pulsar «Subir», `find` el input y `file_upload` (máx 10 MB por llamada → videos de anuncio en 720p ~1,25 Mbps con h264_nvenc).
- En el paso «Ajustar» se puede **reemplazar la imagen por formato** (Cuadrado 1:1 / Vertical 9:16 / Horizontal) con versiones propias en vez del recorte de Meta.
- **Defaults peligrosos vistos (oct-2026)**: presupuesto sugerido 14.800 CLP/día; lugar «Chile» entero; «Llegar a más personas con probabilidades de responder» marcado (expansión de ubicación); «Agregar música» IA encendida; plantilla de Conversaciones = FORMULARIO de nombre+correo (cambiar a bienvenida propia); ubicaciones incluyen «Apps y sitios web» (Audience Network).
- **No usar Escape** en el editor de anuncios: abre «¿Publicar borradores?» (cerrar con X). Para publicar Meta exige **teléfono verificado en la cuenta publicitaria (#3858013)** → lo hace el dueño por SMS.
- Con Chrome en segundo plano FB no repinta: capturas congeladas, clics por coordenadas fallan, `.click()` por JS a veces no dispara → usar `find`+ref, leer con JS, o pedir Chrome al frente.

## 2026-10-16 · rameseba · campaña Interacción→mensajes con 2.000 CLP/día
- Desglose por ubicación manda: Facebook feed $540/conv vs Instagram feed $1.765 con 0 conv. Mirar `breakdowns: publisher_platform, platform_position` antes de tocar presupuesto.
- Con presupuestos de ~US$2/día la campaña nunca sale de aprendizaje: variaciones de ±20 % en costo por conversación son ruido. Medir costo por cotización/cliente, no por conversación.
- Precios en anuncios/novedades: SIEMPRE leer /precios/ del sitio, no la memoria (se publicó una novedad GBP con precio viejo $250.000 vs vigente $199.990).
- 2026-10-17 · rameseba: cambiar ubicaciones de un conjunto revalida TODOS sus anuncios. Si el creativo usa cuenta IG «Page-backed» (sin Instagram real vinculado), queda WITH_ISSUES: «The Instagram actor must be an Instagram account that is currently linked to the Page». Fix rápido: conjunto solo Facebook. Tras cualquier cambio de ubicaciones, correr ads_get_errors al rato.
- 2026-10-17 · rameseba: anuncios armados/duplicados en la UI y publicados con MCP ads_activate_entity → error «Creative should not include standard enhancements» (campo deprecado); publicar desde Ads Manager «Revisar y publicar» sí funciona. Esta cuenta solo deja 1 imagen/video por anuncio → varios anuncios de 1 flyer en el mismo conjunto. Duplicar con MCP ads_create_ad + source_ad_id copia plantilla de chat y mejoras; luego cambiar imagen en UI.

## 2026-11-06 — Video PRO «tienda para mascotas» en vista de COMPUTADOR (rameseba, scratch/reels/tienda-pro)
- Lo que pidió el usuario (06-11): reels de producto **en vista de computador** (el de celular «se ve mal»), web y panel
  reales (no maqueta), fotos de producto que parezcan reales, video «profesional, que llame la atención».
- Pipeline nuevo reutilizable (`1.Rameseba-com/scratch/reels/tienda-pro/`): `rec.mjs` graba tomas con Playwright+Edge
  (1440×900, DPR 1.5, screencast CDP), puntero dibujado, y **registra destinos del puntero y clics** en info.json;
  `build.py` arma una **cámara con resorte que sigue al puntero** (zoom 1.45–1.8 para que se lea en el teléfono) y pone
  sonido de clic donde hubo clic; `tpl.html` = ventana de computador 1020 px en vertical, título por escena, cortina lima,
  oferta y cierre. Render `_pyp-render.mjs` (8 workers, 1655 cuadros en 35 s) + ffmpeg nvenc. Redes: -b:v 1150k (<10 MB).
- Login de admin para grabar: pedir token a Supabase local y poner cookie `sb-127-auth-token` = `base64-`+base64url(sesión).
- Fotos de producto en Flow: 1 prompt por producto, «Professional e-commerce product photo… seamless warm off-white studio
  background… No brand names, no logos, no readable text» → salen muy reales. Bajar todas: recorrer el contenedor con scroll
  juntando `img.src` (orden = más nuevo arriba, grupos de 4) y descargar con fetch→blob→<a download>.
- **VOCES: el usuario rechazó TODAS** — su voz clonada, y 4 voces Qwen3 VoiceDesign (locutor, creador, mujer, tráiler).
  Quiere calidad tipo **ElevenLabs** o «la voz de lectura en voz alta de la app de Claude» (humana, natural, enérgica, sin
  trabarse). Qwen además se queda pegado generando (default max_new_tokens 2048): limitar tokens. Próximo: probar voces de
  pago/nube (ElevenLabs con cuenta del usuario, OpenAI TTS, Google Chirp 3 HD, Azure HD) y mandarle muestras antes de renderizar.

## Reels con video del usuario (iPhone) + publicación desde el PC — 2026-11-18 (video-claude-barberia)
- **Videos de iPhone vienen en HDR (HLG/Dolby Vision, HEVC 10-bit).** Convertir a SDR sin tonemap deja la cara rojiza/lavada; el usuario lo notó y no quiere filtros ni color cambiado. Hacer el master en HDR: gráficos de Remotion como capa transparente (`--scale=2 --codec=prores --prores-profile=4444 --pixel-format=yuva444p10le --image-format=png`) y componer con ffmpeg sobre los .mov originales: capa `zscale=tin=iec61966-2-1:pin=709:rin=full:t=arib-std-b67:p=2020:npl=203` + `overlay=format=yuv420p10` → hevc_nvenc main10 con tags HLG. `libplacebo inputs=2` sale VERDE (roto en ffmpeg 9). Script: `Documents/YT/video-claude-barberia/remotion/herramientas/componer-hdr.py`. Si hace falta SDR (X): `libplacebo ... tonemapping=bt.2390`.
- **Clips nvenc con B-frames rompen Remotion** («No frame found at position») → `-bf 0 -g 15`.
- **Subir videos grandes desde Chrome (file_upload tope ~10 MB por llamada):** YouTube Studio acepta fetch a un servidor local con CORS (127.0.0.1) + DataTransfer en `input[type=file]`. IG/TikTok/FB/X bloquean 127.0.0.1 por CSP → cortar en partes de 9,5 MB, inyectar un input propio que guarda ArrayBuffer por nombre, un file_upload por parte, armar File y meterlo con DataTransfer. En Meta Business Suite capturar el input con hook de `HTMLInputElement.prototype.click`. En grupos FB puede duplicar adjuntos → revisar «Editar todo».
- **Página FB: tope de 2 publicaciones con enlaces al mes** (si no se paga Meta One): el botón «Publicar» queda gris sin aviso; el hover lo explica. Publicar sin enlaces.
- IG «Compartir en Facebook» va al perfil personal, no a la página. Grupos: leer reglas (OPENCODE prohíbe «mira mi app»; Claude Code en Español exige contenido dentro del post).

## Meta Ads por MCP: trampas vistas el 21–22-11-2026 (rameseba)
- Sin `message_template`, el creativo a WhatsApp sale con saludo en INGLÉS («Hi… Can I learn more…»). Siempre pasar greeting en español (+ prefilled_message o icebreakers, no ambos).
- `placement_customizations` (9:16 por ubicación) NO admite `message_template`: o versión vertical o plantilla de chat. Para Stories/Reels usar videos 9:16.
- Cambiar el `creative` de un anuncio YA creado en borrador (ads_update_entity) lo deja con error 1815589 («título y descripción del enlace obsoletos»): descartar el anuncio y crear uno nuevo.
- Subir medios cuando `ads_create_upload_url` no está habilitado: Ads Manager → anuncio temporal → Configurar contenido → Subir, parchando HTMLInputElement.prototype.click para capturar el input y usar file_upload (videos de a uno, ≤10 MB). Al subir videos Meta marca «publicar en anuncios activos» de otros conjuntos: desmarcar y Cancelar. Descartar el anuncio temporal con discard_draft_changes.
- Si la cuenta publicitaria es de un perfil y no de un portafolio, la Biblioteca multimedia de Business no la muestra.
- `ads_dataset_create` exige aceptar las Condiciones del Píxel en el Administrador de eventos (lo hace el dueño).
- Píxel en sitio con CSP estricta: script propio (`assets/js/pixel.js`) + CSP script-src connect.facebook.net, img-src y connect-src www.facebook.com; evento Contact al tocar wa.me.
- **Medir clientes que vienen de anuncios Click-to-WhatsApp (22-11-2026):** en WhatsApp Web, IndexedDB `model-storage` → store `message`: los mensajes con `ctwaContext` (title, sourceId, sourceUrl) son chats iniciados desde un anuncio; `from` → número vía store `contact` (phoneNumber). Cruzar con quién pagó usando el BUSCADOR de WhatsApp (comprobante/transfer/abono/depósito/recibido): los textos en IndexedDB están cifrados. Rameseba: 175 chats de anuncio → 11 clientes (~$11.500 c/u).
- **Píxel en cuenta sin portafolio:** sí se puede 1 píxel (Administrador de eventos → Conectar datos → Web, ignorar el aviso de portafolio). Lista de clientes (Custom Audience por teléfono) NO: error 1870050, exige portafolio.
