// Favoritos, itinerarios y reseñas del turista.
// El usuarioId SIEMPRE sale del token (req.user.id), nunca del cuerpo de la petición:
// así nadie puede crear o leer cosas a nombre de otro. Los procedimientos lo vuelven a validar.
import { llamar, llamarUno } from '../utils/sp.js';

// ---------- Favoritos ----------
export const listarFavoritos = async (usuarioId) => (await llamar('sp_listar_favoritos', [usuarioId]))[0];

export async function agregarFavorito(usuarioId, atractivoId) {
  const { favorito_id } = await llamarUno('sp_agregar_favorito', [usuarioId, atractivoId]);
  const favoritos = await listarFavoritos(usuarioId);
  return favoritos.find((f) => f.favorito_id === favorito_id);
}

export const quitarFavorito = (usuarioId, favoritoId) => llamar('sp_quitar_favorito', [usuarioId, favoritoId]);

// ---------- Itinerarios ----------
export const listarItinerarios = async (usuarioId) => (await llamar('sp_listar_itinerarios', [usuarioId]))[0];

// Los procedimientos que devuelven el itinerario completo usan 2 resultados: cabecera y paradas
const armar = ([[itinerario], paradas]) => ({
  ...itinerario,
  sugerido_ia: Boolean(itinerario.sugerido_ia),
  paradas: paradas.map((p) => ({ ...p, visitado: Boolean(p.visitado), resenado: Boolean(p.resenado) })),
});

export const verItinerario = async (usuarioId, id) => armar(await llamar('sp_ver_itinerario', [usuarioId, id]));

export async function crearItinerario(usuarioId, { nombre, latitud_inicio, longitud_inicio }) {
  const { itinerario_id } = await llamarUno('sp_crear_itinerario', [
    usuarioId, nombre, latitud_inicio ?? null, longitud_inicio ?? null,
  ]);
  return verItinerario(usuarioId, itinerario_id);
}

export const actualizarItinerario = async (usuarioId, id, { nombre, latitud_inicio, longitud_inicio }) =>
  armar(await llamar('sp_actualizar_itinerario', [usuarioId, id, nombre, latitud_inicio ?? null, longitud_inicio ?? null]));

export const eliminarItinerario = (usuarioId, id) => llamar('sp_eliminar_itinerario', [usuarioId, id]);

// ---------- Paradas y "IA" ----------
export const agregarParada = async (usuarioId, id, { favorito_id, tiempo_estimado_horas }) =>
  armar(await llamar('sp_agregar_parada', [usuarioId, id, favorito_id, tiempo_estimado_horas ?? null]));

export const quitarParada = async (usuarioId, id, paradaId) =>
  armar(await llamar('sp_quitar_parada', [usuarioId, id, paradaId]));

export const ordenarConIA = async (usuarioId, id) => armar(await llamar('sp_ordenar_itinerario_ia', [usuarioId, id]));

export const marcarVisitado = async (usuarioId, id, paradaId) =>
  armar(await llamar('sp_marcar_visitado', [usuarioId, id, paradaId]));

// ---------- Reseñas ----------
export const registrarResena = (usuarioId, id, { atractivo_id, puntuacion, comentario }) =>
  llamarUno('sp_registrar_resena', [usuarioId, id, atractivo_id, puntuacion, comentario]);
