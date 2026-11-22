---
name: creativos-imagenes
description: Consigue y prepara imágenes para webs, propuestas, redes y anuncios - bancos de fotos gratuitos (Pexels, Unsplash, Pixabay), generación con Google Flow / Nano Banana, recorte de fondos, compresión y tamaños para redes. Usar cuando haga falta una foto, banner, creativo para Instagram/Facebook/Ads, portada, imagen de producto, o el usuario diga "busca fotos", "genera una imagen", "hazme un creativo", "usa Flow".
---

# Imágenes y creativos

## Orden de preferencia
1. **Fotos reales del negocio/cliente** (Instagram, WhatsApp, Google Maps). Aunque sean de baja
   calidad: sirven en tarjetas chicas.
2. **Bancos gratuitos** con licencia de uso comercial (fotos reales de personas y lugares).
3. **Generadas con IA (Flow / Nano Banana)** para productos, ambientes, fondos, mockups y creativos
   de anuncios. En propuestas, aclarar «fotos de ejemplo».
Nunca: personas generadas por IA como cara principal de una web (delata «hecho con IA»), fotos con
marca de agua, imágenes de Google Imágenes sin licencia.

## Bancos gratuitos
| Banco | Qué tiene | API |
|---|---|---|
| **Pexels** (pexels.com) | Fotos y videos reales, mucha gente latina | Sí, gratis con key: `https://api.pexels.com/v1/search?query=barberia&per_page=15&locale=es-ES` header `Authorization: <KEY>` |
| **Unsplash** (unsplash.com) | Fotos de alta calidad, más «editorial» | Sí, gratis con key (`/search/photos`) |
| **Pixabay** (pixabay.com) | Fotos, ilustraciones, videos, música | Sí, gratis con key |
| **Mixkit / Coverr** | Videos cortos de fondo, música y efectos | No hace falta |
| **unDraw** | Ilustraciones SVG con tu color | No |
| Íconos: **Phosphor**, **Lucide** | SVG consistentes | npm / descarga |
- Las keys van en `.env` (nunca en el código ni en git). El usuario las crea en cada sitio (gratis).
- Buscar en inglés y en español; agregar el país/ciudad si importa («venezuelan street food»).
- Guardar el link de origen de cada foto en `fuentes-imagenes.md` del proyecto.
- Licencias: Pexels/Unsplash/Pixabay permiten uso comercial sin atribución; no vender la foto sola ni
  usar personas reconocibles para avalar algo sensible.

## Generar con Google Flow / Nano Banana
- **Flow** (labs.google/flow, con la cuenta Google del usuario) genera imágenes y videos cortos de
  calidad alta. **Nano Banana** (modelo de imágenes de Gemini) está en la app de Gemini y, si
  Antigravity tiene generación de imágenes, el agente puede usarla directo para bocetos y creativos.
- Abrir Flow en el **navegador del usuario** (ahí tiene su sesión de Google); el agente no inicia
  sesión por él.
- **Subir el logo o una foto real como referencia** (arrastrar al cuadro de creación) para que el
  producto/uniforme/local salga con la marca: ej. «uniforme con el logo bordado en el pecho
  izquierdo».
- Descargar en **2K** desde el visor (ícono de descarga → 2K).
- Estructura de prompt que funciona:
  ```
  Fotografía realista de [qué], [dónde / ambiente], [luz: natural de mañana / cálida de tarde],
  [encuadre: plano medio, 35 mm, profundidad de campo baja], colores de marca [#hex], estilo
  publicitario limpio, sin texto, sin marcas de agua.
  ```
- Generar 4 variantes, elegir 1–2. **Mostrar las opciones al usuario antes de usarlas** en algo
  público (regla: lo visible para el público se aprueba antes).
- Textos (precios, ofertas) **no** dentro de la imagen generada: ponerlos después en HTML/Canva/código
  (la IA escribe mal y no se puede editar).

## Preparar la imagen
- **Quitar fondo** (persona o producto recortado): `rembg i entrada.jpg salida.png` (Python,
  `pip install rembg`; con GPU NVIDIA `onnxruntime-gpu`).
- **Comprimir/convertir** con ImageMagick:
  ```powershell
  magick entrada.jpg -resize 1600x -quality 78 salida.webp
  ```
  Portada ≤ 250 KB, tarjetas ≤ 80 KB. En HTML: `width`/`height` puestos, `loading="lazy"` salvo la
  portada, `fetchpriority="high"` en la portada.

## Tamaños para redes y anuncios
| Uso | Tamaño |
|---|---|
| Post Instagram/Facebook | 1080×1350 (4:5) o 1080×1080 |
| Historia / Reel / TikTok | 1080×1920 (9:16), dejar libres 250 px arriba y abajo |
| Portada web (héroe) | 1920×1080 o 2400×1350 |
| Compartir link (og:image) | 1200×630 |
| Perfil Google (Maps) | 720×720 mínimo |

## Creativos para anuncios (Meta/Google)
- 1 idea por pieza: problema → beneficio → llamada a la acción.
- Producto o persona real en primer plano, fondo limpio, colores de marca, texto corto y grande.
- Hacer **varias versiones distintas** (no 10 iguales con otro color): distinto ángulo, distinta foto,
  distinto mensaje.
- Exportar desde HTML con Playwright (captura de un `div` de 1080×1350) cuando lleve texto: queda
  nítido y editable. Detalle de campañas y reels: `cerebro/reference/marketing-meta-y-reels.md`.
