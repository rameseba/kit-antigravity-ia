# Herramientas locales para Windows (programas propios de escritorio)
> **Qué es:** cómo armar un programa de escritorio propio en el PC del usuario (medidores, utilidades) para que se vea profesional y Claude lo pueda controlar. Patrones salidos de hacer el «Probador de cargador».
> **Actualizado:** 2026-11-16

## Arquitectura que funcionó (2026-11-16, `Documents/diagnostico-bateria`, sin git)
Motor en PowerShell 7 + interfaz web local + ventana propia de Edge. Nada que instalar.
- **Motor** (`app/servidor.ps1`): `System.Net.HttpListener` en `http://127.0.0.1:<puerto>/` (ese prefijo no pide admin). Un solo hilo: `GetContextAsync()` + `Wait(150)` en un bucle que además hace el trabajo periódico. Sirve la interfaz, una API JSON y un endpoint `/mcp`.
- **Interfaz** (`app/web/index.html`): HTML/CSS/JS en un archivo, consulta `/api/estado` cada 2 s. Responsive y con letra nítida gratis.
- **Ventana**: `msedge.exe --app=http://127.0.0.1:<puerto>/ --user-data-dir=%LOCALAPPDATA%\<App>\ui --window-size=…`. Sale sin barra de navegador, con el favicon de la página.
- **Lanzador .exe**: C# mínimo compilado con el `csc.exe` que ya trae Windows (`C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /target:winexe /win32icon:x.ico`). Arranca el motor oculto si el puerto no responde y abre la ventana. Acceso directo en el Escritorio apuntando al .exe.
- **Cierre**: el motor revisa cada 8 s si sigue vivo algún `msedge.exe` con su `--user-data-dir` y se apaga solo. No usar latidos de la página: Edge frena los temporizadores de ventanas tapadas (un juego en pantalla completa) y el motor se apagaría en plena medición. Agregar `--disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-renderer-backgrounding`.

## Por qué NO WinForms desde PowerShell (se hizo primero y hubo que botarlo)
El usuario lo rechazó el mismo día: «la letra está como rara, el programa no es responsive, siento que está mal diseñado».
- pwsh no es DPI-aware para WinForms: con la pantalla al 125 % la letra sale borrosa.
- La barra de tareas muestra el ícono de PowerShell. `SetCurrentProcessExplicitAppUserModelID` + `$form.Icon` devolvió 0 y **igual no cambió el ícono**. No perder tiempo ahí.
- Posiciones fijas en píxeles: no se adapta.

## Que Claude lo controle: endpoint MCP a mano
Un MCP «Streamable HTTP» mínimo son ~40 líneas: `POST /mcp` con JSON-RPC, responder `application/json`.
- `initialize` → `{protocolVersion: <la que pide el cliente>, capabilities:{tools:{}}, serverInfo}`.
- Mensajes sin `id` (notificaciones) → HTTP 202 sin cuerpo.
- `tools/list` → `{tools:[{name, description, inputSchema}]}`; `tools/call` → `{content:[{type:'text', text}], isError:false}`.
- Registrar: `claude mcp add --transport http --scope user <nombre> http://127.0.0.1:<puerto>/mcp`. `claude mcp get <nombre>` confirma «Connected». Las herramientas aparecen en sesiones nuevas; en la misma sesión se controla con `Invoke-RestMethod` contra la API.
- Seguridad: escuchar solo en 127.0.0.1 y rechazar (403) cualquier `Origin` que no sea el propio, para que una página web abierta en el navegador no pueda mandarle órdenes.

## Trampas de PowerShell que costaron tiempo
- **Los nombres de variables no distinguen mayúsculas.** `$Y = { … }` (bloque) y luego `$y = …ToString()` son la MISMA variable: el bloque queda pisado y `& $Y` falla con «El término "236.0" no se reconoce». Nombrar distinto (`$ejeY`, `$py`).
- `$ErrorActionPreference='SilentlyContinue'` + `try {} catch {}` alrededor del trabajo periódico esconde ese tipo de fallo: la función «termina» sin resultado. Al probar, llamar la función por la API para ver el error 500 con el mensaje.
- pwsh 7 lee los `.ps1` como UTF-8 sin BOM; Windows PowerShell 5.1 no (tildes rotas). Si puede caer en 5.1, guardar con BOM o no usar tildes en el script.
- La consola del usuario es PowerShell: `Start-Sleep` largos encadenados se bloquean en la herramienta; usar ejecución en segundo plano para sondeos.

## Otros datos útiles
- **Edge en la RTX y no en la Intel:** `--force_high_performance_gpu` (con `--user-data-dir` propio para que sea un proceso aparte). Con `--disable-frame-rate-limit --disable-gpu-vsync` y un shader pesado en WebGL2 sirve como carga de GPU sin juego: llevó la RTX 4060 a 65-68 W.
- **PDF sin instalar nada:** `msedge --headless=new --disable-gpu --no-pdf-header-footer --user-data-dir=… --print-to-pdf="x.pdf" "file:///…/x.html"`.
- **Ícono .ico multi-tamaño sin herramientas:** dibujar con `System.Drawing`, guardar cada tamaño como PNG y envolverlos en el contenedor ICO (cabecera de 6 bytes + 16 por entrada). Revisar siempre una hoja con 256/48/32/16 px antes de entregarlo.
- **HWiNFO:** sus sensores se leen de la memoria compartida `Global\HWiNFO_SENS_SM2` (hay que activarla en ajustes; en la versión gratis se apaga a las 12 h). HWiNFO exige admin: lanzarlo dispara UAC cada vez. Ajustes en `C:\Program Files\HWiNFO64\HWiNFO64.INI` (`SensorsOnly`, `OpenSensors`, `MinimalizeSensors`, `MinimalizeMainWnd`, `ShowWelcomeAndProgress=0`, `SensorsSM=1`); escribirlo requiere elevación.
- **Batería por WMI** (`root\wmi`, clase `BatteryStatus`): el indicador `Charging` puede decir verdadero mientras descarga. El dato de fiar es la variación de `RemainingCapacity` en una ventana de 60 s.

## Gusto del usuario en sus propios programas
- Quiere ejecutable con ícono propio en el Escritorio, no un script.
- Logos: rechazó un medidor de colores sobre fondo oscuro y una batería genérica; eligió un enchufe blanco plano sobre verde. Mostrarle 3 o 4 opciones en una hoja y que elija, en vez de adivinar.
- Mismas reglas visuales que en sitios (`reglas-web.md`): tema claro y cálido, un solo acento, una tipografía, sin rayas largas.
