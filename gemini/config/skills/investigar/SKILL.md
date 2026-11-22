---
name: investigar
description: Método para investigar antes de hacer o cotizar algo - estudio de mercado de un rubro (20 sitios nacionales + 10 mundiales), competencia, precios del mercado, tendencias de diseño, herramientas o librerías, normas y datos que cambian. Usar cuando el usuario diga "investiga", "averigua", "qué hace la competencia", "estudio de mercado", "cuánto se cobra por...", "qué es mejor...", o antes de una propuesta o un diseño nuevo.
---

# Investigar bien (y rápido)

## Principios
1. **Primero la pregunta exacta.** Escribir en una línea qué se quiere saber y para qué decisión.
2. **Fuentes primarias > blogs.** Sitio oficial, documentación, Gaceta/organismo, la web del
   competidor, precios publicados. Blogs y foros solo para pistas.
3. **Fecha siempre.** Anotar cuándo se publicó cada dato; lo de hace más de 1 año en temas que
   cambian (precios, normas, tasas, APIs) se marca «[VERIFICAR]».
4. **Dos fuentes para datos críticos** (precios, normas, impuestos). Si no hay dos, decirlo.
5. **Nunca inventar** un dato, cifra, cliente o cita. «No lo encontré» es una respuesta válida.
6. **Resumen accionable:** terminar con «qué haría yo con esto» en 3–5 puntos.

## Herramientas en Antigravity
- **Búsqueda web** del agente para encontrar fuentes.
- **Navegador integrado** para abrir cada sitio, recorrerlo y sacar **capturas** (móvil y escritorio).
- Para muchos sitios: script con Playwright (`npx playwright`) que abre la lista y guarda capturas
  y datos (título, secciones, precios visibles) en una carpeta `estudio/`.

## A. Estudio de mercado de un rubro (para propuestas y diseños)
1. Lista: **~20 sitios del país** (Google: «<rubro> <ciudad>», Google Maps, Instagram del rubro) +
   **~10 del mundo** (los mejores del rubro, Awwwards, sitios premiados).
2. Por cada sitio, una fila: URL · qué hacen bien · qué hacen mal · estilo visual · secciones ·
   cómo venden (WhatsApp, formulario, carrito) · precios si los muestran · velocidad en móvil ·
   SEO (título, descripción, aparece en Google Maps) · captura.
3. Conclusiones: patrones que se repiten (lo que el cliente espera ver), huecos que nadie cubre
   (oportunidad), 3 referencias visuales a seguir.
4. Publicarlo como página `/estudio/` dentro de la propuesta (respalda la versión B «wow»).
Método completo y ejemplo: `cerebro/reference/estudio-mercado-propuestas.md`.

## B. Precios del mercado (para cotizar)
- Buscar lo que cobran freelancers y agencias locales por lo mismo (webs, Instagram, Workana,
  grupos de Facebook, Marketplace), en $ y en moneda local.
- Separar por paquete: landing de una página / web completa / web con panel / tienda / mantención
  mensual / publicidad aparte.
- Resultado: tabla mínimo–típico–alto y recomendación de dónde ubicarse (y por qué). Usar la skill
  `analista-precios` para el análisis de sensibilidad.

## C. Técnica (librería, servicio, API)
- Documentación oficial y su fecha; versión actual (`npm view <paquete> version`).
- Límites del plan gratuito y precio al pasarse.
- Ejemplo mínimo que funcione antes de recomendarlo.
- Alternativas (2) y por qué se elige una.

## D. Normas, impuestos y trámites
- Ir al organismo (SENIAT, BCV, Sundde, etc.) o la Gaceta. Citar número de providencia/ley y fecha.
- Marcar todo como «[VERIFICAR con contador/abogado]» antes de que el cliente lo use.

## Entrega
Un archivo `investigacion-<tema>.md` (o la página `/estudio/`) con: pregunta, fecha, fuentes con
link, hallazgos en tabla, conclusiones y próximos pasos. Avisar en una línea dónde quedó.
