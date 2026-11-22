# Estudio de mercado para propuestas (versión B / C basada en datos)
> **Qué es:** método para que cada propuesta lleve un estudio de 20 sitios chilenos + 10 del mundo del rubro, y que la versión B (y C) se diseñe sobre lo encontrado.
> **Actualizado:** 2026-11-22

## Decisión del usuario (2026-11-19, lead Biocontainer)
La versión B «wow» se hace **en base a estudio de mercado**, y es algo que se va a meter en **todas las propuestas**
(quizás hasta una C). Estudio: ~20 mejores sitios nacionales + 10 mundiales; en qué aciertan, en qué fallan, estilos de
diseño, SEO/AEO/GEO y todo lo demás medible. La idea es destacar el diseño y usar los momentos «wow» del kit.

## Método (probado en `Documents/propuesta-biocontainer`, commit 2635cdb)
1. **Elegir sitios**: `firecrawl_search` con `location: Chile` por rubro (2-3 búsquedas) + conocidos; validar con
   `curl -L` que respondan y sean del rubro (se descartaron: transporte, blog roto, asesoría; Mobile Mini ya redirige
   a WillScot; Conexwest bloquea 403). Mundo: líderes del rubro + uno de diseño de producto (DJI, Sunrun…).
2. **Medir HTML** con `estudio/analiza.py` (Python sin dependencias): título, descripción, H1/H2, palabras,
   JSON-LD (tipos, FAQPage, Product), imágenes sin alt, lazy, WhatsApp, precios, CMS, medición, robots que bloquean IA,
   llms.txt, sitemap, HSTS/CSP, tiempo de respuesta → `datos.json`.
3. **Medir renderizado + capturas** con `estudio/captura.mjs` (Playwright + Edge, correr copiándolo a
   `Documents/interelectric-cl`, que tiene playwright-core): H1 real, fuentes, color del botón, ancho en celular
   (desborde), WhatsApp; capturas 1440 (portada y 2.ª pantalla) y 390 → `render.json` + `cap/`. Sitios con JS o
   anti-bot (WillScot, Anwo, Denios, BigSteelBox) solo se miden así. Reanuda: salta los ya capturados.
4. **Hojas de contacto** `estudio/hojas.py` y **mirarlas** para juzgar diseño (no solo números).
5. **Informe** `estudio/informe.py` → `public/estudio/index.html` (noindex, link desde la propuesta): 8 cifras clave,
   «lo que encontramos» (Chile / mundo / SEO-AEO-GEO / qué tomamos), tabla verde/rojo por sitio con nota
   Acierta/Falla escrita a mano, hojas de capturas. **No escribir segundos en las notas** (cambian entre corridas).
6. En la propuesta: sección «Estudio de mercado» con 3 cifras + enlace, y la B justificada con lo encontrado.

## Hallazgos que se repiten (sirven de argumento de venta en cualquier rubro industrial)
- 0/30 cotización con varios productos; 0/30 schema Product; 3/30 FAQPage; 9/30 llms.txt.
- Chile: 7/20 sin H1, 42 % fotos sin alt, texto metido en banners/afiches, azul marino + rojo + Poppins/Montserrat,
  carruseles y popups, 13/20 WordPress+Elementor, 5/20 se desbordan en celular.
- Mundo: producto protagonista, una acción clara, herramientas para decidir (precio inmediato, configurador),
  sellos de normas, casos por sector.

## Versión B que salió (Biocontainer «Ficha técnica»)
Papel de plano + tinta + un acento naranja de seguridad; IBM Plex Sans Condensed/Plex Sans/Plex Mono; índice de
líneas con foto que cambia; **photo-chapters** «De la fábrica a su faena»; **picture-develops** en la portada;
**configurador** de bodega SUSPEL (tambores + sustancia → módulo, plano SVG en vivo, checklist) que suma a la
cotización; panel lateral de cotización. Momentos del kit: copiar `moments.js`, `lib.js` y la carpeta de cada momento
a `mock-b/assets/moments/` y **definir `--nav`, `--s-6` (y `--bar` en celular)** en `:root`, si no el bloque fijado
queda debajo de la cabecera. Ojo: no usar `data-n` para el nombre del producto si el contador usa `[data-n]`.

