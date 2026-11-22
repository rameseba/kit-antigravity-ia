---
trigger: model_decision
description: Leer SIEMPRE antes de diseñar o rediseñar una web, maqueta o tienda, hacer un formulario, o tocar CSS/JS de un sitio (diseño sin cara de IA, formularios chilenos, modales, capturas, URLs de prueba).
---

# Reglas web (diseño, formularios, CSS/JS, URLs de prueba)
> **Qué es:** reglas globales para hacer sitios y tiendas, movidas VERBATIM desde el CLAUDE.md global el 2026-11-16. Leer antes de diseñar, hacer un formulario o tocar CSS/JS de un sitio.
> **Actualizado:** 2026-11-21

## Regla global: URLs de prueba de sitios de clientes (2026-09-04)
Nunca entregar URLs `*.<cuenta-personal>.workers.dev` / vercel con el nombre del usuario. Los sitios en
Cloudflare van como subdominio de **<tu-dominio.com>** (con b): `<cliente>.<tu-dominio.com>` vía Custom Domain
del Worker (`routes: [{ pattern, custom_domain: true }]` en wrangler.jsonc). Cuando el cliente compra
su dominio, se conecta ese y el subdominio queda como respaldo. El crédito del pie es "Diseñado por
<tu-dominio.com>" y el botón flotante de WhatsApp no debe tapar ese crédito (pb-24 / sm:pr-72 en el pie).

## Regla global: salto de página al abrir paneles/modales (2026-09-18)
Al bloquear el scroll para abrir un panel lateral o modal, la barra de scroll desaparece y la
página salta de lado. **NO compensar con `padding-right`** (deja una franja blanca).
Fix correcto: `html { scrollbar-gutter: stable; }` en el CSS global (reserva el ancho siempre)
+ bloquear con `document.documentElement.style.overflow = 'hidden'` (en `<html>`, no en `<body>`:
en varios navegadores el contenedor de scroll real es `html`).
Excepción: en React con Radix/`react-remove-scroll` NO usar `scrollbar-gutter` (dobla la
compensación en Windows); ahí el fix es `modal={false}`. Detalle: memoria de arias-wear.
Se repitió en tehtools-cl-generadores por estar guardado solo en la memoria de otro proyecto.

## Regla global: una clase propia que fija `color` le gana a Tailwind (2026-09-18)
Si defines `.mi-titulo { color: #111 }` en el CSS global y ese archivo se carga DESPUÉS de las
utilidades, `text-white` en el HTML **no hace nada**: el título sale negro sobre fondo negro y
nadie lo nota hasta que alguien mide el contraste. Pasó en tehtools con dos títulos invisibles.
**En clases propias de tipografía: tamaño, peso e interletrado sí; `color` no** (usar
`color: inherit` y que lo ponga el contenedor).

## Regla global: nada que viva en localStorage es de fiar (2026-09-18)
Carrito, listas, cupones: el visitante los edita desde la consola en diez segundos. En tehtools
se podía comprar un compresor de $249.990 por $1.000 y el pedido pasaba. **Revalidar siempre
contra el catálogo antes de cobrar**, aunque el checkout todavía sea simulado — y no fiarse de
un comentario en el código que diga que "el servidor ya valida": comprobarlo.

## Regla global: `querySelector` en el script de un componente (2026-09-18)
Funciona hasta el día que hay DOS instancias en la página, y ahí la segunda queda muerta en
silencio (en tehtools, un slideshow entero). En scripts de componente, recorrer siempre con
`querySelectorAll`.

## Regla global: formularios de sitios chilenos (2026-09-22)
Todo formulario público (contacto, cotizar, etc.) valida **en el navegador y otra vez en el servidor**, con las mismas reglas en un solo módulo:
- **Nombre y apellido:** solo letras (tildes y ñ), mínimo dos palabras, **máx. 50**. Números y símbolos se borran al escribir.
- **Empresa:** letras y puntos (S.A., Ltda.), máx. 50.
- **Teléfono:** celular chileno, siempre **`+56 9 1234 5678`**; se ordena solo al salir del campo.
- **Correo:** formato válido, máx. 100. **Comuna:** lista cerrada de las 346 comunas agrupadas por región (o la región entera), nunca texto libre.
- **Mensaje:** máx. **1000** caracteres con contador (cabe en el enlace wa.me; el envío por correo usa el mismo tope). Los desplegables solo aceptan sus opciones.
- Servidor: limpiar caracteres de control y `< >`, exigir Content-Length con tope, Origin/Sec-Fetch-Site, correo en texto plano, topes diarios.
Implementación de referencia: `inmobiliaria-soto-mayor-cl/herramientas/formulario-chile.mjs` + `comunas-chile.mjs`.
**Ojo CSRF:** con `Referrer-Policy: no-referrer`, Chrome manda `Origin: null` en los POST de formulario → aceptar `null` solo si `Sec-Fetch-Site: same-origin` (bloqueó el login del panel de Sotomayor).

