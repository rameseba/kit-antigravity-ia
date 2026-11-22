---
trigger: model_decision
description: Leer SIEMPRE que el cliente, el negocio o el usuario esté en Venezuela - precios en bolívares y dólares, tasa BCV, IVA/IGTF, facturación SENIAT, RIF y cédula, teléfonos +58, estados y municipios, Pago Móvil, bancos, Zelle, Binance, Cashea, formularios, direcciones, conectividad y textos para venezolanos.
---

# Venezuela: contexto para webs, tiendas, POS y negocios

> Fuente principal: un POS/inventario multi-país en producción con comercios venezolanos (paquete
> `country-ve`, especificación §9) + investigación nov-2026. Todo lo normativo cambia seguido:
> lo marcado **[VERIFICAR]** se confirma con el contador del cliente o la Gaceta Oficial antes de
> prometerlo. Nunca inventar una norma, tasa o comisión.

## 1. Economía bimonetaria (lo más importante)
- **Moneda legal:** bolívar, `VES` (símbolo `Bs.`). Se usa a diario el **dólar** (`USD`, «$», «divisas»)
  como moneda de referencia; también euro y USDT. Historia de reconversiones: 2008 (Bs.F, −3 ceros),
  2018 (Bs.S, −5 ceros), oct-2021 (bolívar digital, −6 ceros). ISO también asignó `VED` en 2021, pero en
  sistemas y bancos se sigue viendo `VES`: aceptar ambos.
- **Precio base en USD, cobro en Bs a la tasa oficial del BCV.** Por la Ley de Precios Justos (Sundde)
  los precios en divisas son **referenciales**: se muestra «Ref. $ 25,00» y se cobra en bolívares a la
  tasa BCV del día. Mostrar SIEMPRE los dos montos:
  ```
  Ref. $ 25,00 · Bs. 21.784,22   (Tasa BCV 871,3689 · 21/11/2026)
  ```
- **Exigencias Sundde [VERIFICAR vigencia]:** cartel visible con la tasa del día, sin recargos por
  forma de pago (no cobrar más por pagar con tarjeta o Pago Móvil), vuelto exacto, margen de ganancia
  con tope sobre estructura de costos. En sistemas: el recargo por método debe venir **apagado** por
  defecto.
- **Tasa BCV:** el BCV **no tiene API oficial**. Publica en la tarde la tasa que rige el **día hábil
  siguiente**; sábado y domingo rige la del viernes (no marcarla «vencida»). Fuentes:
  1. `https://ve.dolarapi.com/v1/dolares/oficial` y `/v1/euros/oficial` (JSON).
  2. Lector propio de `bcv.org.ve` (scraping) o bcvapi.
  3. Carga manual con permiso de supervisor.
  Reglas que funcionaron: consultar 17:00, 18:30, 20:00 y 07:00 hora de Caracas; si dos fuentes
  difieren > 0,5 % o la tasa nueva cambia > 15 % respecto de la anterior, queda «por confirmar» (nunca
  activar sola). Guardar en cada venta/pedido **la tasa usada y su fecha valor**. Cachear la tasa
  (no llamar la API por cada visita: costo y caídas).
- **Tasa euro BCV:** algunos comercios cobran a la tasa euro. Que sea configurable.
- **Dólar paralelo / USDT:** cotiza sobre la tasa oficial (≈12 % arriba en oct-2026, varía). Es
  informativo; **no usar para precios públicos** sin advertencia legal. Sí sirve para reportes de
  reposición del dueño.
- **Dinero con decimales exactos:** nunca `float`. Usar decimal (`decimal.js`, `big.js`, `numeric` en
  Postgres) y redondear al final. Bs con 2 decimales; las tasas con 4 o más decimales.
- **Orden canónico al cobrar con varios medios:** el cálculo debe dar lo mismo sin importar el orden
  en que el cajero teclea los pagos (afecta IGTF y vuelto).

