import { z } from 'zod';
import { id, textoOpcional } from './comunes.js';

export const preguntaFrecuenteSchema = z.object({
  pregunta: z.string().trim().min(5).max(255),
  respuesta: z.string().trim().min(3).max(5000),
  palabras_clave: textoOpcional(255),
  atractivo_id: id.nullable().optional(),
});
