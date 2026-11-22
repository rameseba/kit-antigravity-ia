# Asistente de WhatsApp con IA (conexión oficial) — patrón para clientes (2026-10-25)
> **Qué es:** asistente IA en WhatsApp con la API oficial: costos, método y límites.
> **Actualizado:** 2026-11-22


Origen: propuesta del bot de víveres (primo del usuario, Venezuela) → https://propuesta-bot.rameseba.com
(proyecto `Documents/propuesta-bot-rameseba/`, memoria del proyecto 1.Rameseba-com: `lead-primo-bot-whatsapp-viveres-2026-10-25.md`).

## Video de referencia
https://youtu.be/exgTjIiDS8A — José Manuel Fernández, «Claude Code + WhatsApp: el CRM con agentes de IA que le vendes a
cualquier negocio» (43 min). Arma con Claude Code un CRM (contactos, calendario de citas, conversaciones, agentes
configurables: nombre, descripción, tono, servicios, horario, modelo IA vía OpenRouter, playground) y lo conecta a WhatsApp.
Ejemplo: clínica de fisioterapia; el agente agenda citas en el calendario desde WhatsApp revisando huecos libres.
- NO usar Evolution API / Baileys (no oficiales): en 2026 Meta banea los números.
- API oficial directa de Meta: tediosa, a veces exige verificar empresa y el número deja de funcionar en la app del celular.
- **Solución: YCloud en modo "coexistencia"**: conexión oficial, el dueño sigue usando WhatsApp Business en su celular
  (vinculación por QR como WhatsApp Web), plan gratis con 2 números por cuenta, sin verificar empresa al inicio.
  Requisitos: número en la app WhatsApp Business, portfolio en business.facebook.com (cuenta Facebook con antigüedad),
  método de pago en Meta. Webhook en YCloud → Developer → Webhook, evento «WhatsApp inbound message receiver», + secreto.
- En local usa Tailscale Funnel para exponer el webhook; desplegado no hace falta.
- El video dice «responder es gratis»: **YA NO** (ver abajo).

## Precios oficiales de Meta (rate card USD vigente 1-oct-2026)
- **Desde 1-oct-2026 Meta cobra los mensajes de servicio** (respuestas, incluso de IA de terceros): 1.000 gratis al mes
  por número; desde el 1.001, tarifa del país. Sin método de pago, Meta deja de entregar tras los 1.000.
- Rest of Latin America (Venezuela, etc.): marketing 0,074 · utility 0,0113 · service 0,0113 USD por mensaje.
- Chile tiene tarifa propia: revisar el CSV/PDF en developers.facebook.com/docs/whatsapp/pricing.
- Gratis: todo dentro de la "free entry point window" (cliente llega desde anuncio clic-a-WhatsApp, hasta 7 días).
- Iniciar conversación (recordatorios, avisos) = plantilla pagada (utility/marketing).
- Diseñar el bot para responder en POCOS mensajes (foto+precio+pregunta en uno) → menos costo.

## Arquitectura que proponemos (más barata que n8n)
YCloud coexistencia → webhook a **Cloudflare Worker** (dentro del plan US$5; topes diarios en código) → LLM barato vía
OpenRouter (~US$2–5/mes) → datos editables por el cliente (Google Sheet o el panel de su web) → respuesta por API de YCloud.
n8n se descartó: obliga a pagar un VPS. La IA NO puede verificar pagos (capturas falsificables): siempre confirma un humano.
Supuesto por implementar: pausar el bot en un chat cuando el dueño quiere atender (palabra clave o panel).

## Precio usado (Venezuela, USDT) como referencia
Instalación 180 USDT (90+90) + 25 USDT/mes; Meta aparte con la tarjeta del cliente. ~16 h de trabajo con Claude.
Mensualidad = IA + servidor 24/7 + vigilancia de cambios de Meta + ajustes + soporte. Mercado VE: desde 49 USD/mes.
En Chile recalcular con la tarifa chilena de Meta y precios de rameseba (web básica $40k, tiendas $120–250k CLP).

## Actualización 2026-11-22 (investigación para el propio Rameseba)
- **Meta Business Agent** (lanzado global 3-jun-2026): agente IA NATIVO de Meta dentro de la app WhatsApp Business (y Messenger/IG). Se entrena con lista de precios/catálogo/web, califica leads y pasa a humano. Inicio gratis en la app (Meta no publica el tope gratis). Pago: Meta One (15-sep-2026) Essential US$14,99 · Advanced 49,99 · Expert 149 · Max 499/mes; por API US$2/millón de tokens (~4–5 ¢/mensaje). Disponibilidad en Chile: POR CONFIRMAR en el celular (en WhatsApp Web 22-11 no aparece; sí aparece «Meta One»). Fuentes: fluxi.co/en/blog/meta-business-agent, sleekflow, about.fb.com.
- **Coexistencia directa con la Cloud API exige ser Tech Provider/Solution Partner** (doc Meta embedded-signup/onboarding-business-app-users) → para un negocio solo, vía proveedor (YCloud gratis 0 % markup; Kapso Free/Pro US$25, 5 % en algunos mensajes; 360dialog €49–119/número; BuilderBot.cloud). Requisitos: app ≥2.24.17, portafolio, cuenta FB con antigüedad. Con coexistencia: listas de difusión quedan solo lectura, mensajes temporales y «ver una vez» se apagan, grupos no se sincronizan, historial 6 meses, 20 msg/s.
- **Tarifa Chile (USD, desde 1-oct-2026)**: marketing 0,0889 · utility 0,02 · auth 0,02 · service 0,02 (1.000 service gratis/mes/número). Chat que llega de anuncio clic-a-WhatsApp: ventana de entrada gratis hasta 7 días si respondes en 24 h.
- Videos vistos (transcripción completa): Andy Cruz «WhatsApp API Oficial de Meta: Guía Completa 2026» (ySbOMgZFb74), AIPaths «Agente de WhatsApp con IA… API Oficial» (ANsWFx_yvfs, template + Claude Code, token permanente de usuario del sistema), Leifer Mendez «conectar WhatsApp a la API sin perder tu número» (S5Yw-aIPBB4, coexistencia por QR vía BuilderBot). Coinciden: nada de Baileys/Evolution; la API oficial también banea si hay spam.
