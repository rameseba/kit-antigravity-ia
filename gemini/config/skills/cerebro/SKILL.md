---
name: cerebro
description: Base de conocimiento probada en proyectos reales (sitios Astro + Cloudflare Workers, tiendas Next.js + Convex/Supabase en Vercel, pagos Webpay/Mercado Pago/Flow, paneles de cliente, SEO local, Google/Meta Ads, reels, WhatsApp con IA, catálogo de agentes de negocio). Usar antes de empezar un sitio o tienda, al tocar pagos, caché, auth, bots, anuncios o videos, al cotizar, o cuando un problema "ya pasó antes". También para guardar patrones nuevos que sirvan en más de un proyecto.
---

# Cerebro — conocimiento transversal

Leer **solo el archivo del tema** (no todos). Los archivos citan proyectos reales como ejemplo; los
nombres de clientes son solo referencia del caso.

## Índice (en `reference/`)
| Tema | Archivo |
|---|---|
| Reglas de diseño web, formularios, CSS/JS, URLs de prueba, capturas | `reglas-web.md` |
| Tocar config sin romper nada y cómo avisar daños | `metodo-config-y-avisos.md` |
| Sitios Astro + Cloudflare Worker (patrones, deploy, panel, SEO, precios) | `sitios-astro-worker-patrones.md` |
| Sistema de diseño aprobado para maquetas/propuestas | `guia-diseno-aprobada.md` |
| Estudio de mercado para la versión B de una propuesta | `estudio-mercado-propuestas.md` |
| Tienda nueva: checklist base | `tiendas-checklist-base-pasapalos.md` |
| Tiendas con Convex (patrones, bugs) | `tiendas-patrones-convex.md`, `tiendas-patrones-desde-2026-08-24.md` |
| Vercel: caché, ISR, auth | `tiendas-vercel-cache-auth.md` |
| Pagos (Webpay / Mercado Pago / Flow) | `tiendas-pagos-akim.md` |
| Bots y crawlers (bloquear basura, permitir IA) | `tiendas-politica-bots.md` |
| Auditoría completa de una tienda (ejemplo) | `tiendas-auditoria-pyt-2026-08.md` |
| Ofertas de tiendas en 2 niveles | `ofertas-tiendas-2-niveles.md` |
| Meta Ads, reels y videos | `marketing-meta-y-reels.md` |
| Asistente de WhatsApp con IA (API oficial) | `whatsapp-asistente-ia-oficial.md` |
| Herramientas externas y locales (Windows) | `herramientas-externas.md`, `herramientas-locales-windows.md` |
| Catálogo de agentes de negocio (precios, ofertas, CFO…) | `agency-agents-catalogo.md`, `agency-catalogo-completo.md` |
| Venezuela: POS real (tasas BCV, IGTF, medios de pago, comprobante, contador) | `venezuela-pos-spec.md`, `venezuela-country-ve.ts` (regla resumida: `~/.gemini/config/rules/venezuela.md`) |
| Patrones transversales (errores repetidos en todos los proyectos) | `patrones/TRANSVERSALES.md` |
| Paneles de cliente | `patrones/PANELES-DE-CLIENTE.md` |
| Sitios locales + Google Ads + Perfil de Google | `patrones/SITIOS-LOCALES-ADS-GBP.md` |
| Tiendas Convex + Next | `patrones/TIENDAS-CONVEX-NEXT.md` |

Rutas como `Documents/<proyecto>` o `D:\...` dentro de los archivos son de la máquina original: tomarlas
como ejemplo de estructura, no como rutas existentes.

## Cómo escribir en el cerebro (sin que lo pidan)
Escribir en el mismo turno cuando pase cualquiera de estos:
(a) repo nuevo o clon de otro; (b) sitio publicado en su dominio o subdominio; (c) bug/patrón que
sirve en más de un proyecto; (d) cambio de precio, paquete o política comercial; (e) decisión del
usuario que vale para todos los proyectos.
NO van al cerebro: leads, cotizaciones, estado de sesión, datos personales (eso va a `ESTADO.md` /
memoria del proyecto).

Cada escritura:
1. Agregar al archivo temático en `reference/` con fecha, repo y commit; actualizar su línea
   «Actualizado:».
2. Una línea en `reference/REGISTRO.md` (fecha · archivo · qué). Crearlo si no existe.
3. Si es un tema nuevo, agregar fila a la tabla de arriba.
4. Un dato sin fuente se escribe «POR CONFIRMAR».
5. Nunca claves, tokens, correos personales ni usuarios personales de servicios.
6. Recomendado: que esta carpeta sea un repo git PRIVADO y hacer commit + push tras cada cambio.
