import bcrypt from 'bcryptjs';
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
    { expiresIn: env.jwt.expiresIn },
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
