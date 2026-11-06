// Asistente, preguntas frecuentes, reseñas públicas y administración de usuarios
import { z } from 'zod';
import { id, paginacion, textoOpcional, busqueda } from './comunes.js';

export const preguntarSchema = z.object({
  pregunta: z.string().trim().min(3, 'Escribe una pregunta un poco más larga').max(255),
});

export const preguntaFrecuenteSchema = z.object({
  pregunta: z.string().trim().min(5).max(255),
  respuesta: z.string().trim().min(3).max(5000),
  palabras_clave: textoOpcional(255),
  atractivo_id: id.nullable().optional(),
});

export const listarResenasQuery = z.object({ ...paginacion });

export const listarUsuariosQuery = z.object({ buscar: busqueda(100), ...paginacion });

export const rolSchema = z.object({ rol: z.enum(['TURISTA', 'ADMIN'], { message: 'Usa TURISTA o ADMIN' }) });
