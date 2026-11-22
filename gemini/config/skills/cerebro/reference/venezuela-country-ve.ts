// Venezuela (spec §9). Todo lo normativo es dato con vigencia en country_settings/tax_rates;
// aquí solo hay valores por defecto para sembrar y reglas que los interpretan.
import { buildFlags, d, type Dec, type TenantFlags } from '@pos/domain';

export const VE = {
  code: 'VE',
  legalCurrency: 'VES',
  defaultBaseCurrency: 'USD',
  currencies: ['VES', 'USD', 'EUR', 'USDT'],
  moneyDecimals: { VES: 2, USD: 2, EUR: 2, USDT: 2 } as Readonly<Record<string, number>>,
  timezone: 'America/Caracas',
  taxIdLabel: 'RIF',
  defaultTaxMode: 'none' as const,
  defaultFiscalDocumentPolicy: 'external_manual' as const,
  legalRateSource: 'BCV',
} as const;

// ───────────── RIF ─────────────
const RIF_RE = /^([VEJPGC])-?(\d{8})-?(\d)$/i;
const LETTER_VALUE: Record<string, number> = { V: 1, E: 2, J: 3, P: 4, G: 5, C: 3 };
const WEIGHTS = [3, 2, 7, 6, 5, 4, 3, 2];

/** Normaliza a "J-12345678-9". Devuelve null si el formato no corresponde. */
export function normalizeRif(raw: string): string | null {
  const m = RIF_RE.exec(raw.replace(/[\s.]/g, ''));
  if (!m) return null;
  return `${m[1]!.toUpperCase()}-${m[2]}-${m[3]}`;
}

/**
 * Dígito verificador (módulo 11, peso 4 para la letra). [VERIFICAR con RIF reales del cliente]:
 * por eso un dígito que no coincide se informa como advertencia, no bloquea.
 */
export function rifCheckDigit(letter: string, digits8: string): string {
  let s = (LETTER_VALUE[letter.toUpperCase()] ?? 0) * 4;
  for (let i = 0; i < 8; i++) s += Number(digits8[i]) * WEIGHTS[i]!;
  const r = 11 - (s % 11);
  return String(r >= 10 ? 0 : r);
}

export function validateRif(raw: string): { ok: boolean; normalized: string | null; warning?: 'CHECK_DIGIT' } {
  const n = normalizeRif(raw);
  if (!n) return { ok: false, normalized: null };
  const [letter, digits, check] = n.split('-') as [string, string, string];
  return rifCheckDigit(letter, digits) === check ? { ok: true, normalized: n } : { ok: true, normalized: n, warning: 'CHECK_DIGIT' };
}

