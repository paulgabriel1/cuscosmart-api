// Asistente, preguntas frecuentes, reseñas públicas y usuarios
import { llamar, llamarUno } from '../utils/sp.js';
import { AppError } from '../utils/AppError.js';

const SUGERENCIAS = 3;

// ---------- Asistente ----------
// 1) Busca la respuesta preparada más parecida (FULLTEXT en MySQL).
// 2) Si no hay ninguna, sugiere preguntas que sí sabe responder.
// No guarda lo que pregunta el turista y no llama a servicios externos: responde al instante.
export async function preguntar(texto) {
  const encontrada = await llamarUno('sp_buscar_pregunta_frecuente', [texto]);
  if (encontrada) {
    return {
      encontrada: true,
      pregunta: encontrada.pregunta,
      respuesta: encontrada.respuesta,
      atractivo: encontrada.atractivo_id ? { id: encontrada.atractivo_id, nombre: encontrada.atractivo } : null,
    };
  }
  const todas = await listarPreguntas();
  return {
    encontrada: false,
    respuesta: 'Aún no tengo una respuesta para eso. Prueba con una de estas preguntas:',
    sugerencias: todas.slice(0, SUGERENCIAS).map((p) => p.pregunta),
  };
}

// ---------- Preguntas frecuentes ----------
export const listarPreguntas = async () => (await llamar('sp_listar_preguntas'))[0];
const datosPregunta = (d) => [d.pregunta, d.respuesta, d.palabras_clave, d.atractivo_id ?? null];
export const crearPregunta = (d) => llamarUno('sp_crear_pregunta', datosPregunta(d));
export const actualizarPregunta = (id, d) => llamarUno('sp_actualizar_pregunta', [id, ...datosPregunta(d)]);
export const eliminarPregunta = (id) => llamar('sp_eliminar_pregunta', [id]);

// ---------- Reseñas públicas y moderación ----------
export async function listarResenas(atractivoId, { page, limit }) {
  const [filas, [{ total }]] = await llamar('sp_listar_resenas_atractivo', [atractivoId, limit, (page - 1) * limit]);
  return { filas, total };
}
export const eliminarResena = (id) => llamar('sp_eliminar_resena', [id]);

// ---------- Usuarios (ADMIN) ----------
export async function listarUsuarios({ buscar, page, limit }) {
  const [filas, [{ total }]] = await llamar('sp_listar_usuarios', [buscar, limit, (page - 1) * limit]);
  return { filas, total };
}

export function cambiarRol(adminId, id, rol) {
  if (adminId === id && rol !== 'ADMIN') {
    throw new AppError(422, 'No puedes quitarte a ti mismo el rol de administrador', 'BUSINESS_RULE');
  }
  return llamarUno('sp_cambiar_rol_usuario', [id, rol]);
}

export function eliminarUsuario(adminId, id) {
  if (adminId === id) throw new AppError(422, 'No puedes eliminar tu propia cuenta de administrador', 'BUSINESS_RULE');
  return llamar('sp_eliminar_usuario', [id]);
}
