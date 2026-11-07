import * as s from '../services/zonas.service.js';

const ok = (res, data, status = 200) => res.status(status).json({ ok: true, data });
const param = (req) => req.validado.params; // { id } ya convertido a número por zod

export const listarZonas = async (req, res) => ok(res, await s.listarZonas());
export const verZona = async (req, res) => ok(res, await s.verZona(param(req).id));
export const crearZona = async (req, res) => ok(res, await s.crearZona(req.body), 201);
export const actualizarZona = async (req, res) => ok(res, await s.actualizarZona(param(req).id, req.body));
export async function eliminarZona(req, res) {
  await s.eliminarZona(param(req).id);
  res.status(204).end();
}
