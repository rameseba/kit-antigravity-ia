---
trigger: model_decision
description: Leer antes de correr comandos que reescriben configuración (.env, vercel link/env pull, supabase link, convex dev, firebase init) o antes de avisar al usuario que algo se rompió.
---

## ⚠️ Patrones a NO repetir con archivos de configuración y con los avisos de daño (2026-08-10)
> **Qué es:** cómo tocar config sin romper nada y cómo avisar al usuario cuando algo se rompió.
> **Actualizado:** 2026-11-19


Dos errores cometidos en la misma sesión (Akim, investigación de pagos Webpay). Ninguno causó
daño real, pero el segundo le hizo perder tiempo al usuario y casi lo manda a recuperar
credenciales que nunca se habían perdido.

**1. Copiar el archivo ANTES de correr un comando que lo reescribe.** `vercel link` (y
`vercel env pull`) reescriben `.env.local` sin preguntar y sin dejar respaldo; el output sólo
dice `✓ Updated .env.local file`. Lo mismo vale para cualquier comando que "sincroniza"
configuración (`supabase link`, `npx convex dev`, `firebase init`, generadores de CLI). **Regla:
`cp .env.local .env.local.bak-$(fecha)` antes, o al menos guardar la lista de nombres de
variables** (`grep -oE '^[A-Z_]+=' .env.local | tr -d '='`) para poder comparar después. Cuesta
un segundo y elimina toda la incertidumbre.

**2. NO anunciar un daño sin haberlo verificado.** Acá se afirmó que `vercel link` había
"sobrescrito el `.env.local` y borrado las variables `WEBPAY_*`", y se le dijo al usuario que
tendría que ir a buscar sus credenciales de producción a Transbank porque en Vercel están
marcadas *Sensitive* y no se pueden volver a leer. **Era falso.** La afirmación salió de
`SESSION_MEMORY.md` del repo (2026-07-03), que listaba "Transbank Webpay Plus" entre las
credenciales de `.env.local`. Ese archivo estaba desactualizado: el `.env.local` real ya era
producto de un `vercel env pull` anterior y **nunca** tuvo variables `WEBPAY_*` (viven sólo en
scope Production de Vercel). Al comparar contra una copia del usuario en
`D:\SECUNDARIO\MIGRACION_2026-07-23\` quedó claro que los 29 nombres de variable eran idénticos
y todos los valores tenían el mismo largo: lo único que cambió fue `VERCEL_OIDC_TOKEN`, que
estaba vacío y el comando lo rellenó. O sea, `vercel link` sólo AGREGÓ.
**Regla: un aviso de "rompí X" es una afirmación de hecho y necesita evidencia antes de
enviarse.** La comprobación barata es comparar nombres y LARGOS de valor (nunca los valores) de
la copia vieja contra la nueva:
`awk -F= '/^[A-Za-z_]/{n=$1;print n, length(substr($0,length(n)+2))}' archivo | sort` y hacer
`join` de ambos. Si no hay copia con qué comparar, decirlo como sospecha ("puede que se haya
sobrescrito, no lo puedo confirmar") y no como hecho — y menos mandar al usuario a rotar o
recuperar credenciales.

**3. Los archivos de memoria del repo (`SESSION_MEMORY.md`, `CLAUDE_MEM.md`) son de una fecha,
no del estado actual.** Antes de sacar conclusiones operativas de ellos (sobre todo si van a
disparar un aviso al usuario o un cambio de plan), verificar contra el disco real.

**Copia de respaldo útil del usuario:** `D:\SECUNDARIO\MIGRACION_2026-07-23\Documents\` tiene una
copia de los repos de `Documents\` de esa fecha, incluidos archivos ignorados por git como
`.env.local`. Sirve para comparar cuando se sospecha que algo local se corrompió. **Es de sólo
lectura: no mover, no borrar, no escribir ahí.**


## Trampas de config vistas en Vale-nails-designs (2026-10-09/11)
- `wrangler pages project create` hoy AUTO-MIGRA a Workers: reescribe wrangler.jsonc, mete `@cloudflare/vite-plugin` en vite.config.ts
  y package.json y despliega un Worker con nombre derivado de la carpeta (+ URL *.workers.dev con el usuario). Para sitios estáticos usar
  directo `wrangler.jsonc` con `assets` (SPA) + `routes: [{pattern, custom_domain: true}]`, `workers_dev: false`, y `npx wrangler deploy`.
  Si pasa: revertir vite.config/package.json y borrar el Worker sobrante (`wrangler delete --name …`).
- Vite carga `.env.local` TAMBIÉN en `vite build` (producción). Una bandera solo-local (p. ej. abrir un panel) va en `.env.development.local`.
- Safari iOS: capas 3D anidadas (preserve-3d dentro de preserve-3d con su propia perspective) y `translateZ(calc(var()…))` se dibujan mal.
  Usar estructura plana (todas las capas hijas de un solo contenedor 3D), profundidades en `em`, y órbitas en 2D con sin()/cos() + z-index.

## Recién publicado en Cloudflare Pages: 404 de assets nuevos ≠ roto (2026-11-19)
Tras `wrangler pages deploy`, archivos NUEVOS (p. ej. capturas en `assets/shots/<slug>/`) pueden dar 404 en el dominio propio
durante ~1 minuto mientras en `<hash>.<proyecto>.pages.dev` ya dan 200. Antes de avisar «se rompió», comparar con la URL del
deployment y reintentar a los 20–60 s. Visto en <tu-dominio.com> (commit 5517cb1).
