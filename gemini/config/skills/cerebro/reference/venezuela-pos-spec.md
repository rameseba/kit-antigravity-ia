# Venezuela en un POS real (extracto de la especificación, §9)
> Fuente: especificación maestra de un POS/inventario multi-país en producción. Todo lo normativo: [VERIFICAR] con contador.

### 9.1 Marco normativo investigado (octubre 2026) — todo [VERIFICAR] con contador

| Norma | Efecto en el producto |
|---|---|
| Providencia SNAT/2011/0071 (normas generales de facturación) | Define quién debe usar máquina fiscal; una tienda de ropa al detal normalmente queda obligada |
| Providencia SNAT/2018/0141 | Regula máquinas fiscales; distingue documentos fiscales de comprobantes no fiscales |
| Providencia SNAT/2024/000102 | Ventas por medios electrónicos (web, redes) se facturan por imprenta digital autorizada |
| Providencia SNAT/2026/00084 (Gaceta 43.435, 12 de agosto de 2026) — **verificada** (Moore Venezuela, Victum Legal) | Derogó expresamente la Providencia SNAT/2024/000121 (autorización previa y homologación de proveedores de software de facturación). El POS puede operar como sistema de gestión; la validez fiscal viene de la máquina fiscal o la imprenta digital. Las obligaciones de facturar (0071, 0141, 000102) siguen vigentes |
| Ley de IVA | Alícuota general 16% (en `tax_rates`, con vigencia) |
| IGTF | 3% sobre pagos en divisas o criptoactivos; lo percibe solo el contribuyente especial. Un contribuyente ordinario no lo cobra |
| Sundde / Ley de Precios Justos | Precios en divisas son referenciales; se cobra en Bs a la tasa BCV; cartel con la tasa del día; sin recargos por forma de pago; vuelto exacto; tope de ganancia sobre estructura de costos |

### 9.2 Configuración por defecto de una empresa venezolana

| Parámetro | Valor por defecto | Dónde |
|---|---|---|
| Moneda base / legal | USD / VES | CountryConfig + tenant_settings |
| Modo de impuestos | `none` (precio final) | companies.tax_mode |
| Política fiscal | `external_manual` | companies.fiscal_document_policy |
| Agente de percepción IGTF | no | companies.fiscal_settings.igtfAgent |
| Tasa para convertir precios | oficial BCV | flags.fx |
| Recargos por método | prohibidos | flags.pos.allowMethodSurcharge = false |

### 9.3 Tasas

- El BCV no tiene API oficial. Publica en la tarde la tasa que rige al día hábil siguiente.
- **Fuente 1:** ve.dolarapi.com (`/v1/dolares/oficial`, `/v1/euros/oficial`). **Fuente 2:** lector propio de bcv.org.ve o bcvapi. **Fuente 3:** carga manual con permiso `fx.manual_rate`.
- Job a las 17:00, 18:30, 20:00 y 07:00 (hora de Caracas = 21:00, 22:30, 00:00 y 11:00 UTC; Venezuela no tiene horario de verano) con `pg_cron`, que trabaja en UTC. Si las dos fuentes difieren más de `fx.maxSourceDivergencePct` (0,5%), la tasa queda `candidate` y se pide confirmación. Si solo responde una fuente, queda `candidate` igual (nunca se activa una tasa sin segunda opinión o sin confirmación humana). Una tasa nueva que difiere más de 15% de la anterior también queda `candidate` (protege contra un error de lectura de la página del BCV).
- **Tasa efectiva** de un día = la activa con mayor `valid_for_date <= ese día` (§6.6). Ejemplo: el viernes en la tarde el BCV publica la del lunes; sábado y domingo usan la que rige el viernes, y **no** se marcan vencidas. **[VERIFICAR con contador]** si el comercio debe usar la publicada el viernes desde el sábado.
- Tasa vencida (más antigua que el último día hábil): según `fx.staleRatePolicy` se bloquea, se pide PIN de supervisor o se permite marcando `rate_stale`.
- El cartel con la tasa del día (exigido por la Sundde) se genera desde el sistema: pantalla `/cartel-tasa` imprimible.
- USDT se trata como USD a la par (`fx.usdtParValue`). El precio de mercado del USDT es solo informativo. Como referencia, a inicios de octubre de 2026 estaba cerca de 12% sobre la tasa BCV: quien paga en bolívares a tasa oficial paga menos en términos reales. El reporte "valor real por medio de pago" se lo muestra al dueño.
- Tasa interna del negocio: solo para reportes de reposición. Usarla para precios está bloqueado salvo flag con advertencia legal.

