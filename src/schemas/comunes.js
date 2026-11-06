// Piezas de validación reutilizables en todos los módulos
import { z } from 'zod';

export const id = z.coerce.number({ invalid_type_error: 'Debe ser un número' }).int('Debe ser entero').positive('Debe ser mayor que 0');

export const idParam = z.object({ id });

// ?page=1&limit=10  (valores por defecto y tope de 50 por página)
export const paginacion = {
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(10),
};

export const latitud = z.coerce.number().min(-90, 'Latitud inválida').max(90, 'Latitud inválida');
export const longitud = z.coerce.number().min(-180, 'Longitud inválida').max(180, 'Longitud inválida');

// Texto opcional: '' o solo espacios se convierte en null (así llega NULL al procedimiento)
export const textoOpcional = (max) =>
  z.string().trim().max(max).optional().nullable().transform((v) => (v ? v : null));

// Respuesta de listas paginadas: { ok, data, meta }
export const meta = (page, limit, total) => ({ page, limit, total, totalPages: Math.ceil(total / limit) });
