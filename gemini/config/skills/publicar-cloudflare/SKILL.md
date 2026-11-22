---
name: publicar-cloudflare
description: Publica webs en Cloudflare gratis aunque no haya dominio propio (subdominio *.workers.dev), inicia sesión con wrangler, elige un subdominio de marca, despliega sitios estáticos o Astro con Workers, conecta un dominio después y verifica en la URL real. Usar cuando el usuario diga "publícalo", "súbelo", "ponlo en línea", "inicia sesión en Cloudflare", "deploy", o cuando una web esté lista para mostrarse.
---

# Publicar en Cloudflare (con o sin dominio)

Cloudflare Workers publica gratis: 100.000 peticiones/día en el plan gratuito y los archivos estáticos
no cuentan. **No hace falta tener dominio**: cada cuenta tiene un subdominio `<algo>.workers.dev` y
cada proyecto queda en `https://<proyecto>.<algo>.workers.dev`.

## 1. Cuenta e inicio de sesión (una sola vez)
1. Si no tiene cuenta: que la cree en https://dash.cloudflare.com/sign-up (gratis; la crea el usuario,
   el agente no escribe contraseñas).
2. Iniciar sesión desde la terminal:
   ```powershell
   npx wrangler login
   ```
   Se abre el navegador → el usuario hace clic en **Allow**. Comprobar:
   ```powershell
   npx wrangler whoami
   ```
3. **Elegir el subdominio `workers.dev` (MUY IMPORTANTE, se ve en todas las URLs):** en el panel →
   Workers & Pages → «Subdomain» → ponerle la **marca**, no el nombre personal
   (`dieguiviris.workers.dev` ✅, `diego-perez-1990.workers.dev` ❌). Se puede cambiar después, pero
   rompe los links ya enviados. Preguntarle al usuario cuál quiere antes del primer deploy.

## 2. Publicar un sitio estático (HTML/CSS/JS, plantillas del kit)
En la carpeta del proyecto, `wrangler.jsonc`:
```jsonc
{
  "name": "peluqueria-maipu",            // = parte de la URL: peluqueria-maipu.<sub>.workers.dev
  "compatibility_date": "2026-11-01",
  "assets": { "directory": "./public", "not_found_handling": "404-page" }
}
```
Publicar:
```powershell
npx wrangler deploy
```
La salida muestra la URL. **Abrirla en el navegador integrado de Antigravity y revisarla** (móvil y
escritorio) antes de decir «listo».

## 3. Publicar un sitio Astro
```powershell
npm create cloudflare@latest -- mi-sitio --framework=astro
cd mi-sitio; npm run build; npx wrangler deploy
```
O en un Astro existente: `npx astro add cloudflare` y `npx wrangler deploy`. Detalle y patrones:
skill `frameworks-on-cloudflare` y `cerebro/reference/sitios-astro-worker-patrones.md`.

## 4. Formularios y cosas «con servidor» sin pagar
- Formulario de contacto: lo más simple es enviar a **WhatsApp** (`wa.me`). Si hace falta guardar
  datos: Worker + KV/D1 **con tope diario en código** (ej. 300 envíos/día) y anti-spam con Turnstile
  (skill `turnstile-spin`).
- Variables secretas: `npx wrangler secret put NOMBRE` (nunca en el código ni en git).

## 5. Cuando tenga dominio
- Comprar el dominio (Cloudflare Registrar a precio de costo, o cualquier registrador y apuntar los
  DNS a Cloudflare).
- En `wrangler.jsonc`:
  ```jsonc
  "routes": [{ "pattern": "midominio.com", "custom_domain": true }]
  ```
  y `npx wrangler deploy`. Para subdominios de prueba por cliente:
  `{ "pattern": "cliente.midominio.com", "custom_domain": true }`.
- El `workers.dev` sigue funcionando como respaldo.

## 6. Costos: plan gratuito y sin sorpresas
- Quedarse en el plan **Free** salvo que el usuario decida otra cosa. Cloudflare no tiene tope de gasto
  automático en planes pagos: ver regla `costos-cloud.md`.
- No activar productos pagos (R2 sobre el gratis, Workers AI pagado, Images, Stream) sin preguntar.

## 7. Verificar siempre
1. Abrir la URL publicada en el navegador integrado; revisar en vista móvil (375 px) y escritorio.
2. Probar formulario, botón de WhatsApp y links.
3. Si el cambio no aparece: forzar recarga y revisar que el CSS/JS nuevo se sirva (cambiar `?v=N`).
4. Recién ahí decir «publicado en <URL>» y guardar la URL en `ESTADO.md`.

## Problemas típicos
- `wrangler login` no abre el navegador → copiar la URL que muestra y abrirla a mano.
- «You need a workers.dev subdomain» → hacer el paso 1.3.
- Error de autenticación tras días → `npx wrangler login` de nuevo.
