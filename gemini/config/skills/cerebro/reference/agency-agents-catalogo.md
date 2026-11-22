# Catálogo agency-agents (The Agency) — cuándo usar cuál
> **Qué es:** catálogo curado de expertos de The Agency para convertir en skills (precios, ofertas, CFO…).
> **Actualizado:** 2026-09-16


Creado 2026-09-16 (sesión rameseba.com). Fuente: github.com/msitarzewski/agency-agents (MIT, ~153K ⭐,
último push 2026-09-12). Llegó por la guía PDF de Xabi (@xabatz) "Tu empresa de IA en 3 pasos".
**No se autocarga.** Leer bajo demanda al empezar auditoría, arreglo de sitio, tienda nueva, página
nueva, cotización o decisión de negocio, y ver si algún experto suma.

## Reglas de uso (decididas 2026-09-16)
- **NO correr `./scripts/install.sh --tool claude-code`**: copia todo a `~/.claude/agents/` como
  sub-agentes → descripción de cada uno en el contexto de TODA sesión + choca con la regla global
  de no lanzar sub-agentes (cuota).
- **Sí:** traer solo el `.md` necesario y convertirlo en **skill** en `~/.claude/skills/<nombre>/SKILL.md`
  (frontmatter en español + cabecera "responde en español, adapta a Chile" + cuerpo original).
  Descargar: `https://raw.githubusercontent.com/msitarzewski/agency-agents/main/<ruta>`.
  Pedir permiso al usuario antes de descargar.
- Están escritos para EE. UU. (GAAP, SOX, sales tax). Adaptar a Chile: SII, IVA 19%, boleta/factura,
  boletas de honorarios, pesos CLP.
- Antes de traer uno, revisar si ya lo cubre algo instalado: `impeccable`/`design-taste-frontend`/
  `redesign-existing-projects` (diseño), `web-perf` (rendimiento), `marketing:seo-audit` y trabajo
  GEO/AEO de rameseba (SEO), `engineering:code-review`/`security-review` (código),
  `design:accessibility-review` (a11y). Solo traer si aporta método que no está.

## Ya instalados como skill (2026-09-16)
| Skill | Origen | Para |
|---|---|---|
| `analista-precios` | `specialized/specialized-pricing-analyst.md` | precios, planes, descuentos (sensibilidad −20%/+20%) |
| `estratega-ofertas` | `sales/sales-offer-lead-gen-strategist.md` | oferta con ecuación de valor, lead magnet + seguimiento |
| `estratega-propuestas` | `sales/sales-proposal-strategist.md` | cotizaciones y propuestas a clientes |
| `director-financiero` | `specialized/chief-financial-officer.md` | caja primero, escenario pesimista, gastos/contrataciones |

## Candidatos por caso de uso (no instalados)

### Auditoría de un sitio / tienda existente
- `testing/testing-reality-checker.md` — exige evidencia antes de dar algo por "listo" (va con la regla de verificar)
- `testing/testing-evidence-collector.md` — QA con capturas como prueba
- `testing/testing-accessibility-auditor.md` — WCAG (ojo: solapa con design:accessibility-review)
- `testing/testing-performance-benchmarker.md` — carga (solapa con web-perf)
- `testing/testing-api-tester.md` — endpoints de checkout/Convex
- `design/design-persona-walkthrough.md` — recorrer el sitio como un cliente tipo (útil para QA recorrido cliente de tiendas)
- `design/design-ui-finish-gate-reviewer.md` — revisión final de UI antes de entregar
- `paid-media/paid-media-auditor.md` / `paid-media-tracking-specialist.md` — cuentas Ads y tracking GA/píxeles
- `support/support-legal-compliance-checker.md` + `specialized/data-privacy-officer.md` — privacidad/cookies/términos (adaptar a ley chilena 19.628 / 21.719)
- `specialized/specialized-codebase-archaeologist.md` — entender un repo heredado

### Arreglar un sitio
- `engineering/engineering-minimal-change-engineer.md` — arreglos quirúrgicos sin reescribir
- `engineering/engineering-payments-billing-engineer.md` — Webpay/MP/Stripe, idempotencia, webhooks (patrones de dinero de la familia)
- `engineering/engineering-identity-access-engineer.md` — login/auth
- `engineering/engineering-incident-response-commander.md` — algo caído en producción
- `engineering/engineering-database-optimizer.md` — consultas lentas

### Tienda nueva
- `engineering/engineering-payments-billing-engineer.md` — flujo de pago desde el día 1
- `marketing/marketing-cross-border-ecommerce.md` — si vende fuera de Chile
- `specialized/retail-customer-returns.md` — política de devoluciones/cambios
- `specialized/customer-service.md` / `support/support-support-responder.md` — respuestas tipo WhatsApp/correo
- `marketing/marketing-email-strategist.md` — carrito abandonado, bienvenida, post-compra
- `paid-media/paid-media-ppc-strategist.md` — campañas Google Ads/Shopping
- `product/product-behavioral-nudge-engine.md` — empujes de conversión (con cuidado, sin dark patterns)

### Página / landing nueva
- `design/design-ux-architect.md` — estructura y flujo
- `design/design-visual-storyteller.md` — narrativa visual del hero
- `design/design-image-prompt-engineer.md` — prompts para imágenes generadas
- `marketing/marketing-content-creator.md` — textos
- `marketing/marketing-aeo-foundations.md`, `marketing-ai-citation-strategist.md`, `marketing-agentic-search-optimizer.md` — GEO/AEO (comparar con lo ya hecho en rameseba antes de traer)
- `marketing/marketing-seo-specialist.md` — SEO clásico
- `engineering/engineering-i18n-engineer.md` — sitios ES/EN/PT

### Negocio rameseba (ventas, clientes, operación)
- `sales/sales-discovery-coach.md` — primera reunión con cliente, preguntas correctas
- `sales/sales-outbound-strategist.md` — prospección
- `specialized/business-strategist.md`, `specialized/specialized-chief-of-staff.md` — priorizar semana/negocio
- `specialized/customer-success-manager.md` — retención/mantención mensual de clientes
- `finance/finance-bookkeeper-controller.md`, `finance-tax-strategist.md` — contabilidad (adaptar SII)
- `marketing/marketing-linkedin-content-creator.md`, `marketing-instagram-curator.md`, `marketing-tiktok-strategist.md` — redes
- `specialized/specialized-strategy-duel-agent.md` — dos posturas opuestas antes de decidir

### Ignorar (no aplican a esta familia de proyectos)
academic, game-development, gis, healthcare, spatial-computing, mercado China (baidu, douyin,
wechat, xiaohongshu, weibo, zhihu, kuaishou, bilibili, feishu, gaussdb), gobierno EE. UU. (fedramp,
uswds, section-508), blockchain, embedded/IoT.


## Catálogo completo
Los 267 agentes por carpeta están en `agency-catalogo-completo.md` (separado el 2026-11-16).