## 2026-11-20 · Propuesta psicólogo (propuesta-psicologo, commit 682d963): versión C y redes
- El usuario pidió **3 versiones (A, B, C) completamente distintas y con wow**, estudio 20 Chile + 10 mundo **y redes sociales** (qué contenido funciona), y fotos de internet (no IA todavía).
- Estructura que sirvió: maquetas directo en `public/maqueta-a|b|c/` + `public/maqueta-comun/` (fotos, momentos del kit, `reserva.js`): el CSP de maqueta del Worker cubre todo `/maqueta-*`.
- Cada versión con paleta, tipografía y par de momentos distintos (A picture-develops+word-highlight, B word-rotate+pinned-chapters, C photo-chapters+closing-lift).
- **Los momentos del kit necesitan tokens** en `:root`: `--s-2..--s-7, --r-md, --t-h2, --t-lead, --font-display, --font-text, --display-weight, --display-tracking, --nav, --gutter`; sin ellos el texto sale chico.
- **Una sección con `display:flex;align-items:center;min-height:100svh` rompe pinned-chapters/photo-chapters** (contenido centrado en 1800 px = pantalla en blanco): esas secciones sin esa clase.
- `analiza.py` ahora mide `reserva` y `blog` (la regex de reserva es amplia: «ofrecen agendar», no «reservan en la web»).
- Dominio con ruta (github.io/usuario) funciona en analiza/captura (las capturas quedan en subcarpeta).
- Playwright `fullPage` sobre páginas de más de 16.384 px repite el inicio al final: no es un error de la página.

## 2026-11-20 · Propuesta hamburguesería (propuesta-hamburgueseria, commit 73ca182): carrito → WhatsApp reutilizable
- **Carrito común para cualquier propuesta de comida/local**: `public/maqueta-comun/carta.js` (lista de productos → pinta cada `[data-carta]`, cada maqueta le da su CSS) + `pedido.js`/`pedido.css` (barra «Ver mi pedido», panel lateral, retiro/delivery con envío por comuna, valida nombre y +56 9, vista previa tipo WhatsApp del mensaje y `wa.me/?text=`). Copiar los tres archivos y cambiar ITEMS/ENVIO.
- Carrito en memoria, nunca localStorage (regla web). `[hidden]` no gana a `display:flex`: el CSS lleva `.pd-*[hidden]{display:none!important}`.
- **giant-type-pass**: la opción `image` se resuelve relativa al moment.css, no a la página → usar ruta absoluta (`/maqueta-comun/fotos/x.jpg`).
- **word-rotate** en un h1 centrado: poner la palabra en su propia línea (`<br>` antes y después) o el h1 queda montado; palabras de largo parecido y sin espacios.
- Capturas con palabra que rota: contexto Playwright con `reducedMotion:'reduce'` (la palabra queda quieta).
- `captura.mjs` hay que COPIARLO a `Documents/interelectric-cl` para correrlo (si se corre desde la propuesta, no encuentra playwright-core).
- Hallazgo rubro comida (Chile): 11/20 hamburgueserías venden por Justo o Toteat (plantillas iguales; una con 404), 2/20 con WhatsApp, 0/30 FAQPage, 2/30 schema Menu. Argumento de venta: carta propia + pedido por WhatsApp sin comisión.

## 2026-11-21 · Propuesta aseo ServiMaster360 (propuesta-servimaster, commit 999e550)
- Rubro aseo: **validar que cada dominio sea del rubro mirando la hoja**: 4 «sitios» eran dominios en venta de GoDaddy (cleaning.cl, cleanwhale.com, maidsimple.com) o una tienda (aseoyhogar.cl). Señal en render.json: fuente «gdsherpa/GD Sherpa» = página de venta de GoDaddy.
- Bloquean lectores: mollymaid.com (captcha Cloudflare), thecleaningauthority.com (no abre desde Chile), themaids.com (vacío), maidbrigade.com (444). Sirven: merrymaids, homeaglow, helpling.de, jan-pro, handy, cleanzen, maidpro, housekeep, maidsailors, fantasticservices.
- Hallazgos aseo Chile: 3/20 con precio (solo Appseo con lista), 16/20 WordPress/Elementor/Wix, 5/30 FAQPage, 9/30 llms.txt; La Serena = fucsia, dibujos y fotos de banco. Mundo: precio en línea (Homeaglow, Cleanzen, Maid Sailors) y «qué incluye cada espacio» (Merry Maids). → B «Arma tu limpieza» con precio en vivo.
- Trampas: `.tk::before` absoluto sin `position:relative` en celular desbordaba la página a 450 px (se busca quitando secciones una a una); `img{height:auto}` obligatorio si las img llevan width/height y CSS aspect-ratio, si no salen gigantes.