### 9.4 Medios de pago (semilla editable)

| Código | Nombre | Tipo | Moneda | IGTF si aplica | Referencia | Vuelto | En gaveta |
|---|---|---|---|---|---|---|---|
| cash_ves | Efectivo Bs | cash | VES | no | no | sí | sí |
| cash_usd | Efectivo USD | cash | USD | sí | no | sí | sí |
| cash_eur | Efectivo EUR | cash | EUR | sí | no | no | sí |
| pos_debit | Punto de venta débito | card_debit | VES | no | lote/ref. | no | no |
| pos_credit | Punto de venta crédito | card_credit | VES | no | lote/ref. | no | no |
| pago_movil | Pago Móvil | mobile_payment | VES | no | sí | sí (saliente) | no |
| transfer_ves | Transferencia Bs | bank_transfer | VES | no | sí | no | no |
| zelle | Zelle | foreign_transfer | USD | sí [VERIFICAR] | sí + titular | no | no |
| usdt | Binance / USDT | crypto | USDT | sí | ID de orden | no | no |
| cashea | Cashea (financiado) | bnpl | USD | no | n.º de orden | no | no |
| store_credit | Nota de crédito interna | store_credit | USD | no | código | no | no |
| account | Fiado | account_credit | USD | no | no | no | no |

- **Pago Móvil (cobro):** muestra los datos de la cuenta de la sucursal y el monto exacto en Bs; queda "por verificar" hasta que el cajero lo confirma en su banco.
- **Pago Móvil (vuelto):** pago negativo con referencia.
- El IGTF solo se calcula si la empresa es agente de percepción **y** el método lo tiene marcado.

### 9.5 Financiamiento tipo Cashea

El cliente paga una inicial en la tienda y el resto en cuotas a la aplicación; esta le adelanta al comercio lo financiado y cobra comisiones. Las condiciones dependen del contrato de cada comercio **[VERIFICAR]**.

- Método de pago tipo `bnpl`: crea una cuenta por cobrar al proveedor (`bnpl_receivables`) con lo financiado, la comisión esperada y el neto esperado.
- La venta cuenta el ingreso completo; las comisiones van a gastos financieros.
- La liquidación periódica (`bnpl_settlements`) se concilia contra las cuentas abiertas; la diferencia queda registrada.
- Ejemplo: prenda de 100, inicial 60 por Pago Móvil, financiado 40. Con comisiones de ejemplo de 5% sobre la venta y 3% sobre lo financiado: 5,00 + 1,20 = 6,20; neto esperado 33,80.

### 9.6 Ejemplo numérico de referencia (prueba obligatoria)

Tasa 871,3689 Bs/USD. Empresa en modo `none`, no agente de IGTF.

| Línea | Precio |
|---|---|
| Camisa, M, azul | 25,00 |
| Jean, talla 44 (base 40 + 5 por talla grande) | 45,00 |
| Franela, S, blanca | 15,00 |
| **Total** | **USD 85,00 = Bs. 74.066,36** |

| Pago | Moneda | Entregado | Aplicado USD | Equivalente Bs |
|---|---|---|---|---|
| Pago Móvil | VES | 17.427,38 | 20,00 | 17.427,38 |
| Punto de venta débito | VES | 8.713,69 | 10,00 | 8.713,69 |
| Efectivo USD | USD | 60,00 | 55,00 | 47.925,29 |
| **Total aplicado** | | | **85,00** | **74.066,36** |
| Vuelto por Pago Móvil | VES | −4.356,84 | −5,00 | −4.356,84 |

