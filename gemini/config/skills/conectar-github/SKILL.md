---
name: conectar-github
description: Conecta el PC a GitHub (iniciar sesión con gh), configura la identidad de git y crea repositorios automáticamente para cada proyecto nuevo. Usar cuando el usuario diga "conecta GitHub", "inicia sesión en GitHub", "sube esto a GitHub", "crea el repo", o al empezar cualquier proyecto que todavía no tenga repositorio.
---

# Conectar GitHub y crear repos automáticamente

## 1. Comprobar si ya está conectado (siempre primero)
```powershell
gh auth status
```
- Dice «Logged in to github.com account X» → ya está; ir al paso 3.
- Dice «not logged in» o `gh` no existe → paso 2 (si falta `gh`: `winget install --id GitHub.cli -e`
  y abrir una terminal nueva).

## 2. Iniciar sesión (lo hace el USUARIO, una sola vez)
Ejecutar en la terminal:
```powershell
gh auth login --hostname github.com --git-protocol https --web
```
Sale un **código de 8 caracteres** y se abre el navegador. Decirle al usuario: «copia el código
XXXX-XXXX, pégalo en la página que se abrió y autoriza». El agente **nunca** escribe contraseñas ni
códigos por el usuario. Después:
```powershell
gh auth setup-git
gh auth status
```
`setup-git` hace que `git push` use la sesión de gh (sin pedir contraseña cada vez).

## 3. Identidad de git (una vez por PC; revisar antes del primer commit)
```powershell
git config --global user.name
git config --global user.email
```
Si están vacíos, preguntar al usuario qué nombre/marca y correo quiere en sus commits.
**Recomendado para privacidad:** el correo privado de GitHub. Obtenerlo así:
```powershell
$u = gh api user --jq .login; $id = gh api user --jq .id; "$id+$u@users.noreply.github.com"
```
y configurarlo con `git config --global user.email "<ese correo>"`. Así su correo personal no queda en
repos públicos. (En GitHub → Settings → Emails activar «Keep my email addresses private».)

## 4. Crear el repo de un proyecto (automático, sin preguntar cada vez)
Dentro de la carpeta del proyecto:
```powershell
if (-not (Test-Path .git)) { git init -b main }
if (-not (Test-Path .gitignore)) { Set-Content .gitignore "node_modules/`n.env`n.env.*`n!.env.example`n.wrangler/`ndist/`n.astro/`n.next/`n*.log`n.DS_Store`nThumbs.db" }
git add -A
git commit -m "Primera versión"
gh repo create <nombre-del-proyecto> --private --source . --remote origin --push
```
Reglas:
- **Privado por defecto.** Público solo si el usuario lo pide (y entonces revisar que no haya datos
  personales, claves ni datos de clientes).
- Nombre del repo: minúsculas con guiones, el nombre del proyecto/cliente (`peluqueria-maipu`), nunca
  el nombre personal del usuario.
- **Antes de cada commit:** `git status` y revisar que no entren `.env`, claves, tokens, bases de datos
  locales ni archivos gigantes (> 50 MB). Si una clave llegó a un commit, avisar y rotarla.
- Commits con mensajes cortos en español que digan qué cambió.

## 5. Día a día
- Tras cada cambio que funcione: `git add -A; git commit -m "..."; git push`.
- Ver repos: `gh repo list`. Abrir en el navegador: `gh repo view --web`.
- Clonar uno: `gh repo clone <usuario>/<repo>`.
- Si `git push` pide usuario/contraseña: correr `gh auth setup-git` de nuevo.

## 6. Problemas típicos
- «Permission denied» / 403 al hacer push → `gh auth status`; si la cuenta es otra, `gh auth switch`.
- Internet lento con GitHub (pasa en Venezuela): probar con Cloudflare WARP activado.
- «refusing to merge unrelated histories» → el repo remoto ya tenía archivos: `git pull origin main
  --allow-unrelated-histories`, resolver y subir.