## 2. Formato de números, fechas y hora
- Miles con **punto** y decimales con **coma**: `Bs. 1.234.567,89`, `Ref. $ 85,00`.
  `new Intl.NumberFormat('es-VE', { minimumFractionDigits: 2, maximumFractionDigits: 2 })`.
- Fechas `dd/mm/aaaa`. Hora de 12 h con «a. m./p. m.» es lo habitual en textos.
- Zona horaria `America/Caracas`, **UTC−4 todo el año, sin horario de verano**. Ojo con cron en UTC
  (17:00 Caracas = 21:00 UTC).

## 3. Impuestos [VERIFICAR con contador]
| Impuesto | Valor de referencia | Notas |
|---|---|---|
| IVA general | 16 % | Hay alícuota reducida (8 %) para ciertos bienes y adicional para bienes de lujo; bienes exentos (canasta básica, medicinas, etc.) |
| IGTF | 3 % sobre pagos en **divisas o criptoactivos** | Lo **percibe solo el contribuyente especial** (agente de percepción). Un contribuyente ordinario no lo cobra. Pagos en Bs no llevan IGTF |
| ISLR | según régimen | Retenciones en pagos a proveedores |
- Guardar las tasas de impuesto como **datos con vigencia** (`valid_from`), nunca como constantes en el
  código.
- Contribuyentes especiales retienen IVA a sus proveedores (75 % o 100 %) [VERIFICAR].
- Ejemplo IGTF: cuenta de $ 85; el cliente paga $ 55 en efectivo USD → IGTF 3 % = $ 1,65 (solo si la
  empresa es agente de percepción).

## 4. Facturación (SENIAT) — estado nov-2026 [VERIFICAR]
- **Facturar sigue siendo obligatorio.** Un sistema propio (web, POS, panel) **no es factura fiscal**
  salvo que esté integrado con un medio autorizado.
- Medios válidos: **máquina fiscal homologada**, **imprenta digital autorizada** (API) o portal/app del
  SENIAT (gratis pero manual, sin API pública). Talonarios solo para contingencia.
- Providencia SNAT/2026/00093 (G.O. 43.484, 21-10-2026), plena vigencia **19-04-2027**: la máquina
  fiscal deja de ser obligatoria (libre elección entre los medios). SNAT/2026/00084 derogó la
  homologación de software de facturación (2024/000121). Ventas por web/redes: imprenta digital
  (SNAT/2024/000102).
- **Comprobante del sistema:** título «COMPROBANTE DE COMPRA» o «NOTA DE ENTREGA», con las leyendas
  `DOCUMENTO NO FISCAL – CONTROL INTERNO` y `NO VÁLIDO COMO FACTURA`. **Nunca el título «Factura».**
  Incluir: razón social, RIF, n.º correlativo, fecha · caja · vendedor, líneas con «Ref. $» y «Bs.»,
  total en Bs y Ref. USD, tasa BCV y fecha valor, pagos con referencia, vuelto, campo para n.º de
  factura fiscal si se emitió aparte, política de cambios. Ticket de 80 mm = 42 columnas.
- Integración con imprenta digital: por **API REST** (ej. Unidigital: login → JWT → crear y aprobar
  documento; notas de crédito con documento afectado; lotes para ventas sin conexión). Cada comercio
  contrata su imprenta con su RIF. No prometer factura fiscal sin esa integración.
- Para el contador: exportar «auxiliar de ventas» (no «libro oficial») en XLSX/CSV con n.º interno,
  n.º fiscal, tasa, total USD y Bs, IVA, IGTF, resumen por medio de pago y diferencial cambiario.

## 5. Identificación: RIF y cédula
- **Cédula:** `V-12.345.678` (venezolano) o `E-81.234.567` (extranjero residente). Aceptar con o sin
  puntos y guion; guardar normalizado (`V12345678`). Mostrar con puntos.
