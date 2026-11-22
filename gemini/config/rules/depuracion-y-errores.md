---
trigger: model_decision
description: Leer al depurar un bug, cuando un arreglo no funcionó, cuando algo falla solo en iPhone/Safari, o antes de avisar al usuario que algo se rompió.
---

# Depuración y patrones de error

## Regla 1: dos intentos fallidos de la misma categoría = diagnóstico equivocado
Si van 2+ intentos fallidos atacando la misma causa (p. ej. «la imagen no carga»: headers, caché,
optimizador…), NO probar una tercera variante. Parar, releer toda la evidencia y preguntarse:
**«¿qué dato tengo que mi hipótesis actual no explica?»**. Ese dato «raro» casi siempre es la pista.

## Regla 2: iOS Safari — el recurso carga solo pero no se ve en la página → es el CONTENEDOR
Si una imagen carga perfecto pegando su URL en el navegador, pero no aparece en la página y el bug es
solo de iPhone/Safari (Chrome/Android bien): no es red, ni CORS, ni caché. Es layout: el contenedor
colapsa a altura 0.
Caso real: `<div class="aspect-2/3 overflow-hidden">` con un único hijo `<img class="absolute inset-0">`.
El hijo absoluto no aporta altura y WebKit no calculaba el `aspect-ratio`. Se gastaron 4 arreglos de
«carga» antes de ver esto.
**Arreglo robusto:** truco de padding (`padding-top: 150%` para 2/3) en vez de `aspect-ratio` cuando el
único hijo es absoluto. Primero verificar con el inspector si el contenedor tiene dimensiones.

## Regla 3: iOS Safari — `window.open()` después de un `await` se bloquea en silencio
La operación async se completa (el pedido se guarda) pero la ventana nunca se abre → «dice que
funcionó pero no pasó nada».
```js
btn.addEventListener('click', async () => {
  const win = window.open('', '_blank');      // síncrono, dentro del click
  const url = await crearPedidoYArmarLink();
  win.location.href = url;                     // navegar la ventana ya abierta
});
```

## Regla 4: avisos de daño necesitan evidencia
«Rompí X» / «se borraron tus variables» es una afirmación de hecho. Antes de decirlo, comparar contra
un respaldo (nombres y LARGOS de valores, nunca los valores). Notas internas viejas no son evidencia.
Ver regla `config-y-avisos.md`.

## Regla 5: mapear antes de construir
Antes de arreglar algo en un área con panel o ajustes, listar todas sus rutas/archivos: la solución
puede existir ya (cupones, roles, flags). Construir algo paralelo obliga a revertir después.

## Regla 6: bugs típicos de front (detalle en `web-diseno-y-frontend.md`)
- Salto lateral al abrir modal/panel: `html { scrollbar-gutter: stable; }` + `overflow:hidden` en
  `<html>`, NO `padding-right`. Con Radix/react-remove-scroll: `modal={false}` y sin scrollbar-gutter.
- Título invisible: una clase propia con `color` cargada después de Tailwind le gana a `text-white`.
  En clases de tipografía propias, no fijar `color` (usar `inherit`).
- Segundo componente muerto: `querySelector` en el script de un componente solo toma la primera
  instancia. Usar `querySelectorAll` y recorrer.
- Precio manipulado: carrito/cupón en localStorage se edita en consola. Revalidar en servidor.

## Regla 7: probar cosas que envían mensajes
Antes de probar en local algo que manda correos/WhatsApp/pagos, revisar las variables del entorno
local: si hay claves reales, quitarlas o no probar el envío.

## Regla 8: verificar donde lo ve el usuario
Un arreglo no está «listo» hasta verificarlo en la URL publicada (o decir explícitamente que solo
está en local). Tras el deploy, confirmar que el CSS/JS nuevo se sirve (caché del CDN con `?v=N`).
