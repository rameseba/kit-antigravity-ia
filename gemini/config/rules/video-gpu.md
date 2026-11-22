---
trigger: model_decision
description: Leer al renderizar video o reels, generar voz o transcribir audio, correr IA local, o usar Chromium/Playwright headless para capturas o renders.
---

# Video, voz y tareas pesadas: usar la GPU dedicada

Todo lo pesado (IA, voz, video, render, codificación) va en la GPU dedicada (NVIDIA), nunca en los
gráficos integrados, y aprovechando todos los hilos de la CPU en paralelo.

## Chromium / Edge / Playwright headless
Por defecto usa la GPU integrada (Intel). Lanzar con:
```js
chromium.launch({ args: ['--force_high_performance_gpu'] })
```
Verificado: el WebGL renderer pasa a «NVIDIA GeForce RTX…». `--enable-gpu` / `--use-angle` solos NO bastan.

## ffmpeg
Codificar con NVENC, no libx264:
```
ffmpeg -i in.mp4 -c:v h264_nvenc -preset p6 -tune hq -rc vbr -cq 21 -b:v 0 out.mp4
```
(`hevc_nvenc` / `av1_nvenc` según la tarjeta.)

## PyTorch / TTS / Whisper
`device='cuda'`. faster-whisper en GPU necesita `cublas64_12.dll`:
`pip install nvidia-cublas-cu12 "nvidia-cudnn-cu12==9.*"` y agregar al PATH de usuario las carpetas
`site-packages\nvidia\cublas\bin` y `site-packages\nvidia\cudnn\bin`.
Si faster-whisper falla leyendo el archivo (`TypeError metadata_errors`), extraer el audio:
`ffmpeg -i v.mp4 -ac 1 -ar 16000 -f s16le a.raw` y pasarlo como numpy float32.

## Renders en paralelo
Varias páginas de navegador a la vez (ej. 6) para renderizar cuadros/escenas; parametrizar con una
variable de entorno `WORKERS`.

## Formato de reels que funcionó
Formato «Top 5»: mascota animada que habla con la voz, voz clonada (Qwen3-TTS), fondos con puntos,
todo en movimiento continuo, subtítulos que saltan, sello de marca chico persistente, cierre de marca
con sonido, efectos suaves (whoosh/pop) y elementos con aire (no amontonados). Detalle:
`cerebro/reference/marketing-meta-y-reels.md`. Skills: `remotion-*`, `motion-design`.

## Descargar reels públicos
`python -m yt_dlp -f b -o "reel.%(ext)s" <url>`