Registros: 1 venta, 3 líneas, 4 pagos (3 cobros + 1 vuelto), 3 movimientos de stock.

- **Variante A, modo `included` al 16%:** en USD, base 73,28 e impuesto 11,72. En Bs: **base 63.850,31 e impuesto 10.216,05** (suman 74.066,36). El cliente paga lo mismo.
- **Regresión de la variante A:** el impuesto se calcula sobre el documento (§7.8). Calcularlo línea por línea da base 73,27 e IVA 11,73: **es la prueba de regresión** de que nadie volvió al cálculo por línea.
- **Variante B, empresa agente de IGTF:** sobre los 55,00 pagados en efectivo USD, IGTF 3% = 1,65. Con 60 entregados: vuelto 3,35 = Bs. 2.919,09. Total cobrado 86,65.
- **Variante C, mismo cobro tecleado en otro orden** (efectivo USD primero, luego Pago Móvil y punto): el resultado debe ser idéntico a B (IGTF 1,65, vuelto 3,35). Sin el orden canónico de §7.9 da IGTF 1,7476.
- **Variante D, todo en Bs por Pago Móvil por el monto exacto mostrado (74.066,36):** la venta queda saldada, sin "debe 0,00"; con 74.066,34 queda saldo pendiente de 0,02 (§7.9).
- **Variante E, devolución de la camisa 10 días después con tasa 900,00:** con `refundRatePolicy = 'current'` se devuelven USD 25,00 = Bs. 22.500,00; la diferencia contra Bs. 21.784,22 (tasa original) se registra en `fx_differences` (715,78 Bs). El movimiento `sale_return` usa el costo congelado de la línea original.

### 9.7 Comprobante y convivencia con lo fiscal

Comprobante del sistema (cuando no hay adaptador fiscal integrado). Leyendas editables por país **[VERIFICAR redacción]**:

```
{empresa}  RIF {rif}
{nombre comercial} – {dirección}
NOTA DE ENTREGA N.º {correlativo interno | {dispositivo}-{n.º} si se emitió sin conexión}
DOCUMENTO NO FISCAL – CONTROL INTERNO
NO VÁLIDO COMO FACTURA
Fecha · Caja · Vendedor(a)
{cantidad} x {producto} {talla}/{color}     Ref. $ {precio}   Bs. {línea}
TOTAL Bs. {total}      Ref. USD {total}
Tasa BCV: Bs. {tasa} por USD (fecha valor {fecha})
Pagos: {método} {moneda} {monto} Ref. {referencia}
Vuelto: {moneda} {monto} {método}
[si existe] Factura fiscal N.º {número}
Cambios: {política del local}
```

Nunca lleva la palabra "Factura" como título.

| Política fiscal de la empresa | Comportamiento |
|---|---|
| `none` | No pide documento fiscal. Aviso permanente: el cumplimiento queda a cargo del comercio |
| `external_manual` (por defecto) | Tras cobrar muestra el total y los pagos para emitir en la máquina fiscal, con campo para el número de factura. Reporte diario: ventas sin número fiscal |
| `integrated` (fase posterior) | Envía la venta a la impresora fiscal mediante el agente local |
| `provider_api` (fase posterior) | Para ventas por redes o web: llama a la imprenta digital |

**El modo sin impuestos es una herramienta de gestión.** No exime de facturar ni de declarar; el cumplimiento queda en manos del comercio y su contador.

### 9.8 Paquete para el contador (por empresa y mes; XLSX y CSV)

- Auxiliar de ventas: fecha, n.º interno, n.º fiscal, cliente, canal, total USD, tasa, total Bs, base e impuesto si el modo no es `none`, IGTF.
- Resumen diario por medio de pago y moneda, con comisiones.
- Ventas que requieren documento fiscal y no tienen número.
- Devoluciones y notas de crédito internas.
- Compras con datos del proveedor.
- Gastos por categoría.
- Obsequios y uso interno a costo.
- Inventario valorizado al cierre.
- Diferencial cambiario.

Se llama "auxiliar" para no confundirlo con el libro oficial.

