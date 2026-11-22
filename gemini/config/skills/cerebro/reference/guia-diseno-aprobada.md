# Guía de diseño APROBADA — «no parece IA» (2026-10-25)
> **Qué es:** referencia de diseño que el usuario aprobó («no parece IA»): leer antes de diseñar un sitio.
> **Actualizado:** 2026-10-28


Origen: `Documents/Universidad-abierta-internacional` (uabiertai.rameseba.com), commits 8fe3e3c → 38c2494.
El usuario: «quedó espectacular… súper bien, no parece IA, guárdalo como guía de estilos».
Usar como referencia por defecto para sitios institucionales y de servicio (universidades, clínicas,
empresas). Complementa la regla global «NADA de diseño cara de IA» (CLAUDE.md) y el skill
`design-taste-frontend`. Lo que hizo funcionar el diseño fue **copiar la estructura de sitios reales del
rubro** (el sitio actual del cliente + uno de la competencia), no inventar.

## 1. Método (lo que el usuario premió)
1. Antes de diseñar: ver el sitio actual del cliente y 1-2 referentes reales del rubro (aquí uabiertai.com
   y unincol.edu.co). **Tomar piezas concretas de cada uno** y decir cuáles (el usuario reclamó: «no sacaste
   nada de la otra universidad»).
2. Contenido, logo y colores salen del cliente. Nada de datos inventados.
3. Fotos propias generadas con el logo en el uniforme (ver §4), nunca bancos genéricos ni copiar las del cliente tal cual.
4. Revisar con capturas a 1440 px y a 375 px antes de entregar, y con el QA automático (§6).

## 2. Paleta y tipografía
- **Solo los colores del logo** (aquí azules + blanco). Nada de dorado/acentos ajenos si el logo no los tiene.
  Tokens: `--brand` (color del logo #0b2f8a), `--brand-2` (azul más claro para botones/enlaces #1f63c9),
  `--brand-deep` (fondos oscuros #071d5c), `--sky` (franjas celestes #e1eefb), `--brand-soft` (cajas #e6eefb),
  `--ink` azul noche (no gris carbón). Excepción: colores que el propio cliente ya usa (aquí tarjetas de áreas
  rosado/lila/celeste de su web).
- Una tipografía (Plus Jakarta Sans variable). Títulos `h2` 1,8–2,55 rem en `--brand-deep`, con una palabra
  resaltada en `--brand-2` vía `<em>` («Brigada de <em>Salud y Emergencia</em>»).
- **Antetítulo = texto espaciado sin recuadro** (12 px, letter-spacing .24em, mayúsculas, `--brand-2`).
  **PROHIBIDO** la píldora/recuadro con ícono (el usuario: «no repitas nunca ese tipo de recuadros»).
- Botones píldora; sobre fondo oscuro, botón blanco con texto azul. Verde WhatsApp **#15803d** (el #1fa855
  no pasa contraste con texto blanco).

## 3. Estructura y componentes (compacto, «con vida»)
- Densidad: `.section` padding clamp(44px, 5.5vw, 76px); el usuario rechazó «muy cargado, mucho espacio en
  blanco, cuadros de texto vacíos». Cada sección lleva imagen o algo visual, no solo cajas de texto.
- Barra superior del color del logo (teléfono, correo, «Verificar», crédito rameseba). Encabezado blanco con
  el logo horizontal grande (~178 px).
- **Portada**: carrusel de fotos de borde a borde (texto a la izquierda sobre degradado azul, botones en barra
  inferior) → **mosaicos de acceso montados sobre el borde del banner** (unincol, 4 en fila, borde superior de
  color) → **franja celeste con persona recortada** (unincol) → misión/visión/docentes (uabiertai) → áreas →
  banda de foto → secciones → noticias → FAQ → **contacto en banda azul sobre foto del edificio con formulario
  blanco** (uabiertai).
- **Páginas internas**: SIEMPRE abren con banner de foto de borde a borde (`HeroBanda`: migas, antetítulo,
  h1 con resaltado, bajada, botones y tarjeta blanca opcional a la derecha). **Nunca la foto en un cuadro.**
  Luego mezclar: franja celeste con recorte, texto + foto, `BandaImagen` (franja de foto con texto encima),
  tarjetas con foto arriba + borde inferior azul de 4 px + ícono redondo que monta sobre la foto.
- Noticias/actividades estilo unincol: foto arriba con borde azul, fecha con ícono calendario, título, «+».
- Pie claro (`--sky`) con columnas separadas por línea, títulos con ícono, barra inferior más oscura.
- Crédito «Diseñado por rameseba.com» como **botón destacado** (ícono destello): blanco en la barra superior,
  degradado azul en el pie y al final del menú móvil (`.firma` en global.css).
- Tarjetas y listas que parecen clicables DEBEN llevar a algo (perfiles → pestaña de requisitos, pasos →
  sección, ejes → área).
- Móvil: 2×2 en tarjetas, botones ≥ 32 px de alto, letra ≥ 12 px, sin desborde horizontal.

## 4. Fotos (el usuario nota al tiro las borrosas y las «de IA»)
- Google Flow (Nano Banana), proyecto del cliente, **logo subido como referencia** y pedido «embroidered on the
  chest». Prompt base: «Photorealistic, sharp, high detail, 16:9, natural light, real skin texture, 35/50mm lens,
  [escena], subject on the right third, left side softly blurred with space for text, no text, no watermark».
- **Descargar en 2K** (abrir imagen → ícono descargar → «2K resolución mejorada» = 2752×1536; las flechas ← →
  pasan de imagen). La descarga normal es 1376 px y se ve blanda.
- Recortes de personas para franjas: `rembg` con sesión `isnet-general-use`, desde la versión 2K; revisar que no
  queden fantasmas.
- `<Image>` de Astro: banners con `widths={[828,1280,1920,2752]}` y
  `sizes="(max-width: 560px) 300vw, (max-width: 900px) 180vw, 100vw"` — con `100vw` el móvil baja 828 px para un
  recorte `object-fit: cover` que pide ~2000 px y se ve borroso. Misma lógica en fotos horizontales metidas en
  cuadros verticales: calcular ancho = alto × proporción × 2.
- No usar escenas que el cliente no hace (aquí: nada de ceremonias de titulación).

## 5. Contacto editable (patrón reutilizable)
Teléfonos por país + correo en KV (`contacto`), GET público cacheado 60 s, PUT en el panel; el HTML trae los
datos por defecto y un script (`src/scripts/contacto.ts`) reemplaza `[data-c]`, `[data-c-pais]` y todos los
`wa.me/<número por defecto>`. Países ocultos hasta que el admin los activa.

## 6. QA antes de entregar
`Universidad-abierta-internacional/herramientas/qa-visual.js` (`qaVisual(2)`, `qaMovil()`): fotos con pocos
píxeles, contraste < 4,5, anclas rotas, botones chicos, letra chica, desborde. Encontró: título de formulario
blanco sobre blanco (heredaba `color:#fff` de la banda), verde WhatsApp sin contraste, banners móviles borrosos.
Capturas de página completa: `herramientas/captura.py` (Chrome headless con `--run-all-compositor-stages-before-draw`,
sin eso no se disparan las animaciones de entrada). En móvil medir con el panel del navegador a 375 px
(headless no baja de ~500 px).

**Google Flow (2026-10-28):** usar SIEMPRE https://flow.google.com/u/2/ (cuenta con plan Pro). La cuenta propia del usuario venció. Vale para todos los proyectos.
