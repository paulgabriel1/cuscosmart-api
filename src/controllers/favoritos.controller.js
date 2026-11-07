import * as s from '../services/favoritos.service.js';

const ok = (res, data, status = 200) => res.status(status).json({ ok: true, data });
const yo = (req) => req.user.id; // dueño: siempre desde el token

export const listarFavoritos = async (req, res) => ok(res, await s.listarFavoritos(yo(req)));
export const agregarFavorito = async (req, res) => ok(res, await s.agregarFavorito(yo(req), req.body.atractivo_id), 201);
export async function quitarFavorito(req, res) {
  await s.quitarFavorito(yo(req), req.validado.params.id);
  res.status(204).end();
}
