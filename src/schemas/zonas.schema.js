import { z } from 'zod';
import { textoOpcional } from './comunes.js';

export const zonaSchema = z.object({
  nombre: z.string().trim().min(2, 'Mínimo 2 caracteres').max(100),
  ciudad: textoOpcional(100),
});
