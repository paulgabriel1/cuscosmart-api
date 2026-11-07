// Usuarios (solo ADMIN)
import { llamar, llamarUno } from '../utils/sp.js';
import { AppError } from '../utils/AppError.js';

export async function listarUsuarios({ buscar, page, limit }) {
  const [filas, [{ total }]] = await llamar('sp_listar_usuarios', [buscar, limit, (page - 1) * limit]);
  return { filas, total };
}

export function cambiarRol(adminId, id, rol) {
  if (adminId === id && rol !== 'ADMIN') {
    throw new AppError(422, 'No puedes quitarte a ti mismo el rol de administrador', 'BUSINESS_RULE');
  }
  return llamarUno('sp_cambiar_rol_usuario', [id, rol]);
}

export function eliminarUsuario(adminId, id) {
  if (adminId === id) throw new AppError(422, 'No puedes eliminar tu propia cuenta de administrador', 'BUSINESS_RULE');
  return llamar('sp_eliminar_usuario', [id]);
}
