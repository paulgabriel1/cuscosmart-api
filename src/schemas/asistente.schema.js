import { z } from 'zod';

export const preguntarSchema = z.object({
  pregunta: z.string().trim().min(3, 'Escribe una pregunta un poco más larga').max(255),
});
