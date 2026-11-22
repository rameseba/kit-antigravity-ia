---
name: nueva-web
description: Crea una web nueva de principio a fin partiendo de las plantillas del kit (sitio de servicios/pyme o landing), la personaliza con marca, fotos y datos, crea el repo en GitHub, la publica en Cloudflare y la verifica en vivo. Usar cuando el usuario pida "hazme una web", "una página para...", "un sitio para mi negocio/cliente", "una landing", o quiera empezar un proyecto web desde cero.
---

# Web nueva de punta a punta (en una tarde)

Plantillas en `~/kit-antigravity-ia/plantillas/`:
| Plantilla | Para qué |
|---|---|
| `sitio-pyme` | Negocio de servicios o comercio: portada con foto, servicios, galería, precios Ref. $ + Bs. (tasa BCV automática), testimonios, FAQ, contacto (formulario a WhatsApp con +58, estado/municipio), botón WhatsApp, crédito en el pie. HTML/CSS/JS sin instalar nada. |
| `propuesta` | Página para cotizar o mostrar una muestra a un cliente (ver skill `propuesta-visual`). |

Si el proyecto necesita panel de administración, tienda con carrito o base de datos, usar Astro o
Next.js (skills `frameworks-on-cloudflare`, `nextjs-on-cloudflare`, `cerebro`), pero empezar con la
plantilla si alcanza: menos es más rápido y más barato.

## Flujo
1. **Entender (máx. 1 ronda de preguntas):** rubro, ciudad, servicios/productos, WhatsApp, Instagram,
   logo/colores, si cobra en $ y/o Bs, horario, zonas de delivery. Lo que falte: supuestos razonables
   marcados «[CONFIRMAR]» en el texto.
2. **Mini-investigación (15 min, skill `investigar`):** 5–10 sitios del mismo rubro (país + mundo):
   qué secciones tienen, qué fotos, qué promesa. Anotar 3 ideas a copiar y 3 errores a evitar.
3. **Copiar la plantilla** a una carpeta nueva:
   ```powershell
   $n = "peluqueria-maipu"   # nombre del proyecto
   Copy-Item "$HOME\kit-antigravity-ia\plantillas\sitio-pyme" "$HOME\Documents\$n" -Recurse
   cd "$HOME\Documents\$n"
   ```
4. **Personalizar** (todo está marcado con `{{...}}` o comentarios `EDITAR` en `public/index.html`,
   `public/app.js` y `wrangler.jsonc`): nombre, textos reales del negocio (no relleno), colores del logo
   en las variables CSS de `:root`, WhatsApp, servicios, precios, preguntas frecuentes.
   Buscar que no quede ningún `{{`: `Select-String -Path public\* -Pattern '\{\{'`.
5. **Fotos:** reales del negocio si las hay; si no, bancos gratuitos o Flow (skill
   `creativos-imagenes`). Comprimir a WebP/AVIF, máx. ~200 KB cada una. Nada de personas generadas por
   IA en la portada.
6. **Diseño:** pasar la regla `web-diseno-y-frontend.md` y la skill `design-taste-frontend`; móvil con
   tarjetas 2x2; tema claro; nada de «cara de IA».
7. **Revisar local:** abrir `public/index.html` en el navegador integrado (o `npx wrangler dev`) en
   375 px y en escritorio. Probar el formulario → debe abrir WhatsApp con el mensaje armado.
8. **Repo:** skill `conectar-github` → `gh repo create $n --private --source . --push`.
9. **Publicar:** skill `publicar-cloudflare` → `npx wrangler deploy`.
10. **Verificar en vivo** (URL real, móvil y escritorio, formulario, WhatsApp, tasa BCV cargada).
11. **Cerrar:** URL en `ESTADO.md`, commit final, y el mensaje para el cliente (si es para un
    cliente) en formato WhatsApp dentro de un bloque de código.

## Checklist antes de entregar
- [ ] Sin `{{` ni textos de relleno («Lorem», «Tu negocio aquí»).
- [ ] Título y descripción para Google (`<title>`, `meta description`), favicon, imagen para compartir
      (`og:image`).
- [ ] Teléfono y WhatsApp correctos y probados.
- [ ] Precios con «Ref. $» y Bs. a tasa BCV (si aplica) y aviso de precios referenciales.
- [ ] Imágenes livianas, carga rápida en datos móviles.
- [ ] Crédito en el pie con la marca del creador.
- [ ] Publicada y verificada en la URL real.
