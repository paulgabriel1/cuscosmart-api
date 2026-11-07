import { z } from 'zod';
import { textoOpcional } from './comunes.js';

export const categoriaSchema = z.object({
  nombre: z.string().trim().min(2, 'Mínimo 2 caracteres').max(100),
  descripcion: textoOpcional(255),
});