- **RIF:** letra + 8 dígitos + dígito verificador: `J-12345678-9`.
  Letras: `V` persona natural, `E` extranjero, `J` jurídica (empresa), `G` gobierno, `P` pasaporte,
  `C` consejo comunal.
  ```js
  const RIF_RE = /^([VEJPGC])-?(\d{8})-?(\d)$/i;          // quitar espacios y puntos antes
  const VAL = { V:1, E:2, J:3, P:4, G:5, C:3 }, W = [3,2,7,6,5,4,3,2];
  function rifCheckDigit(l, d8) { let s = VAL[l.toUpperCase()] * 4;
    for (let i = 0; i < 8; i++) s += +d8[i] * W[i];
    const r = 11 - (s % 11); return String(r >= 10 ? 0 : r); }
  ```
  Si el dígito no coincide, **advertir, no bloquear** (hay RIF reales que fallan el cálculo; validar
  con RIF reales del cliente).
- Campo de formulario: «Cédula o RIF» con placeholder `V-12.345.678`.

## 6. Teléfonos (+58)
- **Móviles** (10 dígitos después del 0): Digitel **0412 / 0422** (0422 desde jul-2025), Movistar
  **0414 / 0424**, Movilnet **0416 / 0426**.
- **Fijos:** `02xx` + 7 dígitos. Ej.: 0212 Caracas, 0241 Valencia, 0243 Maracay, 0251 Barquisimeto,
  0261 Maracaibo, 0274 Mérida, 0276 San Cristóbal, 0281 Barcelona/Puerto La Cruz, 0286 Ciudad
  Guayana, 0291 Maturín, 0295 Margarita.
- **Entradas que hay que aceptar** (todas son el mismo número):
  `04141234567`, `0414-1234567`, `0414 123 4567`, `0414-123.45.67`, `414-123.45.67`,
  `+58 414 1234567`, `+58 0414-1234567` (el 0 sobra), `584141234567`, `+58-414-123-4567`.
- **Normalizar:** quitar todo lo que no sea dígito; quitar `58` inicial; quitar el `0` inicial → 10
  dígitos. Validar: `/^(412|414|416|422|424|426|2\d{2})\d{7}$/`.
  Guardar E.164 `+584141234567`; mostrar `0414-1234567` (local) o `+58 414-1234567` (internacional).
- **WhatsApp:** `https://wa.me/584141234567` (sin +, sin 0). Casi todos los clientes escriben por
  WhatsApp; el botón flotante es obligatorio en webs de servicios.
- Selector de país en el teléfono con 🇻🇪 +58 por defecto (hay mucha diáspora: aceptar otros países).

## 7. Territorio y direcciones
- **23 estados + Distrito Capital + Dependencias Federales.** ~335 municipios y ~1.100 parroquias
  [VERIFICAR cifras exactas]. Formularios: selector **Estado → Municipio** (y parroquia si hace falta
  para delivery). No usar «comunas» ni «regiones» (eso es Chile).
- Estados (capital): Amazonas (Puerto Ayacucho), Anzoátegui (Barcelona), Apure (San Fernando de
  Apure), Aragua (Maracay), Barinas (Barinas), Bolívar (Ciudad Bolívar), Carabobo (Valencia),
  Cojedes (San Carlos), Delta Amacuro (Tucupita), Falcón (Coro), Guárico (San Juan de los Morros),
  La Guaira (La Guaira; antes «Vargas»), Lara (Barquisimeto), Mérida (Mérida), Miranda (Los
  Teques), Monagas (Maturín), Nueva Esparta (La Asunción), Portuguesa (Guanare), Sucre (Cumaná),
  Táchira (San Cristóbal), Trujillo (Trujillo), Yaracuy (San Felipe), Zulia (Maracaibo) + Distrito
  Capital (Caracas).
- Caracas abarca el Distrito Capital (Libertador) y municipios de Miranda (Chacao, Baruta, Sucre,
  El Hatillo): al pedir dirección en «Caracas», ofrecer esos municipios.
- **Dirección venezolana:** urbanización/sector, calle o avenida, edificio/quinta/casa, piso y
  apartamento, **punto de referencia** (clave: «frente a la panadería X»), municipio, estado. El código
  postal (zona postal de 4 dígitos, ej. 1060) casi no se usa: opcional.
