import * as s from '../services/preguntas.service.js';

const ok = (res, data, status = 200) => res.status(status).json({ ok: true, data });
const id = (req) => req.validado.params.id;

export const listarPreguntas = async (req, res) => ok(res, await s.listarPreguntas());
export const crearPregunta = async (req, res) => ok(res, await s.crearPregunta(req.body), 201);
export const actualizarPregunta = async (req, res) => ok(res, await s.actualizarPregunta(id(req), req.body));
export async function eliminarPregunta(req, res) {
  await s.eliminarPregunta(id(req));
  res.status(204).end();
}
