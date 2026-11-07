import * as s from '../services/itinerarios.service.js';

const ok = (res, data, status = 200) => res.status(status).json({ ok: true, data });
const yo = (req) => req.user.id;               // dueño: siempre desde el token
const p = (req) => req.validado.params;        // { id, paradaId } ya validados

// ---------- Itinerarios ----------
export const listarItinerarios = async (req, res) => ok(res, await s.listarItinerarios(yo(req)));
export const verItinerario = async (req, res) => ok(res, await s.verItinerario(yo(req), p(req).id));
export const crearItinerario = async (req, res) => ok(res, await s.crearItinerario(yo(req), req.body), 201);
export const actualizarItinerario = async (req, res) => ok(res, await s.actualizarItinerario(yo(req), p(req).id, req.body));
export async function eliminarItinerario(req, res) {
  await s.eliminarItinerario(yo(req), p(req).id);
  res.status(204).end();
}

// ---------- Paradas e IA ----------
export const agregarParada = async (req, res) => ok(res, await s.agregarParada(yo(req), p(req).id, req.body), 201);
export const quitarParada = async (req, res) => ok(res, await s.quitarParada(yo(req), p(req).id, p(req).paradaId));
export const ordenarConIA = async (req, res) => ok(res, await s.ordenarConIA(yo(req), p(req).id));
export const marcarVisitado = async (req, res) => ok(res, await s.marcarVisitado(yo(req), p(req).id, p(req).paradaId));
export const desmarcarVisitado = async (req, res) => ok(res, await s.desmarcarVisitado(yo(req), p(req).id, p(req).paradaId));
export const miRecorrido = async (req, res) => ok(res, await s.miRecorrido(yo(req)));
export const visitarLugar = async (req, res) => ok(res, await s.visitarLugar(yo(req), req.body.atractivo_id));
export const agregarFavoritos = async (req, res) => ok(res, await s.agregarFavoritos(yo(req), p(req).id));
