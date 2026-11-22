---
name: propuesta-visual
description: Arma una propuesta comercial visual publicada (maqueta A, versión B wow con estudio de mercado, 3 precios y mensaje de WhatsApp) cuando un lead pide cotizar una web, tienda o sistema. Usar cuando el usuario diga "coti", "cotízale", "propuesta", "presupuesto" o pegue la conversación de un lead.
---

# Propuesta visual (cotizar = mostrar, no escribir precios)

## Flujo completo (todo en la primera entrega)
1. **Leer al lead:** rubro, ciudad, qué pidió, logo/colores, redes, si ya tiene dominio. Si falta algo
   crítico, preguntar UNA vez; lo demás, supuestos razonables.
2. **Carpeta:** `propuesta-<rubro>/` clonada de la propuesta anterior más parecida (estructura interna,
   jamás mencionada al cliente).
3. **Estudio de mercado** (`/estudio/`): ~20 sitios del rubro en el país + 10 del mundo. Por cada uno:
   qué aciertan, qué fallan, estilo, SEO/AEO/GEO, técnica. Conclusiones → qué haremos distinto.
   Método: `../cerebro/reference/estudio-mercado-propuestas.md`.
4. **Maqueta A (clásica)** con colores del logo: barra superior con datos, encabezado blanco con logo
   y botón píldora, portada de foto a todo el ancho con degradado del color de marca, h1 con palabra
   resaltada, botones (WhatsApp verde), 4 accesos montados sobre el borde, franja con cifras y persona
   recortada, servicios con foto, pasos, FAQ, contacto con formulario, pie en columnas.
   Sistema de referencia: `../cerebro/reference/guia-diseno-aprobada.md`.
5. **Maqueta B (wow)**, completamente distinta, basada en el estudio; usar los «momentos» de la skill
   `design-taste-frontend` (photo-chapters, letters-assemble…). Publicar A y B en vivo:
   `/maqueta-a/`, `/maqueta-b/`.
6. **Página de la propuesta:** problema del cliente → solución → maquetas (capturas + links en vivo)
   → 3 opciones de precio (recomendada al medio o destacada) → plazos → forma de pago → contacto.
   Publicidad (Google/Meta Ads) como opción aparte.
7. **Publicar** en `propuesta-<rubro>.<tu-dominio.com>` y verificar en la URL real.
8. **Revisar CADA captura** (fotos lazy en blanco, celulares sin barra de estado, textos en inglés,
   «cara de IA»).
9. **Mensaje** de WhatsApp en bloque de código, formato WhatsApp, corto, con el link. Sin «Hola» si la
   conversación está en curso.
10. Anotar el lead en `~/.gemini/memoria/leads.md` (estado + fecha de seguimiento).

## Prohibido
- Responder la cotización solo con texto y precios.
- Decir que la web «parte de» otro sitio o mostrar el panel de otro cliente como base.
- Fotos de personas generadas por IA en el héroe; emojis como íconos; azul marino a todo el ancho.
- Ofrecer llamadas o videollamadas.
- Meter la campaña de Ads dentro del paquete web.

## Capturas sin huecos
```js
// antes de la captura de página completa
await page.evaluate(async () => {
  for (const img of document.images) { img.loading = 'eager'; try { await img.decode(); } catch {} }
});
```
Servir por http (no `file://`) y lanzar Chromium con `--force_high_performance_gpu`.