- Delivery: zonas por municipio/urbanización con tarifa en $; motorizados; coordinar por WhatsApp.

## 8. Medios de pago (lista base editable)
| Medio | Moneda | Referencia | ¿Vuelto? | IGTF* |
|---|---|---|---|---|
| Efectivo Bs | VES | no | sí | no |
| Efectivo USD | USD | no | sí (en $, Bs o Pago Móvil) | sí |
| Efectivo EUR | EUR | no | no | sí |
| Punto de venta débito / crédito | VES | lote/ref. | no | no |
| **Pago Móvil** | VES | referencia | sí (vuelto por Pago Móvil) | no |
| Transferencia Bs | VES | referencia | no | no |
| **Zelle** | USD | referencia + titular | no | sí [VERIFICAR] |
| **Binance / USDT** | USDT (≈ USD a la par) | ID de orden | no | sí |
| **Cashea** (compra ahora, paga después) | USD | n.º de orden | no | no |
| Nota de crédito / tarjeta de regalo | USD | código | no | no |
| Fiado (crédito al cliente) | USD | no | no | no |
*IGTF solo si la empresa es agente de percepción.

- **Pago Móvil:** el cliente necesita **banco (código), teléfono y cédula/RIF** del comercio. Mostrar
  esos datos + el **monto exacto en Bs** (con botón para copiar cada dato). El pago queda «por
  verificar» hasta que el comercio lo confirma en su banco; pedir la **referencia** (últimos dígitos) y
  opcionalmente captura del comprobante.
- **Cuenta bancaria:** 20 dígitos; los **primeros 4 son el código del banco**.
- **Códigos de banco frecuentes:** 0102 Banco de Venezuela · 0104 Venezolano de Crédito · 0105
  Mercantil · 0108 Provincial (BBVA) · 0114 Bancaribe · 0115 Exterior · 0128 Caroní · 0134 Banesco ·
  0137 Sofitasa · 0138 Plaza · 0151 BFC Fondo Común · 0156 100% Banco · 0157 Del Sur · 0163 Tesoro ·
  0166 Agrícola · 0168 Bancrecer · 0169 R4 / Mi Banco · 0171 Activo · 0172 Bancamiga · 0174 Banplus ·
  0175 Bicentenario · 0177 Banfanb · 0191 BNC [VERIFICAR lista vigente con SUDEBAN].
- **Cashea:** el cliente paga una inicial en la tienda y el resto en cuotas a la app; Cashea le paga al
  comercio lo financiado menos comisión. Registrar una cuenta por cobrar a Cashea y conciliar sus
  liquidaciones. Comisiones según contrato del comercio [VERIFICAR].
- **Cobro en línea en una web:** Stripe/PayPal no sirven para cobrar a comercios venezolanos. Lo
  habitual: (1) pedido por web → **pago por Pago Móvil/Zelle/Binance con referencia o captura** →
  verificación manual o por API del banco; (2) botones/APIs de pago de bancos locales y pasarelas
  locales (Mercantil, Banesco, R4/Mi Banco con C2P «cobro a persona», Ubii, etc.) [VERIFICAR
  disponibilidad, requisitos y costos por cliente]. Nunca guardar datos de tarjetas.
- El **vuelto** casi siempre se da en Bs o por Pago Móvil (escasea el sencillo en dólares): el
  sistema debe permitir vuelto en otra moneda y registrarlo.

## 9. Webs y tiendas para Venezuela
- **Internet móvil lento y datos caros, cortes de luz:** páginas livianas (imágenes AVIF/WebP chicas,
  pocas fuentes, sin videos de fondo), carga rápida en 3G/4G. Para POS/paneles: **funcionar sin
  conexión** y sincronizar después (ventas offline con número propio por dispositivo).
- Mostrar precios en $ y Bs (tasa del día, actualizada sola) y un aviso «Precios referenciales en
  dólares; se pagan en bolívares a la tasa BCV del día».
- Catálogo + pedido por WhatsApp suele convertir mejor que un checkout largo. Mensaje prellenado con
  productos, total en $ y Bs, nombre y dirección.
