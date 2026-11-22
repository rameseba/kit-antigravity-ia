---
trigger: model_decision
description: Leer antes de desplegar en Cloudflare/Vercel/Supabase, crear bases de datos o KV, programar escrituras disparadas por visitantes, o correr pruebas de carga.
---

# Costos cloud: presupuesto fijo, sin sorpresas

Cloudflare (y la mayoría de los proveedores) NO tienen tope de gasto automático: lo que pasa, lo cobran.
Regla: **presupuesto mensual fijo para toda la cuenta** (ejemplo real: Workers Paid US$5/mes, ni un dólar más).

## Lo incluido en Workers Paid (para toda la cuenta, al mes)
10M requests, 30M ms de CPU, KV: 10M lecturas y 1M escrituras/borrados/listados, 1 GB KV.
Archivos estáticos gratis. Fuera de eso, NO activar sin preguntar: R2 sobre el plan gratis,
Workers AI pagado, Containers, Queues, D1 sobre lo incluido, Images/Stream, Durable Objects intensivos.

## Reglas
1. Toda escritura que dispare un visitante (formularios, contadores, likes, logs) lleva **tope diario
   en código** (ej. 300/día) y **deduplicación**.
2. Login sin escribir en KV: cookie firmada (HMAC), no sesiones guardadas.
3. **Pruebas masivas SOLO en local** (`wrangler dev` / miniflare / `astro dev`), nunca contra KV/D1
   remoto. Caso real: unas pruebas agotaron el cupo del mes y botaron los paneles de todos los sitios.
4. Antes de un deploy con algo que escale con tráfico: estimar consumo mensual y decirlo.
5. Bots: reglas de caché y bloqueo de bots basura antes de que gasten requests (ver
   `cerebro/reference/tiendas-politica-bots.md`). No activar AI Labyrinth ni Bot Fight Mode a ciegas.
6. Borrar recursos no ahorra en plan gratis; no borrar sin respaldo.

## Recursos de la máquina
- Docker solo cuando hace falta; al terminar `docker compose stop` y cerrar Docker Desktop. Poner tope
  de memoria a WSL en `~\.wslconfig` (ej. `memory=6GB`).
- Al apagar pruebas locales, borrar `.next*`, `.open-next` y cachés de build de la sesión
  (`Remove-Item -LiteralPath <ruta> -Recurse -Force`). No tocar `node_modules`.
