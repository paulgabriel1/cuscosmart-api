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

export async function actualizarMe(req, res) {
  res.json({ ok: true, data: await servicio.actualizarPerfil(req.user.id, req.body) });
}

export async function subirFoto(req, res) {
  res.json({ ok: true, data: await servicio.subirFotoPerfil(req.user.id, req.file) });
}

export async function quitarFoto(req, res) {
  res.json({ ok: true, data: await servicio.quitarFotoPerfil(req.user.id) });
}

export async function google(req, res) {
  res.json({ ok: true, data: await servicio.loginGoogle(req.body) });
}

export function config(_req, res) {
  res.json({ ok: true, data: servicio.configuracionPublica() });
}
