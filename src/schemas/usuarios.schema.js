// Administración de usuarios
import { z } from 'zod';
import { paginacion, busqueda } from './comunes.js';

export const listarUsuariosQuery = z.object({ buscar: busqueda(100), ...paginacion });

export const rolSchema = z.object({ rol: z.enum(['TURISTA', 'ADMIN'], { message: 'Usa TURISTA o ADMIN' }) });
