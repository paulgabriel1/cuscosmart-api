// Reseñas: las registra el turista desde un itinerario, las lee cualquiera y el ADMIN las modera.
// El usuarioId SIEMPRE sale del token (req.user.id).
import { llamar, llamarUno } from '../utils/sp.js';

export async function listarResenas(atractivoId, { page, limit }) {
  const [filas, [{ total }]] = await llamar('sp_listar_resenas_atractivo', [atractivoId, limit, (page - 1) * limit]);
  return { filas, total };
}

export const registrarResena = (usuarioId, id, { atractivo_id, puntuacion, comentario }) =>
  llamarUno('sp_registrar_resena', [usuarioId, id, atractivo_id, puntuacion, comentario]);

export const eliminarMiResena = (usuarioId, resenaId) => llamar('sp_eliminar_mi_resena', [usuarioId, resenaId]);
export const eliminarResena = (id) => llamar('sp_eliminar_resena', [id]);
