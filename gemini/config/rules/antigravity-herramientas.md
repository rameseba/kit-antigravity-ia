---
trigger: always_on
description: Cómo aprovechar las herramientas propias de Antigravity (navegador integrado, terminal, artefactos, generación de imágenes, modelos) siguiendo el método del kit.
---

# Usar bien Antigravity

## Navegador integrado = verificar antes de decir «listo»
- Toda web, maqueta o cambio visual se **abre en el navegador integrado** y se revisa en **móvil
  (375 px) y escritorio**: capturas, consola sin errores, links, formulario, botón de WhatsApp.
- Tras publicar, revisar la **URL real** (no solo el archivo local). Adjuntar las capturas en el
  resumen final.
- Para investigar (skill `investigar`): recorrer los sitios de la competencia con el navegador y
  guardar capturas.
- Iniciar sesión en cuentas (Google, GitHub, Cloudflare, Meta) lo hace **el usuario**; el agente no
  escribe contraseñas ni códigos.

## Terminal
- Windows + PowerShell: comandos de PowerShell, no de bash.
- Comandos largos (instalaciones, renders, deploys) en segundo plano y **revisar su salida** antes de
  seguir; si piden permiso de administrador o una ventana de Windows, avisar al usuario de inmediato
  («aparece una ventana de permiso, haz clic en Sí»).
- Nada destructivo (borrar carpetas, `git push --force`, cambiar configuración del sistema, cambiar la
  directiva de ejecución de scripts) sin explicarlo y pedir confirmación.

## Planificar y dejar rastro
- Tareas grandes: primero un plan corto (pasos, archivos, cómo se verifica) y después ejecutar todo
  seguido sin parar en cada paso. Al final, un resumen con lo hecho, la URL y lo pendiente.
- Mantener `ESTADO.md` al día (skill `guardar-estado`) para poder abrir una conversación nueva sin
  perder nada: las conversaciones largas se vuelven lentas y caras.

## Generación de imágenes
- Si el agente puede generar imágenes, usarlo para bocetos, fondos, productos y creativos; para fotos
  finales de alta calidad, Google Flow (skill `creativos-imagenes`). Nunca personas generadas como cara
  principal de una web. Mostrar las opciones antes de usarlas en algo público.

## Elegir modelo (selector bajo el chat)
- **Rápido/Flash:** preguntas, cambios chicos, textos, comandos.
- **El más potente disponible (Pro u otro modelo de alto nivel):** diseño de una web, propuestas,
  depuración difícil, proyectos grandes, investigación. Si un resultado sale flojo con el modelo rápido,
  repetirlo con el potente antes de seguir parchando.
- Si el usuario no lo indicó y la tarea es grande, sugerir cambiar de modelo en una línea.

## Ejecución automática de comandos
- El modo que ejecuta todo sin preguntar (p. ej. «Turbo») es cómodo, pero puede correr comandos
  peligrosos. Recomendar el modo intermedio (pregunta antes de lo riesgoso) salvo que el usuario
  prefiera lo contrario.

## Herramientas conectadas (MCP), opcional
Los CLI (`gh`, `wrangler`, `npx`) ya cubren GitHub y Cloudflare desde la terminal. Si el usuario quiere
más, se pueden agregar servidores MCP desde el menú de Antigravity (ej. Playwright:
`npx @playwright/mcp@latest`). Agregar solo los que se usen: cada uno ocupa contexto.

## El kit crece con el usuario
- Lo que el usuario corrija y valga para siempre → `~/.gemini/config/rules/mis-reglas.md` (nunca
  editar los archivos del kit: una actualización los reemplaza).
- Patrones técnicos reutilizables → `~/.gemini/config/skills/cerebro/reference/mis-<tema>.md`.
- Para traer mejoras del kit: skill `actualizar-kit`.
