import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { AppError } from '../utils/AppError.js';
import { llamarUno } from '../utils/sp.js';

// 401 → "¿quién eres?". Lee el token "Authorization: Bearer xxx" y deja el usuario en req.user.
// El rol se lee de la BASE en cada petición (no del token): si un admin pierde el rol o se
// elimina su cuenta, pierde el acceso al instante, sin esperar a que venza su token.
export async function authenticate(req, res, next) {
  const [tipo, token] = (req.headers.authorization || '').split(' ');
  if (tipo !== 'Bearer' || !token) throw new AppError(401, 'Token requerido', 'NO_TOKEN');

  let datos;
  try {
    datos = jwt.verify(token, env.jwt.secret, { algorithms: ['HS256'] });
  } catch {
    throw new AppError(401, 'Token inválido o vencido', 'INVALID_TOKEN');
  }

  const usuario = await llamarUno('sp_usuario_por_id', [datos.sub]).catch((e) => {
    if (e.sqlState === '45404') throw new AppError(401, 'La cuenta ya no existe', 'INVALID_TOKEN');
    throw e;
  });
  req.user = { id: usuario.id, rol: usuario.rol, nombre: usuario.nombre_completo };
  next();
}

// 403 → "¿tienes permiso?". Uso: authorize('ADMIN')
export const authorize = (...roles) => (req, res, next) => {
  if (!roles.includes(req.user.rol)) throw new AppError(403, 'No tienes permiso para esta acción', 'FORBIDDEN');
  next();
};
