# Paneles para que el cliente edite su propio sitio: cómo fallan

Destilado el **2026-08-29** de los **dos ensayos completos** del panel de `floormasters-cl`
(Convex + React sobre un generador estático), que sacaron **8 fallos reales la primera vuelta y
12 la segunda**, todos encontrados **probando**, ninguno leyendo el código.

Aplica a cualquier panel hecho a medida para que un cliente no técnico edite su sitio sin tocar
código: el de Floor Masters, el `/editar-web` de `homenaje-florales-cl`, `servinel-net` y
`beauty-gang-world-com`, y el panel admin de las tiendas (para esas, además,
`TIENDAS-CONVEX-NEXT.md`).

La tesis: **un panel se rompe por lo que NO tiene, no por lo que tiene mal**. Los bugs de código
salen solos; los huecos —un campo que nadie declaró, una función sin llamador, una pantalla que
no existe— no se ven leyendo, sólo intentando usar el panel como lo usaría el cliente.

---

## 1. Los cuatro huecos que hay que buscar SIEMPRE

### 1.1 Campos del esquema que ningún formulario declara

En estos paneles el formulario suele pintarse desde una lista declarada (`campos: [...]`), y esa
lista **es la superficie real del panel**. Todo lo que esté en el esquema y no en la lista es
contenido que el cliente ve publicado y no puede tocar.

En Floor Masters faltaban: el **cuerpo entero de las guías del blog** (los apartados con sus
párrafos), las preguntas de cada guía y de cada servicio, «Qué hace variar el precio» —el bloque
que responde *¿cuánto cuesta?* sin dar tarifas, o sea el diferenciador del sitio—, «También
hacemos», los valores, «lo que nos define» y la zona de trabajo del pie. Un servicio o una guía
recién creados salían publicados **con esas secciones en blanco**.

**Chequeo mecánico**, vale para cualquier panel: por cada tabla, cruzar las claves del esquema
(o las de la función que crea un elemento nuevo) contra las claves declaradas en el formulario.
Lo que sobre, o se edita o es dato muerto — y conviene saber cuál de las dos cosas es. En Floor
Masters `audiences` resultó ser dato muerto: se cargaba, se pasaba al render y no lo usaba nadie.

### 1.2 Funciones del servidor sin ningún llamador

Mismo patrón que ya está registrado para las tiendas (`sendOrderConfirmationEmail`,
`/api/support/notify`): **la pieza existe, está terminada, funciona, y nadie la llama.** Como no
falla nada, no aparece en ningún log.

En Floor Masters eran dos, y las dos de cuentas:

- `auth.changePassword` — completa, con validaciones y cierre de las demás sesiones. Sin
  llamador. Y `mustChangePassword`, que el creador de cuentas marca, no lo miraba nadie: **la
  contraseña temporal que viaja por un mensaje era la definitiva**, para siempre.
- `panel.unlockUser` — sin llamador. La pantalla enseñaba «bloqueada» y no ofrecía nada: el único
  remedio era esperar 15 minutos o llamar al desarrollador.

**Chequeo:** por cada función pública del backend, `grep` de su nombre en el frontend. Cero
resultados = o sobra, o falta el botón. En Convex:

```bash
grep -rn "^export const" convex/*.ts | grep -v internal   # la superficie pública
# y por cada una:  grep -rn "api\.<modulo>\.<funcion>\b" <frontend>/
```

### 1.3 Pantallas que el plan da por hechas y no existen

La memoria del proyecto decía «al comprar el dominio hay que cambiar la dirección **en el panel**
(Ajustes, sólo administrador)». **No había ninguna pantalla de Ajustes.** El control de permiso
—«sólo el dueño puede cambiar `site.url`»— estaba escrito y probado en el servidor, protegiendo
un campo que ningún formulario pintaba.

**Señal de alarma barata:** un control de acceso sobre un campo, sin un formulario que edite ese
campo. Casi siempre significa que la pantalla se planeó y no se hizo.

### 1.4 Avisos que sólo cubren el primer caso

El panel prometía «avisa si una combinación queda difícil de leer» y comprobaba **1 de los 13
colores** (el fondo de la cabecera). Justo el error más probable —un ámbar claro en el botón
principal, que en ese mismo proyecto ya había fallado el contraste una vez— pasaba sin una
palabra.

**Chequeo:** por cada aviso que el panel promete, escribir el caso que debería dispararlo **y uno
distinto del que el programador tenía en mente**. Si el segundo no avisa, la promesa es falsa.

---

## 2. Roles: el permiso se rompe por los dos lados a la vez

Con dos roles (`editor` / `owner`) aparecieron los dos fallos simétricos, y conviene buscar los
dos juntos:

