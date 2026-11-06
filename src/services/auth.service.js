import crypto from 'node:crypto';
import bcrypt from 'bcryptjs';
import { OAuth2Client } from 'google-auth-library';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { llamar, llamarUno } from '../utils/sp.js';
import { AppError } from '../utils/AppError.js';

const RONDAS_BCRYPT = 10;
// Hash de relleno: si el correo no existe igual comparamos, para tardar lo mismo
// y no revelar qué correos están registrados (ataque por tiempo de respuesta).
const HASH_FALSO = bcrypt.hashSync('contrasena-de-relleno', RONDAS_BCRYPT);

function firmarToken(usuario) {
  return jwt.sign(
    { sub: usuario.id, rol: usuario.rol, nombre: usuario.nombre_completo },
    env.jwt.secret,
    { expiresIn: env.jwt.expiresIn, algorithm: 'HS256' },
  );
}

export async function registrar({ nombre_completo, correo, contrasena, telefono }) {
  const hash = await bcrypt.hash(contrasena, RONDAS_BCRYPT); // la contraseña real nunca llega a MySQL
  const { usuario_id } = await llamarUno('sp_registrar_usuario', [nombre_completo, correo, hash, telefono]);
  const usuario = await llamarUno('sp_usuario_por_id', [usuario_id]);
  return { token: firmarToken(usuario), usuario };
}

export async function login({ correo, contrasena }) {
  const encontrado = await llamarUno('sp_usuario_por_correo', [correo]);
  const coincide = await bcrypt.compare(contrasena, encontrado?.contrasena ?? HASH_FALSO);
  // Mismo mensaje si falla el correo o la contraseña: no damos pistas
  if (!encontrado || !coincide) throw new AppError(401, 'Correo o contraseña incorrectos', 'INVALID_CREDENTIALS');

  const { contrasena: _omitida, ...usuario } = encontrado; // nunca devolver el hash
  return { token: firmarToken(usuario), usuario };
}

export async function perfil(usuarioId) {
  const [[usuario]] = await llamar('sp_usuario_por_id', [usuarioId]);
  return usuario;
}

export async function actualizarPerfil(usuarioId, { nombre_completo, telefono }) {
  return llamarUno('sp_actualizar_perfil', [usuarioId, nombre_completo, telefono]);
}

// ---------- Login con Google ----------
// El front recibe de Google un "ID token" firmado. Aquí verificamos la firma con la
// librería oficial: así nadie puede inventar un token con el correo de otra persona.
const clienteGoogle = env.googleClientId ? new OAuth2Client(env.googleClientId) : null;

async function verificarTokenGoogle(credential) {
  if (!clienteGoogle) throw new AppError(503, 'El login con Google no está configurado', 'GOOGLE_NOT_CONFIGURED');
  try {
    const ticket = await clienteGoogle.verifyIdToken({ idToken: credential, audience: env.googleClientId });
    return ticket.getPayload();
  } catch {
    throw new AppError(401, 'El token de Google no es válido', 'INVALID_GOOGLE_TOKEN');
  }
}

export async function loginGoogle({ credential }) {
  const datos = await verificarTokenGoogle(credential);
  if (!datos?.email || !datos.email_verified) {
    throw new AppError(401, 'Google no confirmó el correo de esta cuenta', 'INVALID_GOOGLE_TOKEN');
  }
  const correo = datos.email.toLowerCase();
  const encontrado = await llamarUno('sp_usuario_por_correo', [correo]);
  if (encontrado) {
    const { contrasena: _omitida, ...usuario } = encontrado;
    return { token: firmarToken(usuario), usuario, nuevo: false, foto: datos.picture ?? null };
  }
  // Primera vez: se registra con los datos de Google y una contraseña aleatoria
  // (la persona siempre entrará con Google; nadie conoce esa contraseña).
  const nombre = (datos.name || correo.split('@')[0]).slice(0, 150);
  const hash = await bcrypt.hash(crypto.randomBytes(32).toString('hex'), RONDAS_BCRYPT);
  const { usuario_id } = await llamarUno('sp_registrar_usuario', [nombre, correo, hash, null]);
  const usuario = await llamarUno('sp_usuario_por_id', [usuario_id]);
  return { token: firmarToken(usuario), usuario, nuevo: true, foto: datos.picture ?? null };
}

export function configuracionPublica() {
  return { googleClientId: env.googleClientId || null };
}
