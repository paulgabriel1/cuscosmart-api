import * as s from '../services/categorias.service.js';

const ok = (res, data, status = 200) => res.status(status).json({ ok: true, data });
const param = (req) => req.validado.params; // { id } ya convertido a número por zod

export const listarCategorias = async (req, res) => ok(res, await s.listarCategorias());
export const verCategoria = async (req, res) => ok(res, await s.verCategoria(param(req).id));
export const crearCategoria = async (req, res) => ok(res, await s.crearCategoria(req.body), 201);
export const actualizarCategoria = async (req, res) => ok(res, await s.actualizarCategoria(param(req).id, req.body));
export async function eliminarCategoria(req, res) {
  await s.eliminarCategoria(param(req).id);
  res.status(204).end();
}
