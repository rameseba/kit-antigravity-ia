---
name: actualizar-kit
description: Revisa si hay una versión nueva del kit de reglas y skills, la instala sin pisar lo que el usuario agregó (mis-reglas.md, cerebro/reference/mis-*.md, leads, ESTADO.md de proyectos) y respalda su conocimiento propio en un repo privado de GitHub. Usar cuando el usuario diga "actualiza el kit", "hay novedades del kit", "respalda mis reglas", o una vez al mes de forma proactiva.
---

# Actualizar el kit y hacerlo crecer

## 1. ¿Hay versión nueva?
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/rameseba/kit-antigravity-ia/main/bootstrap.ps1))) -SoloRevisar
```
Muestra la versión instalada, la publicada y las novedades (CHANGELOG). Contarle al usuario en 2–3
líneas qué trae de nuevo y preguntar si actualiza.

## 2. Actualizar (con su visto bueno)
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/rameseba/kit-antigravity-ia/main/bootstrap.ps1))) -Actualizar
```
- Reusa sus datos (marca, correo, país) guardados en `~/.gemini/kit.json`: no pregunta nada.
- Respalda `GEMINI.md` y `rules/` como `.bak-<fecha>` antes de copiar.
- **Reemplaza** los archivos del kit (GEMINI.md, reglas y skills del kit, plantillas).
- **No toca:** `rules/mis-reglas.md`, `skills/cerebro/reference/mis-*.md`, `cerebro/reference/REGISTRO.md`,
  `~/.gemini/memoria/`, skills nuevas que él haya creado, ni sus proyectos.
- Después: cerrar y volver a abrir Antigravity.
- Si el usuario había editado a mano un archivo del kit, ese cambio se pierde (queda en el `.bak`):
  revisar el respaldo y pasar lo suyo a `mis-reglas.md`.

## 3. Cómo crece el kit con el usuario (hacerlo sin que lo pida)
| Pasa esto | Va a |
|---|---|
| El usuario corrige algo que debe valer siempre («no hagas X», «siempre Y») | `~/.gemini/config/rules/mis-reglas.md`: una línea `fecha · regla · por qué` |
| Se resolvió un bug o patrón técnico reutilizable | `~/.gemini/config/skills/cerebro/reference/mis-<tema>.md` + línea en `REGISTRO.md` |
| Precios/paquetes que decidió | `cerebro/reference/mis-precios.md` |
| Lead o cliente | `~/.gemini/memoria/leads.md` |
| Estado de un proyecto | `ESTADO.md` del proyecto |
Avisar en una línea qué se guardó y dónde. Nunca guardar contraseñas, claves ni tokens.

## 4. Respaldo privado en GitHub (recomendado, una vez)
Para no perder lo aprendido si formatea el PC. Solo sube lo del kit y lo suyo; **nunca** las
credenciales que Gemini/Antigravity guardan en `~/.gemini`.
```powershell
cd $HOME\.gemini
if (-not (Test-Path .git)) {
  git init -b main
  # lista blanca: se ignora TODO salvo lo listado
  Set-Content .gitignore "*`n!.gitignore`n!GEMINI.md`n!kit.json`n!config/`n!config/rules/`n!config/rules/**`n!config/skills/`n!config/skills/cerebro/`n!config/skills/cerebro/**`n!memoria/`n!memoria/**`n*.bak*`n*oauth*`n*cred*`n*token*`n*.key`n.env*"
}
git add -A
git status   # REVISAR: no debe aparecer nada con oauth, cred, token, key ni .env
git commit -m "Respaldo de reglas y cerebro"
gh repo create mi-cerebro-antigravity --private --source . --remote origin --push
```
Luego, cada tanto: `cd $HOME\.gemini; git add -A; git commit -m "Respaldo"; git push`.
Para restaurar en otro PC: instalar el kit y después `gh repo clone <usuario>/mi-cerebro-antigravity`
y copiar `config/rules/mis-reglas.md`, `config/skills/cerebro/reference/mis-*.md` y `memoria/`.

## 5. Proponer mejoras al kit original
Si algo del kit está mal o falta (y sirve para cualquiera, no solo para él), anotarlo en
`cerebro/reference/mis-sugerencias-kit.md` para enviárselo a quien mantiene el kit.