**Demasiado poco.** El editor **no podía guardar ni el teléfono ni los colores**, que es
exactamente lo que la propia pantalla de permisos le promete. Causa: cada pantalla mandaba el
bloque de configuración **entero** (`{contact, site, brand, coverage}`), con la dirección del
sitio dentro, que es del administrador → el servidor rechazaba la petición completa.

> **Regla: cada pantalla manda SÓLO su parte.** Un guardado que arrastra campos que la pantalla
> no edita hereda los permisos del campo más restringido, y el resultado es un rol que no puede
> hacer nada de lo que se le prometió. Da igual que el usuario no haya tocado ese campo: viaja
> igual.

**Demasiado.** El editor **veía «Cuentas»** en el menú, entraba y leía «sólo el administrador
puede ver esto». No es un agujero —el servidor la negaba bien— pero es un menú que miente.

> **Regla: filtrar el menú por rol, no sólo el servidor.** Y probar con una cuenta de cada rol de
> verdad; leer el código no lo enseña, porque cada mitad está bien por separado.

**Cómo probarlo sin teclear contraseñas** (Claude no puede escribirlas en un formulario): crear
una cuenta temporal por CLI, sacar el token llamando al login por API, y sembrar el
`localStorage` del panel. Al terminar, borrar la cuenta.

---

## 3. El formulario devuelve cadenas; el esquema quiere números

Un `<input>` devuelve `"7"`. Si el esquema pide un número, la base rechaza el documento **con un
error de esquema, que no es un error de aplicación**: Convex lo sustituye por
`[Request ID: …] Server Error` y el panel enseña su mensaje genérico. En Floor Masters eso hacía
que **crear una guía fallara siempre** en cuanto se tocaba «Minutos de lectura», con el mensaje
más inútil posible: *«El servidor rechazó el cambio y no explicó por qué»*.

Es la versión de formulario del patrón ya conocido de las tiendas («el panel miente en producción
porque nadie usa `ConvexError`»), y se arregla en los dos sitios: tipo de campo numérico en el
panel **y** conversión + validación con mensaje propio en el servidor.

**Chequeo de 1 minuto:** listar los campos del esquema que no son `string` y comprobar con qué
control se editan.

---

## 4. Las protecciones de borrado se escriben una vez y no se replican

Borrar un servicio comprobaba quién lo enlazaba, lo decía por su nombre y no borraba nada.
Borrar una **comuna** —enlazada como «comuna cercana» desde otras cuatro— **no comprobaba nada**:
se borró en silencio y cuatro páginas perdieron un enlace sin que nadie se enterara. Y se podían
borrar todas, dejando el borrador impublicable.

> **Regla: si una tabla tiene protección de borrado, todas las que se referencian entre sí la
> necesitan.** Poner las ramas de borrado de cada tabla una al lado de la otra y comparar; es el
> mismo método que destapó que cancelar un pedido devolvía el stock por el panel y no por la
> pasarela.

Ojo con la excusa «el render ya lo tolera»: es verdad —un `filter(Boolean)` descarta la
referencia rota— pero el cliente pierde contenido sin avisar, que es peor que un error.

---

## 5. El panel en el teléfono: medirlo, no mirarlo

Un panel a tres columnas en un móvil no se degrada: **se rompe**. Y el cliente va a abrirlo desde
el teléfono, porque es el aparato que tiene encima.

Medido en Floor Masters antes de tocar nada, en 390 px:

| | Antes | Después |
|---|---|---|
| Ancho que pide el documento | **613 px** (con 386 de pantalla) | 386 px |
| Barra superior | 613 px → «Publicar» y «Salir» fuera de pantalla | cabe, en dos filas |
| Columna de edición | 181 px | 386 px |
| Campos de texto | **68 px** | 313 px |

La causa era una sola: había un corte en `1100px` que escondía la vista previa **y ningún corte
por debajo**, así que el menú fijo seguía comiéndose 190 px. Arreglo: menú en cajón con ☰ sobre
un velo, formulario a ancho completo, listas apiladas, `100dvh` en vez de `100vh`.

**Cómo medirlo de verdad** (ya costó tiempo en dos proyectos de esta cuenta): cambiar el tamaño
de la ventana **no cambia el viewport**. Lo que funciona es inyectar un iframe del mismo origen
de 390×844 y medir dentro; las media queries responden al tamaño del iframe.

```js
const f=document.createElement('iframe'); f.src='/admin/';
f.style.cssText='position:fixed;right:0;bottom:0;width:390px;height:844px;z-index:99999';
document.body.appendChild(f); await new Promise(r=>f.onload=r);
const d=f.contentDocument, w=f.contentWindow;
console.log(w.innerWidth, d.documentElement.scrollWidth);   // si no coinciden, se desborda
```

Un número (613 contra 386) convence y se puede volver a medir después del arreglo. «Se ve
apretado» no.

---

