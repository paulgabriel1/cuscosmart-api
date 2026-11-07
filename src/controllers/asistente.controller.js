import * as s from '../services/asistente.service.js';

const ok = (res, data, status = 200) => res.status(status).json({ ok: true, data });

export const preguntar = async (req, res) => ok(res, await s.preguntar(req.body.pregunta));