## 2026-11-21 · Propuesta climatización Arica (propuesta-climatizacion, commit 0b47b61)
- Rubro aire acondicionado: 20 Chile + 10 mundo (Quilt, Aira, Gradient, Sealed, Mitsubishi, Carrier, One Hour, Octopus, Daikin, Lennox). Scripts copiados de biocontainer; NOTA reescrita a mano con `tools/adapta-informe.py` (un heredoc largo de bash se rompió con el hook rtk: escribir los scripts con Write).
- Hallazgos clima: 0/20 con base en regiones del norte; Google para «aire acondicionado Arica» muestra directorios (2x3.cl) y páginas por ciudad de empresas de Santiago → argumento «el primer técnico local con buena web se queda con esas búsquedas». 3/20 sitios rotos (plantilla de limpiafosas en airemax/splitchile, frioclima «en desarrollo»). Fotos de banco casi todos; 3/30 FAQPage; 6/30 llms.txt.
- **Ojo**: 10/20 mencionan «calculadora» en la portada → NO decir «nadie tiene calculadora de BTU»; verificar con grep antes de afirmar «nadie lo tiene».
- B «Sol del norte»: configurador con plano SVG a escala (42 px/m), reutilizable para cualquier lead de clima.
- Usuario 21-11: la A estilo Inter Electric vale $40k–$85k; la B wow es la de $150k. Entregar A + estudio + B de una vez.

## 2026-11-22 · Propuesta IPTV Rancagua (propuesta-iptv, commit f600e73): rubro TV por internet
- Lead revende IPTV: el usuario decidió web **solo informativa**. Reglas usadas: sin carátulas, logos ni nombres de canales/plataformas (tienen dueño), sin precios, **sin ofrecer Ads** (Meta/Google suelen rechazar IPTV). Argumento de venta: personas reales en vez de carátulas = se distingue y es más seguro.
- 20 Chile = 9 IPTV/app (iptv-chile.org, iptvchiledigital.cl, flixnet.vip, chileiptv.store, iptvlatinopro.com, premiumycodigos.cl, iptvchile.net, chiletvapp.com, zapping.com) + 11 telcos/cable (entel, claro, movistar ww2, gtd, wom, tuves, vtr, tvn, directvla.com/cl, directvgo, tvred.cl). Mundo: tv.youtube, peacock y philo (solo EE.UU., muestran «no disponible»), pluto, directv (403 a curl), plex, zattoo, samsungtvplus, waipu, hulu (redirige a Disney+). **magistv.cl y mundo.cl no son del rubro** (casino / eventos).
- Hallazgos: 7/9 IPTV fondo oscuro, 4/9 carátulas ajenas, 1/20 nombra Rancagua, 8/30 FAQPage, 6/30 llms.txt, 8/20 sin H1, claro.cl >20 s y bloquea IA.
- B «Control remoto»: tele con botones de canal (estática CSS + OSD «CH 02»), «Arma tu pantalla» multiselección con foto → WhatsApp. Reutilizable para cualquier servicio de TV/streaming/internet hogar.
- **Trampa**: el `build.js` de propuesta-climatizacion tiene `copiaMaqueta()` que hace `rmSync(public/maqueta-a)` y después lee `mock/`; si el clon ya no tiene `mock/`, BORRA la maqueta y falla. Al clonar, quitar esa función (en propuesta-iptv ya no está).
- Bash (Git Bash) dejó de abrir a mitad de sesión (`bash.exe not found` vía rtk/xargs): seguir en PowerShell.