// ───────────── Medios de pago (semilla editable, §9.4) ─────────────
export interface PaymentMethodSeed {
  code: string; name: string;
  kind: 'cash' | 'card_debit' | 'card_credit' | 'bank_transfer' | 'mobile_payment' | 'foreign_transfer'
    | 'crypto' | 'bnpl' | 'store_credit' | 'account_credit';
  currency: string; surchargeTaxCode: 'IGTF' | null;
  requiresReference: boolean; referenceLabel: string | null;
  allowsChange: boolean; countsInDrawer: boolean; sortOrder: number;
}
export const PAYMENT_METHODS_VE: readonly PaymentMethodSeed[] = [
  { code: 'cash_ves', name: 'Efectivo Bs', kind: 'cash', currency: 'VES', surchargeTaxCode: null, requiresReference: false, referenceLabel: null, allowsChange: true, countsInDrawer: true, sortOrder: 10 },
  { code: 'cash_usd', name: 'Efectivo USD', kind: 'cash', currency: 'USD', surchargeTaxCode: 'IGTF', requiresReference: false, referenceLabel: null, allowsChange: true, countsInDrawer: true, sortOrder: 20 },
  { code: 'cash_eur', name: 'Efectivo EUR', kind: 'cash', currency: 'EUR', surchargeTaxCode: 'IGTF', requiresReference: false, referenceLabel: null, allowsChange: false, countsInDrawer: true, sortOrder: 30 },
  { code: 'pos_debit', name: 'Punto de venta débito', kind: 'card_debit', currency: 'VES', surchargeTaxCode: null, requiresReference: true, referenceLabel: 'Lote / referencia', allowsChange: false, countsInDrawer: false, sortOrder: 40 },
  { code: 'pos_credit', name: 'Punto de venta crédito', kind: 'card_credit', currency: 'VES', surchargeTaxCode: null, requiresReference: true, referenceLabel: 'Lote / referencia', allowsChange: false, countsInDrawer: false, sortOrder: 50 },
  { code: 'pago_movil', name: 'Pago Móvil', kind: 'mobile_payment', currency: 'VES', surchargeTaxCode: null, requiresReference: true, referenceLabel: 'Referencia', allowsChange: true, countsInDrawer: false, sortOrder: 60 },
  { code: 'transfer_ves', name: 'Transferencia Bs', kind: 'bank_transfer', currency: 'VES', surchargeTaxCode: null, requiresReference: true, referenceLabel: 'Referencia', allowsChange: false, countsInDrawer: false, sortOrder: 70 },
  { code: 'zelle', name: 'Zelle', kind: 'foreign_transfer', currency: 'USD', surchargeTaxCode: 'IGTF', requiresReference: true, referenceLabel: 'Referencia y titular', allowsChange: false, countsInDrawer: false, sortOrder: 80 },
  { code: 'usdt', name: 'Binance / USDT', kind: 'crypto', currency: 'USDT', surchargeTaxCode: 'IGTF', requiresReference: true, referenceLabel: 'ID de orden', allowsChange: false, countsInDrawer: false, sortOrder: 90 },
  { code: 'cashea', name: 'Cashea (financiado)', kind: 'bnpl', currency: 'USD', surchargeTaxCode: null, requiresReference: true, referenceLabel: 'N.º de orden', allowsChange: false, countsInDrawer: false, sortOrder: 100 },
  { code: 'store_credit', name: 'Nota de crédito interna', kind: 'store_credit', currency: 'USD', surchargeTaxCode: null, requiresReference: true, referenceLabel: 'Código', allowsChange: false, countsInDrawer: false, sortOrder: 110 },
  { code: 'account', name: 'Fiado', kind: 'account_credit', currency: 'USD', surchargeTaxCode: null, requiresReference: false, referenceLabel: null, allowsChange: false, countsInDrawer: false, sortOrder: 120 },
];

// ───────────── IGTF (§9.1, §9.4) ─────────────
export interface CompanyFiscal { igtfAgent: boolean }
/**
 * Recargo de un medio de pago. Solo si la empresa es agente de percepción Y el método está marcado.
 * `igtfRate` sale de tax_rates (código 'IGTF', vigente a la fecha), nunca de una constante.
 */
export function surchargeRate(company: CompanyFiscal, method: { surchargeTaxCode: string | null }, igtfRate: Dec | null): Dec {
  if (!company.igtfAgent || method.surchargeTaxCode !== 'IGTF') return d(0);
  if (igtfRate === null) throw new Error('IGTF_RATE_MISSING');
  return igtfRate;
}

// ───────────── Valores normativos para sembrar country_settings / tax_rates ─────────────
export const VE_TAX_RATES_SEED = [
  { code: 'VAT_GENERAL', kind: 'vat', rate: '0.16', validFrom: '2016-01-01', sourceNote: 'Ley de IVA, alícuota general [VERIFICAR vigencia]' },
  { code: 'EXEMPT', kind: 'vat', rate: '0', validFrom: '2000-01-01', sourceNote: 'Exento' },
  { code: 'IGTF', kind: 'payment_surcharge', rate: '0.03', validFrom: '2022-03-28', sourceNote: 'Ley IGTF reformada 2022 [VERIFICAR]' },
] as const;

export const VE_RECEIPT_LEGENDS = {
  // 1.106 (Dēstroit 03-11): «Comprobante de compra». Nunca «Factura»: sin máquina fiscal no lo es (SENIAT).
  title: 'COMPROBANTE DE COMPRA',
  nonFiscal: ['DOCUMENTO NO FISCAL – CONTROL INTERNO', 'NO VÁLIDO COMO FACTURA'],
  noFiscalDocumentPolicy: 'El cumplimiento fiscal queda a cargo del comercio.',
} as const;

