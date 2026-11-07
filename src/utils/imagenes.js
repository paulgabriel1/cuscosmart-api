// Guardar imágenes subidas (desde la PC) o descargadas (desde un link de internet).
// Se guardan en la carpeta uploads/ de la API y en la base solo va la ruta: "uploads/fotos/abc.jpg".
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import dns from 'node:dns/promises';
import net from 'node:net';
import { AppError } from './AppError.js';

export const CARPETA_SUBIDAS = path.resolve('uploads');
export const MAX_BYTES = 5 * 1024 * 1024; // 5 MB por imagen
const TIEMPO_MAX_MS = 10_000;
const MAX_REDIRECCIONES = 3;

// No confiamos en la extensión ni en el "Content-Type": miramos los primeros bytes del archivo
const FIRMAS = [
  { ext: 'jpg', es: (b) => b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff },
  { ext: 'png', es: (b) => b.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) },
  { ext: 'webp', es: (b) => b.toString('ascii', 0, 4) === 'RIFF' && b.toString('ascii', 8, 12) === 'WEBP' },
  { ext: 'gif', es: (b) => b.toString('ascii', 0, 4) === 'GIF8' },
];
export const tipoImagen = (buf) => (buf?.length > 12 ? FIRMAS.find((f) => f.es(buf))?.ext ?? null : null);

const NO_ES_IMAGEN = 'El archivo no es una imagen. Usa JPG, PNG, WEBP o GIF.';

/** Guarda la imagen y devuelve su ruta relativa (uploads/<carpeta>/<nombre>.<ext>) */
export async function guardarImagen(buf, carpeta, nombre = crypto.randomUUID()) {
  const ext = tipoImagen(buf);
  if (!ext) throw new AppError(400, NO_ES_IMAGEN, 'NOT_AN_IMAGE');
  if (buf.length > MAX_BYTES) throw new AppError(400, 'La imagen pesa más de 5 MB', 'FILE_TOO_LARGE');
  const dir = path.join(CARPETA_SUBIDAS, carpeta);
  await fs.mkdir(dir, { recursive: true });
  const archivo = `${nombre}.${ext}`;
  await fs.writeFile(path.join(dir, archivo), buf);
  return `uploads/${carpeta}/${archivo}`;
}

/** Borra un archivo subido (solo si está dentro de uploads/; ignora rutas img/ o https://) */
export async function borrarSubida(ruta) {
  if (!ruta?.startsWith('uploads/')) return;
  const abs = path.resolve(ruta.split('?')[0]);
  if (!abs.startsWith(CARPETA_SUBIDAS + path.sep)) return;
  await fs.rm(abs, { force: true });
}

// ---------- Descargar desde un link ----------
// Protección SSRF: no dejamos que la API descargue de su propia red (localhost, 192.168.x.x, etc.)
function ipPrivada(ip) {
  if (net.isIPv6(ip)) return ip === '::1' || /^(fc|fd|fe80)/i.test(ip) || ip.startsWith('::ffff:') && ipPrivada(ip.slice(7));
  const [a, b] = ip.split('.').map(Number);
  return a === 10 || a === 127 || a === 0 || (a === 169 && b === 254) || (a === 172 && b >= 16 && b <= 31) || (a === 192 && b === 168) || (a === 100 && b >= 64 && b <= 127);
}

async function revisarUrl(texto) {
  let url;
  try { url = new URL(texto); } catch { throw new AppError(400, 'El link no es válido', 'INVALID_URL'); }
  if (!['http:', 'https:'].includes(url.protocol)) throw new AppError(400, 'El link debe empezar con http:// o https://', 'INVALID_URL');
  const direcciones = await dns.lookup(url.hostname, { all: true }).catch(() => []);
  if (direcciones.length === 0) throw new AppError(400, 'No se encontró ese sitio web', 'INVALID_URL');
  if (direcciones.some((d) => ipPrivada(d.address))) throw new AppError(400, 'Ese link apunta a una red privada', 'INVALID_URL');
  return url;
}

async function pedir(texto) {
  let url = await revisarUrl(texto);
  for (let i = 0; i <= MAX_REDIRECCIONES; i += 1) {
    const r = await fetch(url, {
      redirect: 'manual',
      signal: AbortSignal.timeout(TIEMPO_MAX_MS),
      headers: { 'User-Agent': 'CuscoSmartEscolar/1.0 (proyecto educativo)', Accept: 'image/*,text/html;q=0.8' },
    }).catch(() => { throw new AppError(400, 'No se pudo descargar ese link (revisa tu internet o prueba con otro)', 'DOWNLOAD_FAILED'); });
    if (r.status >= 300 && r.status < 400 && r.headers.get('location')) {
      url = await revisarUrl(new URL(r.headers.get('location'), url).href); // revisamos cada redirección
      continue;
    }
    if (!r.ok) throw new AppError(400, `El sitio respondió con error ${r.status}`, 'DOWNLOAD_FAILED');
    if (Number(r.headers.get('content-length')) > MAX_BYTES) throw new AppError(400, 'La imagen pesa más de 5 MB', 'FILE_TOO_LARGE');
    const buf = Buffer.from(await r.arrayBuffer());
    if (buf.length > MAX_BYTES) throw new AppError(400, 'La imagen pesa más de 5 MB', 'FILE_TOO_LARGE');
    return { buf, tipo: r.headers.get('content-type') ?? '', url };
  }
  throw new AppError(400, 'El link redirige demasiadas veces', 'DOWNLOAD_FAILED');
}

/**
 * Descarga una imagen desde internet.
 * Si el link es una PÁGINA (no una imagen), usa la foto principal de esa página
 * (la etiqueta og:image que usan Facebook y WhatsApp para la vista previa).
 */
export async function descargarImagen(link) {
  const { buf, tipo, url } = await pedir(link);
  if (tipoImagen(buf)) return buf;
  if (tipo.includes('html')) {
    const html = buf.toString('utf8');
    const meta = html.match(/<meta[^>]+(?:property|name)=["'](?:og:image(?::secure_url)?|twitter:image)["'][^>]*>/i)?.[0];
    const foto = meta?.match(/content=["']([^"']+)["']/i)?.[1];
    if (foto) {
      const segunda = await pedir(new URL(foto.replace(/&amp;/g, '&'), url).href);
      if (tipoImagen(segunda.buf)) return segunda.buf;
    }
    throw new AppError(400, 'Ese link es una página web sin foto principal. En el navegador haz clic derecho sobre la foto → "Copiar dirección de imagen" y pega ese link.', 'NOT_AN_IMAGE');
  }
  throw new AppError(400, NO_ES_IMAGEN, 'NOT_AN_IMAGE');
}

// ---------- Foto de perfil ----------
// No hace falta una columna nueva en tbl_usuario (el diagrama ER se mantiene):
// el archivo se llama como el id del usuario, ej. uploads/perfiles/2.jpg
const EXTENSIONES = ['jpg', 'png', 'webp', 'gif'];

export async function fotoPerfil(usuarioId) {
  for (const ext of EXTENSIONES) {
    const rel = `uploads/perfiles/${usuarioId}.${ext}`;
    const info = await fs.stat(path.resolve(rel)).catch(() => null);
    if (info) return `${rel}?v=${Math.round(info.mtimeMs)}`; // ?v= evita que el navegador muestre la foto vieja
  }
  return null;
}

export async function borrarFotoPerfil(usuarioId) {
  await Promise.all(EXTENSIONES.map((ext) => borrarSubida(`uploads/perfiles/${usuarioId}.${ext}`)));
}
