// Piezas de validación reutilizables en todos los módulos
import { z } from 'zod';

export const id = z.coerce.number({ invalid_type_error: 'Debe ser un número' }).int('Debe ser entero').positive('Debe ser mayor que 0').max(2147483647);

export const idParam = z.object({ id });

// ?page=1&limit=10  (valores por defecto y tope de 50 por página)
export const paginacion = {
  page: z.coerce.number().int().min(1).max(10000).default(1),
  limit: z.coerce.number().int().min(1).max(50).default(10),
};

// Las ubicaciones deben estar dentro del Perú (además, distancia_km es DECIMAL(6,2): máx. 9999.99 km)
const FUERA = 'La ubicación debe estar dentro del Perú';
export const latitud = z.coerce.number().min(-18.5, FUERA).max(0, FUERA);
export const longitud = z.coerce.number().min(-81.5, FUERA).max(-68.5, FUERA);

// Texto opcional: '' o solo espacios se convierte en null (así llega NULL al procedimiento)
export const textoOpcional = (max) =>
  z.string().trim().max(max).optional().nullable().transform((v) => (v ? v : null));

// Texto para buscar con LIKE: % y _ se escapan para que se busquen como texto y no como comodines
export const busqueda = (max) =>
  textoOpcional(max).transform((v) => (v ? v.replace(/[\\%_]/g, (c) => '\\' + c) : null));

// Respuesta de listas paginadas: { ok, data, meta }
export const meta = (page, limit, total) => ({ page, limit, total, totalPages: Math.ceil(total / limit) });
