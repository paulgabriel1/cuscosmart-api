// Atractivos, horarios y fotos.
// Cada función solo llama a un procedimiento almacenado (la lógica está en MySQL).
import { llamar, llamarUno } from '../utils/sp.js';
import { AppError } from '../utils/AppError.js';
import { guardarImagen, borrarSubida, descargarImagen } from '../utils/imagenes.js';

// ---------- Atractivos ----------
export async function listarAtractivos({ categoria_id, zona_id, buscar, page, limit }) {
  const [filas, [{ total }]] = await llamar('sp_listar_atractivos', [
    categoria_id ?? null, zona_id ?? null, buscar, limit, (page - 1) * limit,
  ]);
  // Sin resultados por un error de tipeo ("sieterrrr", "sacsaywaman"): sugerimos los nombres más parecidos
  const sugerencias = total === 0 && buscar ? await sugerirNombres(buscar.replace(/\\(.)/g, '$1')) : [];
  return { filas, total, sugerencias };
}

// ---------- "¿Quisiste decir…?" (distancia de Levenshtein) ----------
// Normaliza: minúsculas, sin tildes y sin letras repetidas ("sieterrrr" → "sieter")
const normalizar = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
  .replace(/[^a-z0-9ñ ]/g, ' ').replace(/(.)\1+/g, '$1').trim();

function levenshtein(a, b) {
  let previa = Array.from({ length: b.length + 1 }, (_, j) => j);
  for (let i = 1; i <= a.length; i++) {
    const actual = [i];
    for (let j = 1; j <= b.length; j++) {
      actual[j] = Math.min(previa[j] + 1, actual[j - 1] + 1, previa[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    }
    previa = actual;
  }
  return previa[b.length];
}

// 1 = idénticas, 0 = nada que ver
const parecido = (a, b) => 1 - levenshtein(a, b) / Math.max(a.length, b.length, 1);

async function sugerirNombres(texto, cuantas = 4) {
  const buscadas = normalizar(texto).split(' ').filter((p) => p.length >= 3);
  if (buscadas.length === 0) return [];
  const [lugares] = await llamar('sp_nombres_atractivos');
  return lugares
    .map((l) => {
      const palabras = normalizar(l.nombre).split(' ').filter((p) => p.length >= 3);
      // Cada palabra buscada se compara con la palabra más parecida del nombre (o con su comienzo)
      const puntos = buscadas.map((b) => Math.max(0, ...palabras.map((p) => Math.max(parecido(b, p), parecido(b, p.slice(0, b.length))))));
      return { id: l.id, nombre: l.nombre, categoria: l.categoria, puntaje: puntos.reduce((x, y) => x + y, 0) / puntos.length };
    })
    .filter((l) => l.puntaje >= 0.6)
    .sort((x, y) => y.puntaje - x.puntaje)
    .slice(0, cuantas)
    .map(({ puntaje: _p, ...l }) => l);
}

// sp_ver_atractivo devuelve 3 resultados: datos, horarios y fotos
export async function verAtractivo(id) {
  const [[atractivo], horarios, fotos] = await llamar('sp_ver_atractivo', [id]);
  return { ...atractivo, horarios, fotos };
}

const datosAtractivo = (a) => [
  a.nombre, a.descripcion, a.direccion, a.latitud ?? null, a.longitud ?? null, a.precio_entrada, a.categoria_id, a.zona_id,
];

export async function crearAtractivo(datos) {
  const { atractivo_id } = await llamarUno('sp_crear_atractivo', datosAtractivo(datos));
  return verAtractivo(atractivo_id);
}

export async function actualizarAtractivo(id, datos) {
  await llamar('sp_actualizar_atractivo', [id, ...datosAtractivo(datos)]);
  return verAtractivo(id);
}

export const eliminarAtractivo = (id) => llamar('sp_eliminar_atractivo', [id]);

export async function cercanos({ lat, lng, radio_km, limit }) {
  const [filas] = await llamar('sp_atractivos_cercanos', [lat, lng, radio_km, limit]);
  return filas;
}

// ---------- Horarios y fotos ----------
export const listarHorarios = async (id) => (await llamar('sp_listar_horarios', [id]))[0];
export const agregarHorario = (id, { dia_semana, hora_apertura, hora_cierre }) =>
  llamarUno('sp_agregar_horario', [id, dia_semana, hora_apertura, hora_cierre]);
export const eliminarHorario = (id, horarioId) => llamar('sp_eliminar_horario', [id, horarioId]);

export const listarFotos = async (id) => (await llamar('sp_listar_fotos', [id]))[0];
export const agregarFoto = (id, { url_foto, descripcion }) => llamarUno('sp_agregar_foto', [id, url_foto, descripcion]);
// Al borrar la foto también se borra el archivo si fue subido a la API (uploads/)
export async function eliminarFoto(id, fotoId) {
  const foto = (await listarFotos(id)).find((f) => f.id === fotoId);
  await llamar('sp_eliminar_foto', [id, fotoId]);
  await borrarSubida(foto?.url_foto);
}

/** Guarda la imagen en uploads/fotos y la registra; si el SP falla, borra el archivo */
async function registrarImagen(id, buf, descripcion) {
  const ruta = await guardarImagen(buf, 'fotos');
  try {
    return await llamarUno('sp_agregar_foto', [id, ruta, descripcion ?? null]);
  } catch (e) {
    await borrarSubida(ruta);
    throw e;
  }
}

/** Fotos subidas desde la PC (varias a la vez) */
export async function subirFotos(id, archivos, descripcion) {
  if (!archivos?.length) throw new AppError(400, 'Elige al menos una imagen (JPG, PNG, WEBP o GIF)', 'NO_FILES');
  await verAtractivo(id); // 404 si no existe, antes de guardar archivos
  const guardadas = [];
  for (const a of archivos) guardadas.push(await registrarImagen(id, a.buffer, descripcion || null));
  return guardadas;
}

/** Foto desde un link de internet: la API la descarga y la guarda (así no se rompe si el sitio la borra) */
export async function fotoDesdeUrl(id, { url, descripcion }) {
  await verAtractivo(id);
  const buf = await descargarImagen(url);
  return registrarImagen(id, buf, descripcion);
}
