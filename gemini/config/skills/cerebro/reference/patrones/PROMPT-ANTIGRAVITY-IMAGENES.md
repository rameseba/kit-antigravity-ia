# Prompt para describir las imágenes (Antigravity / Gemini Flash)

Las imágenes ya están extraídas a disco como archivos normales, con un manifiesto que dice de
dónde salió cada una. Este documento es el encargo, listo para copiar y pegar.

## Antes de empezar (comprobar, no asumir)

1. Existe `C:\Users\<USUARIO>\Documents\supercerebro\datos\imagenes.jsonl` — una línea por imagen.
2. Existe la carpeta `C:\Users\<USUARIO>\Documents\supercerebro\imagenes\<proyecto>\`.
3. Cada línea del manifiesto tiene esta forma:

```json
{"id":"a1b2c3d4e5f6a7b8","proyecto":"piel-y-trigo-cl","sesion":"cb99ecd6-...","ts":"2026-08-22T18:37:00.000Z","origen":"usuario","ruta":"imagenes/piel-y-trigo-cl/a1b2c3d4e5f6a7b8.jpg","bytes":184320,"mediaType":"image/jpeg"}
```

`origen` vale `usuario` (la mandó la persona) o `claude` (captura que tomó el asistente).

---

## EL PROMPT

> Tienes un manifiesto en `supercerebro/datos/imagenes.jsonl`. Cada línea describe **una** imagen
> guardada en disco, en la ruta que indica el campo `ruta` (relativa a `supercerebro/`).
>
> **Tu tarea:** abrir cada imagen y escribir una descripción factual de lo que se ve. Nada más.
>
> **Empieza por las que tienen `"origen":"usuario"`: son 564 imágenes distintas.** Las envió una
> persona para señalar algo concreto —un error, un precio mal, una pantalla rota— y son las
> únicas cuyo contenido no está ya descrito en el texto de la conversación. Las 1.403 de
> `"origen":"claude"` son capturas automáticas del navegador y pueden esperar.
>
> En total el manifiesto tiene 2.037 líneas y 1.969 ficheros distintos: **algunas imágenes se
> repiten**, así que si dos líneas comparten `id` puedes reutilizar la misma descripción en vez
> de volver a mirar el fichero.
>
> **Para cada imagen, describe:**
> 1. **Qué es**: captura de pantalla de una web, de un panel de administración, de un móvil, de
>    una terminal, de un correo, una foto, un diagrama…
> 2. **Qué aplicación o pantalla se ve**, si es reconocible (nombre visible, URL de la barra de
>    direcciones, título de la página).
> 3. **Todo el texto legible que sea relevante, TRANSCRITO LITERALMENTE**, con especial atención
>    a: mensajes de error, URLs, importes y precios, números de pedido, nombres de campos de
>    formulario, códigos, y estados como "Pendiente" o "Pagado".
> 4. **Si se ve un problema o una confirmación**: ¿hay algo roto, un error en rojo, un dato
>    incorrecto, algo desalineado? ¿O es una pantalla de "todo salió bien"?
> 5. **Si hay marcas hechas a mano** (círculos, flechas, subrayados): qué señalan exactamente.
>    Suelen ser lo más importante de la imagen.
>
> **Reglas estrictas:**
> - **No inventes.** Si algo no se distingue, escribe `"ilegible"`. Es una respuesta válida y
>   útil; una descripción inventada envenena todo el trabajo posterior.
> - **No interpretes el contexto** ni supongas de qué iba la conversación: no la tienes.
>   Describe solo lo que se ve en la imagen.
> - **No resumas varias imágenes juntas.** Una línea de salida por cada línea de entrada.
> - **No cambies el orden ni te saltes ninguna.** Si una imagen no se puede abrir, emite igual su
>   línea con `"error":"no se pudo abrir"`.
> - **Escribe en español.**
>
> **Formato de salida:** un fichero `supercerebro/datos/imagenes-descritas.jsonl`, **una línea
> JSON por imagen**, con exactamente estos campos:
>
> ```json
> {"id":"<el mismo id del manifiesto>","tipo":"captura-web|captura-panel|captura-movil|terminal|correo|foto|diagrama|otro","pantalla":"<qué app o página, o \"desconocida\">","texto_visible":"<transcripción literal de lo relevante>","hallazgo":"<qué problema o confirmación se ve, o \"ninguno evidente\">","marcas_manuales":"<qué señalan, o \"ninguna\">","legibilidad":"buena|regular|ilegible"}
> ```
>
> **Trabaja por lotes de 50 imágenes** y guarda después de cada lote, para no perder trabajo si
> algo se corta.
>
> **Al terminar, comprueba y dime:** cuántas líneas tiene tu fichero de salida y cuántas tiene el
> manifiesto de entrada. **Tienen que ser el mismo número.** Si no coinciden, dime cuáles faltan
> por su `id`; no lo tapes.

---

## Cómo se comprueba el trabajo después

```bash
cd C:/Users/<USUARIO>/Documents/supercerebro
wc -l datos/imagenes.jsonl datos/imagenes-descritas.jsonl   # deben coincidir
```

Y que los `id` sean los mismos en los dos ficheros, sin inventados ni perdidos.

## Por qué se hace así y no de otra forma

Las imágenes vivían **en base64 dentro de los ficheros de conversación** (430 MB, el 84 % del
historial). Ninguna herramienta externa podía abrirlas sin extraerlas antes. El manifiesto es lo
que permite volver a unir cada descripción con su momento de la conversación: sin el `id`, una
descripción suelta no vale para nada.
