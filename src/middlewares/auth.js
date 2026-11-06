import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { AppError } from '../utils/AppError.js';

// 401 → "¿quién eres?". Lee el token "Authorization: Bearer xxx" y deja el usuario en req.user
export function authenticate(req, res, next) {
  const [tipo, token] = (req.headers.authorization || '').split(' ');
  if (tipo !== 'Bearer' || !token) throw new AppError(401, 'Token requerido', 'NO_TOKEN');
  try {
    const datos = jwt.verify(token, env.jwt.secret);
    req.user = { id: datos.sub, rol: datos.rol, nombre: datos.nombre };
  } catch {
    throw new AppError(401, 'Token inválido o vencido', 'INVALID_TOKEN');
  }
  next();
}

// 403 → "¿tienes permiso?". Uso: authorize('ADMIN')
export const authorize = (...roles) => (req, res, next) => {
  if (!roles.includes(req.user.rol)) throw new AppError(403, 'No tienes permiso para esta acción', 'FORBIDDEN');
  next();
};
