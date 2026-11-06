// Catálogo: categorías, zonas, atractivos, horarios y fotos.
// Cada función solo llama a un procedimiento almacenado (la lógica está en MySQL).
import { llamar, llamarUno } from '../utils/sp.js';

// ---------- Categorías ----------
export const listarCategorias = async () => (await llamar('sp_listar_categorias'))[0];
export const verCategoria = (id) => llamarUno('sp_ver_categoria', [id]);
export const crearCategoria = ({ nombre, descripcion }) => llamarUno('sp_crear_categoria', [nombre, descripcion]);
export const actualizarCategoria = (id, { nombre, descripcion }) =>
  llamarUno('sp_actualizar_categoria', [id, nombre, descripcion]);
export const eliminarCategoria = (id) => llamar('sp_eliminar_categoria', [id]);

// ---------- Zonas ----------
export const listarZonas = async () => (await llamar('sp_listar_zonas'))[0];
export const verZona = (id) => llamarUno('sp_ver_zona', [id]);
export const crearZona = ({ nombre, ciudad }) => llamarUno('sp_crear_zona', [nombre, ciudad]);
export const actualizarZona = (id, { nombre, ciudad }) => llamarUno('sp_actualizar_zona', [id, nombre, ciudad]);
export const eliminarZona = (id) => llamar('sp_eliminar_zona', [id]);

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
export const eliminarFoto = (id, fotoId) => llamar('sp_eliminar_foto', [id, fotoId]);
