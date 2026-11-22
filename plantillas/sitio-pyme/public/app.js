// EDITAR: datos del negocio
const CONFIG = {
  whatsapp: '4141234567',   // 10 dígitos SIN 0 ni +58 (ej. 0414-1234567 → '4141234567')
  negocio: '{{NOMBRE}}',
  mostrarBs: true,          // false si el negocio no cobra en bolívares
};

// ── WhatsApp: todos los enlaces con data-wa abren el chat con ese mensaje ──
const waUrl = (texto) => `https://wa.me/58${CONFIG.whatsapp}?text=${encodeURIComponent(texto)}`;
document.querySelectorAll('[data-wa]').forEach((a) => {
  a.href = waUrl(a.dataset.wa);
  a.target = '_blank';
  a.rel = 'noopener';
});

// ── Menú móvil ──
const menu = document.querySelector('.menu');
const navMovil = document.getElementById('nav-movil');
if (menu && navMovil) {
  menu.addEventListener('click', () => {
    const abierto = menu.getAttribute('aria-expanded') === 'true';
    menu.setAttribute('aria-expanded', String(!abierto));
    navMovil.hidden = abierto;
  });
  navMovil.querySelectorAll('a').forEach((a) => a.addEventListener('click', () => {
    menu.setAttribute('aria-expanded', 'false');
    navMovil.hidden = true;
  }));
}

document.querySelectorAll('[data-anio]').forEach((el) => { el.textContent = new Date().getFullYear(); });

// ── Formato venezolano: 1.234.567,89 ──
const fmt = new Intl.NumberFormat('es-VE', { minimumFractionDigits: 2, maximumFractionDigits: 2 });

// ── Tasa BCV (ve.dolarapi.com), guardada 3 h en el navegador para no consultar en cada visita ──
async function tasaBCV() {
  const KEY = 'tasa-bcv';
  try {
    const guardada = JSON.parse(localStorage.getItem(KEY) || 'null');
    if (guardada && Date.now() - guardada.t < 3 * 3600e3) return guardada;
  } catch { /* sin localStorage: seguir */ }
  const r = await fetch('https://ve.dolarapi.com/v1/dolares/oficial', { cache: 'no-store' });
  if (!r.ok) throw new Error('tasa no disponible');
  const j = await r.json();                       // { promedio, fechaActualizacion, ... }
  const dato = { tasa: Number(j.promedio), fecha: j.fechaActualizacion, t: Date.now() };
  if (!(dato.tasa > 0)) throw new Error('tasa inválida');
  try { localStorage.setItem(KEY, JSON.stringify(dato)); } catch { /* ignorar */ }
  return dato;
}

(async () => {
  if (!CONFIG.mostrarBs) return;
  const precios = document.querySelectorAll('[data-usd]');
  if (!precios.length) return;
  try {
    const { tasa, fecha } = await tasaBCV();
    precios.forEach((p) => {
      const usd = Number(p.dataset.usd);
      if (!Number.isFinite(usd)) return;   // precio sin completar
      p.textContent = `Ref. $ ${fmt.format(usd)}`;
      const bs = p.parentElement.querySelector('[data-bs]');
      // redondeo a 2 decimales al final (montos chicos: suficiente para mostrar; para cobrar usar decimal en el servidor)
      if (bs) bs.textContent = `Bs. ${fmt.format(Math.round(usd * tasa * 100) / 100)}`;
    });
    const aviso = document.querySelector('[data-tasa]');
    const dia = fecha ? new Date(fecha).toLocaleDateString('es-VE', { timeZone: 'America/Caracas' }) : 'hoy';
    const fmtTasa = new Intl.NumberFormat('es-VE', { minimumFractionDigits: 2, maximumFractionDigits: 4 });
    if (aviso) aviso.textContent = `Precios referenciales en dólares. Tasa BCV: Bs. ${fmtTasa.format(tasa)} por $ (${dia}).`;
  } catch {
    // sin tasa: se quedan solo los precios en $ y el aviso general
  }
})();

// ── Formulario → WhatsApp (no guarda datos en ningún servidor) ──
const ESTADOS = ['Amazonas', 'Anzoátegui', 'Apure', 'Aragua', 'Barinas', 'Bolívar', 'Carabobo', 'Cojedes',
  'Delta Amacuro', 'Distrito Capital', 'Falcón', 'Guárico', 'La Guaira', 'Lara', 'Mérida', 'Miranda', 'Monagas',
  'Nueva Esparta', 'Portuguesa', 'Sucre', 'Táchira', 'Trujillo', 'Yaracuy', 'Zulia', 'Fuera de Venezuela'];

/** Acepta 0414-1234567, +58 414 1234567, 584141234567, 414.123.45.67… Devuelve 10 dígitos o null. */
function normalizarTelefono(raw) {
  let d = String(raw).replace(/\D/g, '');
  if (d.startsWith('58') && d.length >= 12) d = d.slice(2);
  if (d.startsWith('0')) d = d.slice(1);
  return /^(412|414|416|422|424|426|2\d{2})\d{7}$/.test(d) ? d : null;
}

const form = document.getElementById('form-contacto');
if (form) {
  const sel = form.elements.estado;
  ESTADOS.forEach((e) => sel.add(new Option(e, e)));
  const error = form.querySelector('.form__error');

  form.addEventListener('submit', (ev) => {
    ev.preventDefault();
    const f = form.elements;
    const problemas = [];
    [f.nombre, f.telefono, f.estado, f.mensaje].forEach((c) => c.setAttribute('aria-invalid', 'false'));
    const nombre = f.nombre.value.trim();
    if (nombre.length < 2) { problemas.push('tu nombre'); f.nombre.setAttribute('aria-invalid', 'true'); }
    const tel = normalizarTelefono(f.telefono.value);
    if (!tel && f.estado.value !== 'Fuera de Venezuela') { problemas.push('un teléfono venezolano válido (ej. 0414-1234567)'); f.telefono.setAttribute('aria-invalid', 'true'); }
    if (!f.estado.value) { problemas.push('tu estado'); f.estado.setAttribute('aria-invalid', 'true'); }
    const msj = f.mensaje.value.trim();
    if (msj.length < 5) { problemas.push('qué necesitas'); f.mensaje.setAttribute('aria-invalid', 'true'); }
    if (problemas.length) {
      error.textContent = `Revisa: ${problemas.join(', ')}.`;
      error.hidden = false;
      form.querySelector('[aria-invalid="true"]')?.focus();
      return;
    }
    error.hidden = true;
    const telVisible = tel ? `0${tel.slice(0, 3)}-${tel.slice(3)}` : f.telefono.value.trim();
    const lugar = [f.municipio.value.trim(), f.estado.value].filter(Boolean).join(', ');
    const texto = `Hola ${CONFIG.negocio}, soy ${nombre} (${telVisible}, ${lugar}).\n\n${msj}`;
    window.open(waUrl(texto), '_blank', 'noopener');
  });
}
