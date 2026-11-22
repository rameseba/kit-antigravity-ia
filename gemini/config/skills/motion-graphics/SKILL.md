---
name: motion-graphics
description: Hace videos y motion graphics con código - reels, historias, anuncios en video, intros de marca, explicadores con texto animado, subtítulos que saltan y voz - usando Remotion o HTML/CSS/GSAP renderizado con Playwright + ffmpeg. Usar cuando el usuario pida "un reel", "un video", "una animación", "motion graphics", "un intro", "subtítulos", "un video para Instagram/TikTok".
---

# Motion graphics y videos con código

## Elegir herramienta
| Necesidad | Herramienta |
|---|---|
| Reel/anuncio con escenas, texto animado, fotos, música, subtítulos | **Remotion** (React → MP4). Skills `remotion-create`, `remotion-best-practices`, `remotion-captions`, `remotion-render` |
| Animación simple, rápida, sin instalar mucho | **HTML + CSS/GSAP** en una página de 1080×1920, grabada cuadro a cuadro con Playwright y unida con ffmpeg |
| Microanimaciones de una web | CSS / Motion — skills `motion-design`, `emil-design-eng`, `review-animations` |
| Video «real» generado (escena filmada) | Google Flow (Veo) — skill `creativos-imagenes` |

## Flujo de un reel (30–60 s)
1. **Guion primero** (texto, no código): gancho en 2 s → 3 a 5 puntos → cierre con marca y llamada a la
   acción. Una idea por pantalla, frases cortas.
2. **Storyboard**: lista de escenas con duración, texto en pantalla, imagen y movimiento. Mostrarlo al
   usuario antes de animar (cambiar texto es gratis; re-renderizar no).
3. **Voz** (opcional): grabada por el usuario (lo más natural) o TTS
   (`pip install edge-tts`; `edge-tts --voice es-VE-PaolaNeural --text "..." --write-media voz.mp3`;
   voces venezolanas: `es-VE-PaolaNeural`, `es-VE-SebastianNeural`).
4. **Subtítulos**: transcribir la voz con Whisper (faster-whisper, en GPU si hay NVIDIA) → palabras con
   tiempos → subtítulos que aparecen palabra por palabra (skill `remotion-captions`).
5. **Animar** con Remotion (`npx create-video@latest`): composición 1080×1920 a 30 fps.
6. **Música y efectos**: suaves (whoosh, pop), música sin copyright (Pixabay Music, Mixkit). Volumen de
   música bajo la voz (~-18 dB).
7. **Render**: `npx remotion render` (con GPU: ver regla `video-gpu.md`). Revisar el MP4 completo
   antes de entregar.

## Estilo que funciona (aprendido haciendo decenas de reels)
- **Todo en movimiento continuo** (nada quieto más de ~1 s), pero con **aire**: elementos separados,
  nunca amontonados.
- Fondos simples (color de marca, puntos, degradado suave); 1–2 colores de acento.
- Texto grande, máx. 6–8 palabras por pantalla, tipografía de la marca.
- Subtítulos que saltan palabra por palabra, centrados en el tercio inferior (fuera de la zona de la
  interfaz de Instagram/TikTok: 250 px libres arriba y abajo).
- **Sello de marca chico y persistente** en una esquina (ej. «tumarca.com»).
- **Cierre de marca** de 2–3 s con logo + llamada a la acción + sonido corto.
- Transiciones consistentes (siempre la misma familia), curvas de aceleración suaves (`ease-out`).
- Un personaje o mascota animada (SVG) que «habla» con la voz ayuda mucho a la retención.

## HTML → video (sin Remotion)
```js
// grabar.mjs: abre la animación y captura N cuadros; la página expone window.seek(t) para ir al segundo t
import { chromium } from 'playwright';
const b = await chromium.launch({ args: ['--force_high_performance_gpu'] });
const p = await b.newPage({ viewport: { width: 1080, height: 1920 } });
await p.goto('http://localhost:5173/reel.html');
for (let f = 0; f < 30 * 30; f++) {           // 30 s a 30 fps
  await p.evaluate(t => window.seek(t), f / 30);
  await p.screenshot({ path: `frames/${String(f).padStart(5, '0')}.png` });
}
await b.close();
```
```powershell
ffmpeg -framerate 30 -i frames/%05d.png -i voz.mp3 -c:v h264_nvenc -pix_fmt yuv420p -c:a aac -shortest reel.mp4
```
(sin NVIDIA: `-c:v libx264 -crf 20`). Paralelizar en varias páginas para que sea rápido.

## Entrega
- MP4 1080×1920, H.264, AAC, < 60 s para reels (o lo que pida la plataforma).
- Portada (primer cuadro atractivo) y texto para la publicación (formato WhatsApp/Instagram).
- Guardar el proyecto (código, guion, voz) para poder hacer variantes después.
