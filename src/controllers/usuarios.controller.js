import * as s from '../services/usuarios.service.js';
import { meta } from '../schemas/comunes.js';

const ok = (res, data, status = 200) => res.status(status).json({ ok: true, data });
const id = (req) => req.validado.params.id;
const sinContenido = (res) => res.status(204).end();

export async function listarUsuarios(req, res) {
  const q = req.validado.query;
  const { filas, total } = await s.listarUsuarios(q);
  res.json({ ok: true, data: filas, meta: meta(q.page, q.limit, total) });
}
export const cambiarRol = async (req, res) => ok(res, await s.cambiarRol(req.user.id, id(req), req.body.rol));
export async function eliminarUsuario(req, res) {
  await s.eliminarUsuario(req.user.id, id(req));
  sinContenido(res);
}
