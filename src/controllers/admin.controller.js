import * as s from '../services/admin.service.js';
import { meta } from '../schemas/comunes.js';

const ok = (res, data, status = 200) => res.status(status).json({ ok: true, data });
const id = (req) => req.validado.params.id;
const sinContenido = (res) => res.status(204).end();

// ---------- Asistente ----------
export const preguntar = async (req, res) => ok(res, await s.preguntar(req.body.pregunta));

// ---------- Preguntas frecuentes ----------
export const listarPreguntas = async (req, res) => ok(res, await s.listarPreguntas());
export const crearPregunta = async (req, res) => ok(res, await s.crearPregunta(req.body), 201);
export const actualizarPregunta = async (req, res) => ok(res, await s.actualizarPregunta(id(req), req.body));
export async function eliminarPregunta(req, res) {
  await s.eliminarPregunta(id(req));
  sinContenido(res);
}

// ---------- Reseñas ----------
export async function listarResenas(req, res) {
  const q = req.validado.query;
  const { filas, total } = await s.listarResenas(id(req), q);
  res.json({ ok: true, data: filas, meta: meta(q.page, q.limit, total) });
}
export async function eliminarResena(req, res) {
  await s.eliminarResena(id(req));
  sinContenido(res);
}

// ---------- Usuarios ----------
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
