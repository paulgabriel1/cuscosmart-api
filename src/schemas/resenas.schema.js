// Reseñas: las escribe el turista (desde un itinerario) y las lee cualquiera
import { z } from 'zod';
import { id, paginacion, textoOpcional } from './comunes.js';

export const resenaSchema = z.object({
  atractivo_id: id,
  puntuacion: z.coerce.number().int().min(1, 'Mínimo 1').max(5, 'Máximo 5'),
  comentario: textoOpcional(500),
});

export const listarResenasQuery = z.object({ ...paginacion });
