import * as s from '../services/resenas.service.js';
import { meta } from '../schemas/comunes.js';

const ok = (res, data, status = 200) => res.status(status).json({ ok: true, data });
const yo = (req) => req.user.id;        // dueño: siempre desde el token
const id = (req) => req.validado.params.id;

export async function listarResenas(req, res) {
  const q = req.validado.query;
  const { filas, total } = await s.listarResenas(id(req), q);
  res.json({ ok: true, data: filas, meta: meta(q.page, q.limit, total) });
}
// POST /itinerarios/:id/resenas (el id es el del itinerario)
export const registrarResena = async (req, res) => ok(res, await s.registrarResena(yo(req), id(req), req.body), 201);
export async function eliminarMiResena(req, res) {
  await s.eliminarMiResena(yo(req), id(req));
  res.status(204).end();
}
export async function eliminarResena(req, res) {
  await s.eliminarResena(id(req));
  res.status(204).end();
}