- Sección «Formas de pago» con logos/nombres: Pago Móvil, transferencia, Zelle, Binance, efectivo
  en divisas, Cashea si aplica.
- Horarios y «hacemos delivery en…» (municipios) visibles. Google Business Profile e Instagram son
  los canales principales de descubrimiento.
- Textos: español venezolano natural y respetuoso. Palabras locales correctas: «celular», «delivery»,
  «Pago Móvil», «punto de venta», «divisas», «tasa del día», «motorizado», «urbanización». Evitar
  chilenismos («comuna», «boleta», «RUT», «$» refiriéndose a pesos). Trato de «tú» en marcas jóvenes y
  de «usted» en salud, legal y servicios formales.

## 10. Trabajar desde Venezuela (para el desarrollador)
- Algunas rutas internacionales van lentas en ciertos proveedores (GitHub, descargas de winget/npm)
  aunque el test de velocidad local dé bien. Probar con speed.cloudflare.com; **Cloudflare WARP**
  (gratis) suele arreglar la ruta. winget: usar descargador `wininet`
  (`settings.json` → `"network": { "downloader": "wininet" }`).
- Pagar servicios en el exterior (dominios, Cloudflare, Meta Ads) requiere tarjeta internacional:
  usar billeteras/tarjetas en dólares que acepten pagos en línea [VERIFICAR cuál funciona hoy].
  Preferir siempre los planes gratuitos.
- Cobrarle a clientes: precios en $ referenciales, cobro en $ (Zelle/Binance/efectivo) o en Bs a la
  tasa BCV del día de pago. Dejarlo escrito en la propuesta.

## 11. Organismos y trámites
- **SENIAT** (impuestos y facturación) · **Sundde** (precios) · **BCV** (tasa oficial) · **SUDEBAN**
  (bancos) · **CONATEL** (telecomunicaciones) · **SAREN** (registros y notarías) · **SAIME** (cédulas y
  pasaportes).
- **Documentos para notaría (SAREN en línea):** texto **corrido** (sin espacios entre párrafos, sin
  títulos ni «PRIMERO/SEGUNDO»: subtítulos en negrita dentro del texto seguidos de «:»), **sin
  membrete, sin «Atentamente» ni línea de firma** (se firma ante el notario), cerrar con «En [ciudad],
  Estado [estado], a la fecha de su presentación.». El visado de abogado lo pone el abogado.
  Escaneos de cédula nítidos, tamaño original, PDF ≤ 2 MB. Si alguien mencionado es mayor de edad, se
  pide también su cédula. Allá son exigentes: investigar el formato antes de redactar.

## 12. Ejemplo numérico de referencia (usar como prueba en sistemas de cobro)
Tasa 871,3689 Bs/USD, empresa sin IVA desglosado y no agente de IGTF.
Camisa 25,00 + Jean 45,00 + Franela 15,00 = **USD 85,00 = Bs. 74.066,36**.
Pagos: Pago Móvil Bs. 17.427,38 (= $ 20) + Punto débito Bs. 8.713,69 (= $ 10) + Efectivo $ 60 (aplica
$ 55) → vuelto por Pago Móvil Bs. −4.356,84 (= $ 5).
- Con IVA incluido 16 % (calculado sobre el documento, no por línea): base Bs. 63.850,31 + IVA
  Bs. 10.216,05. Por línea daría 73,27 + 11,73 en $: es el error a evitar.
- Si es agente de IGTF: IGTF sobre los $ 55 en efectivo = $ 1,65; vuelto $ 3,35 = Bs. 2.919,09; total
  cobrado $ 86,65. Debe dar igual aunque los pagos se tecleen en otro orden.
- Devolución 10 días después con tasa 900,00: se devuelven $ 25 = Bs. 22.500,00; la diferencia contra
  la tasa original (Bs. 715,78) se registra como diferencial cambiario.

Más detalle técnico (modelo de datos, código del paquete de país): skill `cerebro`,
`reference/venezuela-pos-spec.md` y `reference/venezuela-country-ve.ts`.
