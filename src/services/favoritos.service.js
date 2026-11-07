// El usuarioId SIEMPRE sale del token (req.user.id), nunca del cuerpo de la petición:
// así nadie puede crear o leer cosas a nombre de otro. Los procedimientos lo vuelven a validar.
import { llamar, llamarUno } from '../utils/sp.js';

export const listarFavoritos = async (usuarioId) => (await llamar('sp_listar_favoritos', [usuarioId]))[0];

export async function agregarFavorito(usuarioId, atractivoId) {
  const { favorito_id } = await llamarUno('sp_agregar_favorito', [usuarioId, atractivoId]);
  const favoritos = await listarFavoritos(usuarioId);
  return favoritos.find((f) => f.favorito_id === favorito_id);
}

export const quitarFavorito = (usuarioId, favoritoId) => llamar('sp_quitar_favorito', [usuarioId, favoritoId]);