## Regla global: NADA de diseño "cara de IA" en sitios web (2026-10-24)
El usuario lo rechaza siempre ("no quiero un diseño IA"); pasó en abogada-migratoria y se repitió en Clima-ven.
**Antes de diseñar cualquier sitio, cargar el skill `design-taste-frontend` y pasar su pre-flight.** Prohibido por defecto:
etiqueta mayúscula con rayita sobre cada título, hero oscuro con degradados/halos/blobs, animaciones infinitas,
chips con checks en el hero, datos inventados ("-18°", "+500 clientes"), bandas de urgencia de plantilla,
tarjetas iguales en fila, íconos SVG dibujados a mano (usar Phosphor), rayas largas (—). Sí: fotos reales del
cliente como protagonistas, un solo acento, una tipografía (Geist u otra no-Inter), un radio, SOLO tema claro (13-11 rechazó el modo oscuro auto: «no quiero la web en modo dark»).
**Prohibido (13-11, P&P Deco): bandas/secciones/pie/modo oscuro de AZUL MARINO o azul oscuro a todo el ancho** («eso es lo IA que no me gusta»). Fondos claros y cálidos; el azul solo en acentos chicos. Nav al CENTRO del header (logo izq., acciones der.). Tienda y ficha: copiar Pasapalos / Bendito Cuadro / web-cueros, no inventar.
**Referencia aprobada («no parece IA», 25-10): `~/.claude/cerebro/guia-diseno-aprobada.md` — leerla antes de diseñar.**


## Regla global: qué delata «hecho con IA» y la referencia buena (2026-11-18)
Dicho por el usuario con el lead Higienespa (cliente que rechazó otra oferta «toda hecha con IA»): lo que más delata IA es
**el logo** (íconos de personitas + destellos), **cómo se ordenan los textos en el héroe** (antetítulo con rayita + h1 de 4 líneas
con palabra en color + chips con íconos debajo), **los íconos** (ícono en cuadradito de color sobre cada tarjeta) y **las fotos
generadas**. «Te lo digo y lo sigues haciendo».
- Fotos: buscar **fotos reales de personas en internet** (Pexels: `firecrawl_scrape` de `pexels.com/search/<q>/` con formato images,
  luego `images.pexels.com/photos/<id>/pexels-photo-<id>.jpeg?w=…`) y usarlas de muestra. Unsplash napi da 401.
  Gratis y sin firecrawl (18-11): abrir pexels.com en el navegador integrado y con `javascript_tool` hacer `fetch('/search/<q>/')` y sacar
  los IDs con `/photos\/(\d+)\/pexels-photo/`; bajar miniaturas `?w=360` y armar hoja de contacto con PIL para elegir.
- Servicios en **lista numerada 01–06 + foto grande que cambia**, no tarjetas iguales con ícono. Íconos solo funcionales (WhatsApp, teléfono, flecha).
- Logo de maqueta: palabra con tipografía + bloque simple, nunca un ícono inventado.
- **Referencia aprobada: interelectricjgm.cl** (`Documents/interelectric-cl`, `src/styles/global.css`): Archivo ancho variable,
  esquinas rectas, nav con logo al centro, portada foto completa con degradado neutro, palabra subrayada, pasos en papel cuadriculado,
  FAQ numerada, contacto sobre foto, barra flotante WhatsApp/Llamar. Aplicado en `propuesta-higienespa/mock/mock.html`.

## Maquetas con celular: barra de estado e isla (2026-11-18)
La web dentro del celular (.cel/.scr del sistema Contengo → Kiwicha y clones) NO puede empezar debajo de la isla dinámica: poner
barra de estado blanca de ~54 px con hora (9:41), señal, wifi y batería (Phosphor) y recién debajo la barra del negocio. Las 27 propuestas
anteriores se corrigieron el 18-11 con `1.<TU_MARCA>-com/scratch/_statusbar-snippet.html` + `_fix-phones.mjs` (sirve para futuras). Ejemplo: `propuesta-sanalfonso/mock/sanalfonso.css` (.sb).

## Capturas de maquetas: fotos lazy salen en blanco (2026-11-18)
Una captura de página completa (Playwright `fullPage`/clip, Edge `--screenshot`) NO carga las `<img loading="lazy">` fuera de la
pantalla: quedan cajas vacías. Pasó en propuesta-eventos y el usuario lo vio publicado («huecos donde deberían ir imágenes»).
Antes de capturar: servir la carpeta por http (no `file://`, los módulos ES no cargan), `img.loading='eager'` + `await img.decode()`,
y forzar las clases de revelado. Revisar CADA captura antes de publicar. Edge headless tiene ancho mínimo ~492 px: para celular usar
Playwright (`playwright-core` de `Documents/interelectric-cl`, `channel:'msedge'`, viewport 390, `isMobile`).
Efectos de scroll (momentos del kit) no se aprecian en capturas: publicar la maqueta en vivo dentro de la propuesta (`/maqueta-a/`),
con CSP que permita scripts inline y Google Fonts solo en esa ruta. Recién publicado, el Worker puede dar 404 unos segundos.

## Campos PIN / clave de un solo uso: `autocomplete="one-time-code"` (2026-11-21, POS 4. Sistema-inventario 1.161)
Chrome IGNORA `autocomplete="off"` cuando ve un par usuario + `type="password"`: rellena el PIN de supervisor con una
clave guardada y el formulario la manda (en el POS el cierre de caja fallaba con «PIN incorrecto» aunque cuadrara).
Todo campo de PIN, código o autorización que no sea el login: `type="password" inputMode="numeric" autoComplete="one-time-code"`.
El login sí lleva `username` / `current-password`.
