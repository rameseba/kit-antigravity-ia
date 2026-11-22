---
name: guardar-estado
description: Guarda el estado del trabajo en ESTADO.md para poder cerrar el chat y retomarlo sin perder el hilo. Usar cuando el usuario diga "guarda todo", "continuamos después", "nos vemos", "me voy", al terminar una fase grande, o cuando la conversación ya esté muy larga.
---

# Guardar estado (para abrir un chat nuevo sin perder nada)

El contexto largo gasta cuota rápido. Esta skill deja todo escrito para que un chat nuevo retome
exactamente donde quedó. Hacerlo **sin que lo pidan** al cerrar fases o cuando el chat ya es largo.

## Dónde
- Estado del proyecto: `ESTADO.md` en la raíz del repo (o `.agents/memoria/ESTADO.md` si el repo es público
  y no debe llevarlo: en ese caso agregarlo a `.gitignore`).
- Lecciones del usuario que valen para este proyecto: `.agents/memoria/lecciones.md`.
- Lo que vale para TODOS los proyectos: skill `cerebro` (sección «Cómo escribir en el cerebro»).
- Leads / clientes: una línea por lead en `~/.gemini/memoria/leads.md` con estado y fecha de seguimiento.

## Qué escribir en ESTADO.md (corregir el existente, no duplicar)
```markdown
# Estado — <proyecto>
> Actualizado: <AAAA-MM-DD HH:MM>

## Objetivo
<qué se busca, en 1–3 líneas>

## Decisiones tomadas (y por qué)
- <decisión> — <motivo / quién lo pidió>

## Hecho
- <cambio> (commit <hash>, publicado en <url> / solo local)

## Pendiente — próximos pasos en orden
1. <paso concreto, con archivo/ruta>
2. ...

## Rutas y datos clave
- Repo / carpeta: ...
- URL de prueba / producción: ...
- Comandos: dev `...`, deploy `...`
- Datos verificados: ... (los no verificados con «POR CONFIRMAR»)

## Cuidado
- <trampas conocidas, cosas que NO tocar>
```

## Reglas
1. Nunca escribir claves, tokens, contraseñas ni datos personales del usuario: solo el NOMBRE de la
   variable y dónde vive (`.env.local`).
2. Fechas absolutas (`2026-11-22`), nunca «ayer» o «el jueves».
3. Un dato sin fuente se marca «POR CONFIRMAR».
4. Al terminar, decir en una línea: «Guardé el estado en ESTADO.md (objetivo, hecho, 3 pendientes).
   Puedes abrir un chat nuevo y decir "lee ESTADO.md y sigue".»

## Al abrir un chat nuevo
Si existe `ESTADO.md`, leerlo primero y retomar desde «Pendiente», sin repreguntar lo ya decidido.
