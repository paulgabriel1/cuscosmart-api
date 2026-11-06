// Favoritos, itinerarios, paradas y reseñas (todo lo del turista)
import { z } from 'zod';
import { id, latitud, longitud, textoOpcional } from './comunes.js';

export const favoritoSchema = z.object({ atractivo_id: id });

// El punto de inicio (ej. el hotel) es opcional, pero latitud y longitud van juntas
export const itinerarioSchema = z
  .object({
    nombre: z.string().trim().min(3, 'Mínimo 3 caracteres').max(200),
    latitud_inicio: latitud.nullable().optional(),
    longitud_inicio: longitud.nullable().optional(),
  })
  .refine((i) => (i.latitud_inicio == null) === (i.longitud_inicio == null), {
    message: 'Envía latitud_inicio y longitud_inicio juntas',
    path: ['longitud_inicio'],
  });

// La parada se agrega desde un favorito (favorito_id) o desde cualquier lugar (atractivo_id, no lo guarda en favoritos)
export const paradaSchema = z
  .object({
    favorito_id: id.optional(),
    atractivo_id: id.optional(),
    tiempo_estimado_horas: z.coerce.number().gt(0, 'Debe ser mayor que 0').max(24).optional(),
  })
  .refine((p) => (p.favorito_id == null) !== (p.atractivo_id == null), {
    message: 'Envía favorito_id o atractivo_id (solo uno)',
    path: ['atractivo_id'],
  });

export const resenaSchema = z.object({
  atractivo_id: id,
  puntuacion: z.coerce.number().int().min(1, 'Mínimo 1').max(5, 'Máximo 5'),
  comentario: textoOpcional(500),
});

export const paradaParams = z.object({ id, paradaId: id });
