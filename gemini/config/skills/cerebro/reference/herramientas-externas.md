# Herramientas externas evaluadas (repos / MCP / CLI)
> **Qué es:** herramientas y servicios externos que se usan (y cuáles no) con sus límites.
> **Actualizado:** 2026-10-11


Archivo vivo. Cada entrada: qué es, para qué nos sirve, cómo usarlo sin gastar de más, riesgos.
No instalar nada permanente sin pedirlo: cada MCP nuevo suma tokens en todas las sesiones.

---

## ⭐ REA — Reverse Engineer Anything (`morluto/rea`) — INTERESA (2026-10-09)
- Repo: https://github.com/morluto/rea · web https://rea.tools · npm `rea-agents` · MIT · TypeScript · ~46k ⭐ (oct-2026).
- Qué es: un MCP + CLI para que el agente **entienda cómo funciona algo sin tener su código**: webs (estructura, scripts, red, capturas), apps JS/Electron (módulos, rutas, IPC, source maps), binarios nativos (con Hopper/Ghidra/IDA), .NET, capturas HAR, bytecode EVM.
- Para qué nos sirve (agencia web Chile):
  - Ver cómo resolvió un competidor o un SaaS una función (reservas, carrito, cotizador, widget de chat, buscador) y **construir la nuestra** para un cliente.
  - Auditar lo que carga la web vieja de un cliente antes de un rediseño (scripts de terceros, llamadas de red, trackers).
  - Revisar el bundle de nuestras propias tiendas (qué se filtra al navegador, rutas expuestas).
- Requisitos: Node 22.19+/24.11+/26+ y npm. Para webs: un Chrome. Para binarios: Hopper/Ghidra/IDA (no hace falta para web/JS).
- Uso barato (recomendado, sin instalar MCP):
  ```bash
  npx -y rea-agents@latest analyze-javascript-application "D:/ruta/app" --json
  npx -y rea-agents@latest --help
  ```
  Instalación completa (agrega MCP + skill a Claude Code; **pedir OK al usuario**, sube tokens): `npx rea-agents setup` (muestra cambios y hace respaldo de la config). Actualizar: `npx rea-agents@latest setup`.
- Reglas: entender ≠ copiar. No copiar código, textos ni diseño de terceros (derechos de autor); reimplementar a nuestra manera. No usarlo contra sitios para saltar pagos, logins o protecciones. Analizar en local.

## trycua/cua — NO por ahora (2026-10-09)
- https://github.com/trycua/cua · MIT (app Spaces FSL-1.1-MIT) · Rust/Swift · ~29k ⭐.
- Computer-use: Cua Driver (controla apps de escritorio Win/mac/Linux en segundo plano, vía CLI/MCP/SDK), Cua Spaces (escritorios virtuales, **solo macOS 26**), sandboxes, Lume (VMs Apple Silicon), Cua Bench.
- Posible uso futuro: automatizar subidas a redes sin que Chrome se congele en segundo plano / diálogos nativos de archivos. Hoy ya tenemos Claude in Chrome + computer-use; instala cuenta en cua.ai y relay → no compensa.

## Anuncios (Meta/Google) — evaluados 2026-10-10, NO instalados
- **AgriciDaniel/claude-ads** ★9,9k MIT — skill Claude Code `/ads` (setup, audit, plan, create, launch --draft, monitor, optimize --draft, report) para 12 plataformas; solo lectura por defecto. **Candidata #1** para auditar campañas (la del amigo, clientes).
- **coreyhaines31/marketingskills** ★54k MIT — skills sueltas: ads, ad-creative, copywriting, offers, marketing-psychology, cro… tomar solo las necesarias.
- **pipeboard-co/meta-ads-mcp** ★1,3k — MCP para leer/crear en Ads Manager por API (alternativa a Chrome).
- mathiaschu/meta-ads-analyzer ★441 (fase de aprendizaje, desgloses) · proxy-intell/facebook-ads-library-mcp ★311 (Biblioteca de anuncios) · anthropics/skills ★180k y vercel-labs/agent-skills ★32k (generales, nada de ads).
- Gratis sin instalar: Biblioteca de anuncios de Meta facebook.com/ads/library (filtrar Chile) para ver competencia y antigüedad de sus anuncios.
