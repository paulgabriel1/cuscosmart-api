import * as s from '../services/atractivos.service.js';
import { meta } from '../schemas/comunes.js';

const ok = (res, data, status = 200) => res.status(status).json({ ok: true, data });
const param = (req) => req.validado.params; // { id } ya convertido a número por zod

// ---------- Atractivos ----------
export async function listarAtractivos(req, res) {
  const q = req.validado.query;
  const { filas, total, sugerencias } = await s.listarAtractivos(q);
  res.json({ ok: true, data: filas, meta: { ...meta(q.page, q.limit, total), ...(q.buscar && { sugerencias }) } });
}
export const cercanos = async (req, res) => ok(res, await s.cercanos(req.validado.query));
export const verAtractivo = async (req, res) => ok(res, await s.verAtractivo(param(req).id));
export const crearAtractivo = async (req, res) => ok(res, await s.crearAtractivo(req.body), 201);
export const actualizarAtractivo = async (req, res) => ok(res, await s.actualizarAtractivo(param(req).id, req.body));
export async function eliminarAtractivo(req, res) {
  await s.eliminarAtractivo(param(req).id);
  res.status(204).end();
}

// ---------- Horarios y fotos ----------
export const listarHorarios = async (req, res) => ok(res, await s.listarHorarios(param(req).id));
export const agregarHorario = async (req, res) => ok(res, await s.agregarHorario(param(req).id, req.body), 201);
export async function eliminarHorario(req, res) {
  const { id, horarioId } = param(req);
  await s.eliminarHorario(id, horarioId);
  res.status(204).end();
}

export const listarFotos = async (req, res) => ok(res, await s.listarFotos(param(req).id));
export const agregarFoto = async (req, res) => ok(res, await s.agregarFoto(param(req).id, req.body), 201);
export const subirFotos = async (req, res) => ok(res, await s.subirFotos(param(req).id, req.files, req.body?.descripcion?.slice(0, 255)), 201);
export const fotoDesdeUrl = async (req, res) => ok(res, await s.fotoDesdeUrl(param(req).id, req.body), 201);
export async function eliminarFoto(req, res) {
  const { id, fotoId } = param(req);
  await s.eliminarFoto(id, fotoId);
  res.status(204).end();
}
