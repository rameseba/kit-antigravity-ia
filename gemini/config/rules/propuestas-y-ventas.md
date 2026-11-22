---
trigger: model_decision
description: Leer cuando haya que cotizar, armar una propuesta o maqueta para un cliente, redactar textos comerciales, definir paquetes o entregar una web en el hosting del cliente.
---

# Propuestas, cotizaciones y ventas

## Cotizar = propuesta visual, nunca solo texto
Cuando un lead pide precio («coti»), no se responde con un mensaje de precios. Se arma una
**propuesta visual** publicada en `propuesta-<rubro>.<tu-dominio.com>` (clonando la propuesta anterior
más parecida) con:
1. Maqueta «así se vería tu web» con los colores del logo del cliente.
2. **Versión A** (clásica) y **versión B «wow»** completamente distinta, en la PRIMERA entrega (no
   dejarla para después ni preguntar). A veces una C.
3. La B se basa en un **estudio de mercado**: ~20 sitios nacionales + 10 mundiales del rubro (qué
   aciertan, qué fallan, estilo, SEO/AEO/GEO, técnica), publicado como `/estudio/` en la propuesta.
4. Ambas maquetas en vivo (`/maqueta-a/`, `/maqueta-b/`): los efectos de scroll no se ven en captura.
5. Tres opciones de precio. Escalera típica de referencia: una página → web completa con panel
   editable (recomendada) → versión B wow. Publicidad siempre aparte.
6. Recién ahí, UN mensaje de WhatsApp con el link.
Método y scripts: skill `propuesta-visual` y `cerebro/reference/estudio-mercado-propuestas.md`.

## Maquetas ricas
- Cada sección con foto y algo de vida: cotizador sobre foto, el mensaje de WhatsApp mostrado en un
  computador, menús con foto, galería, pasos con foto, contacto con imagen de fondo.
- Fotos: **reales** (Pexels u otras con licencia) como muestra, y decir que son de ejemplo. Nada de
  personas generadas por IA en héroes. Persona recortada (rembg) para franjas con cifras.
- Celulares con barra de estado (hora/señal/batería) y la web bajo la isla.
- Revisar TODAS las capturas antes de publicar (las imágenes lazy salen en blanco).

## Lo que NO se dice ni se muestra
- Nunca «tu sitio parte de X» ni capturas de la web/panel de otro cliente como base: suena a
  plantilla. El clon es interno; la maqueta y el panel van con la marca del cliente.
  (Mostrar otros trabajos como *ejemplos de trabajo hecho* sí está bien.)
- Nunca ofrecer «lo hacemos por llamada/videollamada». Pasos por escrito, capturas o video corto.
- En el sitio propio de la marca, no decir que se desarrolla con IA. La IA se ofrece como SERVICIO
  (automatizaciones, chatbots). Hacer contenido SOBRE IA (videos, reels) sí está bien.

## Paquetes
- El paquete «web pyme» = web + panel editable (/admin) + SEO, AEO y GEO reforzado.
- **Google Ads / Meta Ads nunca dentro de un paquete web**: siempre como opción separada, por
  plataforma (gestión inicial + mensualidad opcional).
- Hosting y correo como mensualidad aparte (reenvío a Gmail vs responder como contacto@dominio).

## Entrega en hosting del cliente sin pagar → interruptor remoto
Si la web se sube al hosting/dominio del CLIENTE (cPanel, etc.) y aún no está pagada, **preguntar si
ponemos el interruptor**: el JS del sitio consulta `https://<cliente>.<tu-dominio.com>/estado.json`
(Worker propio, CORS `*`, `no-store`). Con `"activo": false` muestra «Sitio temporalmente no
disponible» (mensaje neutro). Si nuestro servidor no responde, la web sigue funcionando. Subirlo antes
de que el cliente cambie la clave FTP.

## Crédito en cada sitio
En el footer de todo sitio entregado: pastilla destacada «Diseño y desarrollo web · <TU_MARCA>»
enlazada a `https://<tu-dominio.com>` (`target="_blank" rel="noopener"`), adaptada a la paleta del
cliente, separada del copyright. Es el canal de captación: cada sitio es una vitrina. Revisar que el
dominio esté bien escrito.

## Decisiones de plata del cliente
Presupuestos, pujas, horarios de anuncios: proponer opciones A/B/C con datos simples, redactar el
mensaje para el cliente y esperar su respuesta. No decirle «ya lo estoy ajustando» antes de que conteste.

## Skills útiles
`estratega-propuestas`, `estratega-ofertas`, `analista-precios`, `director-financiero`,
`deal-value-calc`, `sales-objection-handling`, `negotiation-concession-planner`,
`sales-discovery-questions`, `copywriting`, `cro`, `landing-page-conversion-audit`.