## 6. Un fallo del servicio de compilación que no es un fallo

Publicar disparaba un enganche de compilación (deploy hook de Cloudflare Pages) y la publicación
se marcaba **error** cada vez que se publicaba dos veces seguidas. El enganche responde **`304`**
cuando **ya hay una compilación en cola para el mismo commit**: no crea otra, pero el sitio se
regenera igual. Tratar todo lo que no sea `2xx` como fallo pintaba de rojo una publicación
correcta y el cliente creía que no había salido.

> **Regla: en una integración con un servicio externo, cada código de estado se decide a mano.**
> `r.ok` es una aproximación, y en los enganches de compilación es la aproximación equivocada.

(El `304` no se pudo reproducir a voluntad: dos publicaciones seguidas devolvieron `200` las dos.
La condición es más estrecha que «dos seguidas».)

---

## 7. El método que hace posible probar a lo bruto

Sin esto no se prueba de verdad, y probar a medias no encuentra nada. Es lo que permitió crear,
borrar y romper cosas **en producción** durante horas y dejarlo todo como estaba:

1. **Copia local del borrador** antes de tocar nada.
2. **Una publicación marcada como punto de retorno** (con nota que lo diga).
3. Probar sin miedo: crear, editar, subir, borrar, reordenar, publicar, volver atrás.
4. Al terminar, **recuperar el punto de retorno desde el propio panel** — eso también es parte
   de la prueba, no un rodeo.
5. **Comparar el borrador con la copia, byte a byte.** No «parece igual».
6. Comparar **lo servido con lo que genera la máquina, página por página**, no sólo que responda
   200.
7. Limpiar los archivos huérfanos y borrar las cuentas temporales.

En las dos vueltas la única diferencia tras el paso 5 fue la tabla de **archivos subidos**, que
no viaja en las publicaciones: volver atrás deja la foto huérfana en el almacenamiento. Merece su
propia función de limpieza (`media:limpiarHuerfanos`) — **cualquier panel con subida de archivos
y con historial de versiones tiene este hueco.**

---

## 8. Trampas de herramienta (cuestan una hora cada una)

- **`npx convex codegen` NO sube las funciones**, sólo genera tipos. Las pruebas contra
  producción siguen viendo el código viejo y parece que el arreglo no sirve. Sube
  `npx convex dev --once` (con el deploy key de producción, va a producción). `npx convex deploy`
  lo bloquea el clasificador de permisos.
- **`npx convex run … --prod` con el deploy key ya apuntando a producción imprime un aviso ANTES
  del JSON**: el respaldo se guarda con basura delante y no se puede leer. Sin el flag.
- **Un verificador que «regenera y compara» puede REESCRIBIR la salida** con una fecha fija y con
  el contenido de los archivos del repo en vez del de la base. Después de correrlo, la carpeta de
  salida ya no es lo que se desplegaría — y comparar contra lo servido da un falso positivo (aquí
  fue el `lastmod` del sitemap). Reconstruir antes de comparar.
- **Un `.click()` sintético sobre un botón de React DENTRO de un iframe no dispara nada.** Hay que
  mandar un `MouseEvent` construido con el `view` de la ventana del iframe.
- **Las transiciones CSS no avanzan mientras el panel del navegador está oculto** (el navegador
  frena `requestAnimationFrame`): un cajón que se abre con `transform` parece no abrirse nunca.
  Quitarle la transición antes de medir.
- **`element.focus()` no dispara nada si la pestaña no tiene el foco real**: probar un `onFocus`
  automatizado da falso negativo.
- **Un `alert()` nativo congela el renderer** y hace fallar capturas y JS con timeouts. Parchear
  `window.alert` y `window.confirm` ANTES de enviar el formulario, y leer después lo que se
  guardó.
- **La comprobación de acceso que agota los intentos deja la cuenta bloqueada**: correrla la
  ÚLTIMA, o con una cuenta desechable aparte, o las demás fallan sin motivo aparente.

---

## 9. La pregunta que resume todo

Antes de dar por bueno un panel, contestar **con el panel abierto**, no leyendo el código:

1. ¿Puedo editar **cada cosa** que se ve publicada? (esquema contra formulario)
2. ¿Puedo crear un elemento nuevo **completo**, sin que salga con secciones en blanco?
3. ¿Funciona con la cuenta de **cada rol**, y el menú enseña sólo lo que ese rol puede usar?
4. ¿Se puede usar **en el teléfono**? (medido, no mirado)
5. ¿Puedo **cambiar mi contraseña** y desbloquear una cuenta?
6. ¿Cada función del servidor tiene **alguien que la llame**?
7. Cuando algo se rechaza, ¿el mensaje nombra **lo que pone en la pantalla**?
8. ¿Borrar algo en uso **avisa**, en todas las tablas que se referencian?