// ───────────── Comprobante no fiscal (§9.7) ─────────────
export interface ReceiptData {
  companyLegalName: string; rif: string; displayName: string; address: string;
  number: string; offline: boolean;
  date: string; register: string; seller: string;
  lines: { qty: string; description: string; refUsd: string; bs: string }[];
  totalBs: string; totalUsd: string; rate: string; rateDate: string;
  /** Cobrada a la tasa euro BCV (flags.fx.bsPricing.useEuroRate, 1.31): «Tasa euro BCV» en vez de «Tasa BCV». */
  rateEuro?: boolean;
  payments: { method: string; currency: string; amount: string; reference?: string }[];
  change?: { method: string; currency: string; amount: string };
  /** Vuelto que el cliente dejó (no se entregó): queda escrito para que la nota cuadre con lo cobrado. */
  changeKept?: { currency: string; amount: string };
  /** IGTF cobrado por los pagos en divisas (Bs.), aparte del total de la mercancía. */
  igtf?: { bs: string; totalBs: string };
  /** Diferencial por pagar en bolívares (flags.fx.bsPricing): parte del precio, no impuesto. totalBs = lo pagado con todo. */
  bsDiff?: { bs: string; totalBs: string };
  /** 1.147: si TODO se pagó en Bs, el precio en $ de cada línea (mismo orden) y el total con lo que subió por pagar en Bs.
   *  Solo se usa con «Ref. con el precio en Bs» (receipt.refBsPrice) encendido. */
  refBs?: { lines: string[]; total: string };
  fiscalNumber?: string; exchangePolicy?: string;
  /** Cliente de la venta; `balanceUsd` = saldo de fiado (moneda base) después de la venta (solo si se fió). */
  customer?: { name: string; balanceUsd?: string };
  /** Nota de crédito o tarjeta de regalo usada en esta venta: lo que le queda. */
  storeCredits?: { label: string; code: string; balanceUsd: string }[];
  /** Cotización (2026-10-18): otro título, sin número de nota y con fecha de validez. No es una venta. */
  quote?: { validUntil: string };
}

/** Texto plano de 80 mm (42 columnas). Nunca lleva "Factura" como título. */
export function buildReceipt(r: ReceiptData, width = 42): string[] {
  const center = (s: string) => s.length >= width ? s.slice(0, width) : ' '.repeat(Math.floor((width - s.length) / 2)) + s;
  const lr = (l: string, rgt: string) => {
    const space = width - rgt.length - 1;
    return (l.length > space ? l.slice(0, space) : l.padEnd(space)) + ' ' + rgt;
  };
  const out = [
    // sin RIF cargado (negocio recién creado) no se imprime "RIF null"
    center(r.companyLegalName), ...(r.rif && r.rif !== 'null' ? [center(`RIF ${r.rif}`)] : []), center(r.displayName),
    ...(r.address ? [center(r.address)] : []), '',
    center(r.quote ? 'COTIZACIÓN' : `${VE_RECEIPT_LEGENDS.title} N.º ${r.number}`),
    ...VE_RECEIPT_LEGENDS.nonFiscal.map(center),
    ...(r.offline ? [center('(emitida sin conexión)')] : []),
    // 2026-10-17 (carga «Grupo Caribe»): fecha · caja · cajero no cabía en 42 columnas con un nombre largo
    ...(`${r.date} · ${r.register} · ${r.seller}`.length <= width ? [`${r.date} · ${r.register} · ${r.seller}`]
      : [`${r.date} · ${r.register}`.slice(0, width), `Atendió: ${r.seller}`.slice(0, width)]), '-'.repeat(width),
  ];
  for (const l of r.lines) {
    out.push(`${l.qty} x ${l.description}`.slice(0, width));
    // si la referencia con la promoción no cabe junto al monto, el monto baja a su línea (antes «(Bienvenida 10» cortado)
    const left = `   Ref. $ ${l.refUsd}`, right = `Bs. ${l.bs}`;
    if (left.length > width - right.length - 1) out.push(left.slice(0, width), lr('', right)); else out.push(lr(left, right));
  }
  out.push('-'.repeat(width), lr('TOTAL', `Bs. ${r.totalBs}`), lr('', `Ref. USD ${r.totalUsd}`));
  if (r.igtf) out.push(lr('IGTF (pago en divisas)', `Bs. ${r.igtf.bs}`));
  if (r.bsDiff) out.push(lr('Precio pago en Bs', `Bs. ${r.bsDiff.bs}`));
  if (r.igtf || r.bsDiff) out.push(lr('TOTAL PAGADO', `Bs. ${(r.bsDiff ?? r.igtf)!.totalBs}`));
  out.push((r.rateEuro ? `Tasa euro BCV: Bs. ${r.rate}` : `Tasa BCV: Bs. ${r.rate} por USD`).slice(0, width), `Fecha valor ${r.rateDate}`.slice(0, width));
  for (const p of r.payments) {
    const right = `${p.currency} ${p.amount}`, full = `${p.method}${p.reference ? ` Ref. ${p.reference}` : ''}`;
    // si la referencia no cabe junto al monto, va en su propia línea (antes se cortaba: "Ref. GCW")
    if (full.length + right.length + 1 <= width) out.push(lr(full, right));
    else { out.push(lr(p.method, right)); if (p.reference) out.push(`  Ref. ${p.reference}`.slice(0, width)); }
  }
  if (r.quote) out.push('-'.repeat(width), `Válida hasta ${r.quote.validUntil}`.slice(0, width), 'No es una venta: precios sujetos a la tasa', 'del día del pago y a disponibilidad.'.slice(0, width));
  if (r.change) out.push(lr(`Vuelto ${r.change.method}`, `${r.change.currency} ${r.change.amount}`));
  if (r.changeKept) out.push(lr('Vuelto dejado por el cliente', `${r.changeKept.currency} ${r.changeKept.amount}`));
  for (const c of r.storeCredits ?? []) out.push(`${c.label[0]!.toUpperCase()}${c.label.slice(1)} ${c.code}`.slice(0, width), lr('  Saldo restante', `Ref. $ ${c.balanceUsd}`));
  if (r.customer) {
    out.push('-'.repeat(width), `Cliente: ${r.customer.name}`.slice(0, width));
    if (r.customer.balanceUsd !== undefined) out.push(lr('Saldo por pagar (fiado)', `Ref. $ ${r.customer.balanceUsd}`));
  }
  if (r.fiscalNumber) out.push(`Factura fiscal N.º ${r.fiscalNumber}`);
  if (r.exchangePolicy) out.push('', `Cambios: ${r.exchangePolicy}`.slice(0, width * 3));
  return out;
}

