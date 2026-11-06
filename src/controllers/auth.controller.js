// Los controladores solo traducen HTTP ↔ servicio: leen la petición y arman la respuesta.
import * as servicio from '../services/auth.service.js';

export async function registro(req, res) {
  res.status(201).json({ ok: true, data: await servicio.registrar(req.body) });
}

export async function login(req, res) {
  res.json({ ok: true, data: await servicio.login(req.body) });
}

export async function me(req, res) {
  res.json({ ok: true, data: await servicio.perfil(req.user.id) });
}