// ───────────── Paquete de país para el asistente de creación (§3.1) ─────────────
export const countryPackVE = {
  code: VE.code,
  legalCurrency: VE.legalCurrency,
  defaultBaseCurrency: VE.defaultBaseCurrency,
  timezone: VE.timezone,
  defaultTaxMode: VE.defaultTaxMode,
  defaultFiscalDocumentPolicy: VE.defaultFiscalDocumentPolicy,
  validateTaxId: (raw: string) => { const r = validateRif(raw); return { ok: r.ok, normalized: r.normalized }; },
  paymentMethods: PAYMENT_METHODS_VE,
  profileFlags: (profile: string): TenantFlags =>
    profile === 'clothing' ? clothingStoreFlagsVE() : profile === 'minimarket' ? minimarketFlagsVE()
      : buildFlags({ fx: { enabled: true, displayDualCurrency: true, sourcePrimary: 'dolarapi_oficial', sourceSecondary: 'bcv_scraper' } }),
};

// ───────────── Plantilla "Tienda de ropa" en Venezuela (§5.1, §9.2) ─────────────
export function clothingStoreFlagsVE(): TenantFlags {
  return buildFlags({
    catalog: { variants: true, sizeMatrix: true, classifiers: true, photosByColor: true, priceByAttribute: true, priceLists: true },
    fx: { enabled: true, displayDualCurrency: true, sourcePrimary: 'dolarapi_oficial', sourceSecondary: 'bcv_scraper',
      maxSourceDivergencePct: 0.5, staleRatePolicy: 'allow_with_supervisor' },
    pos: { changeInOtherCurrency: true },
    sales: { exchanges: true, exchangeMaxDays: 30, layaway: true, storeCredit: true, promotions: true,
      channels: ['store', 'whatsapp', 'instagram'] },
    inventory: { giveaways: true, giveawayPinThresholdBase: 20 },
    cash: { maxDifferenceBase: 2 },
  });
}

// ───────────── Plantilla "Minimarket" en Venezuela (§7.19) ─────────────
/** Balanza: prefijo 20 = peso (gramos), 21 = precio en USD con 2 decimales. [VERIFICAR con etiquetas reales del cliente] */
export function minimarketFlagsVE(): TenantFlags {
  return buildFlags({
    catalog: { weighable: true, lots: true, packs: true },
    scaleBarcode: { enabled: true, prefixes: ['20', '21'], itemDigits: 5, valueDigits: 5, priceCheckDigit: false,
      valueType: 'by_prefix', prefixValueType: { '20': 'weight', '21': 'price' }, weightDecimals: 3, priceDecimals: 2 },
    fx: { enabled: true, displayDualCurrency: true, sourcePrimary: 'dolarapi_oficial', sourceSecondary: 'bcv_scraper' },
    pos: { quickButtons: true, changeInOtherCurrency: true, allowNegativeStock: true },
    credit: { enabled: true, defaultLimit: 0, blockOverLimit: true },
  });
}
