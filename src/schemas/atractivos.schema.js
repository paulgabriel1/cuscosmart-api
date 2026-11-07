import { z } from 'zod';
import { id, paginacion, latitud, longitud, textoOpcional, busqueda } from './comunes.js';

const HORA = /^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/; // 08:30 o 08:30:00

// latitud y longitud van juntas: o las dos, o ninguna
export const atractivoSchema = z
  .object({
    nombre: z.string().trim().min(2, 'Mínimo 2 caracteres').max(200),
    descripcion: textoOpcional(5000),
    direccion: textoOpcional(255),
    latitud: latitud.nullable().optional(),
    longitud: longitud.nullable().optional(),
    precio_entrada: z.coerce.number().min(0, 'No puede ser negativo').max(99999).default(0),
    categoria_id: id,
    zona_id: id,
  })
  .refine((a) => (a.latitud == null) === (a.longitud == null), {
    message: 'Envía latitud y longitud juntas',
    path: ['longitud'],
  });

export const listarAtractivosQuery = z.object({
  categoria_id: id.optional(),
  zona_id: id.optional(),
  buscar: busqueda(100),
  ...paginacion,
});

export const cercanosQuery = z.object({
  lat: latitud,
  lng: longitud,
  radio_km: z.coerce.number().min(0.1).max(100).default(2),
  limit: z.coerce.number().int().min(1).max(50).default(10),
});

export const horarioSchema = z
  .object({
    dia_semana: z.string().trim().min(3).max(50),
    hora_apertura: z.string().regex(HORA, 'Formato HH:MM'),
    hora_cierre: z.string().regex(HORA, 'Formato HH:MM'),
  });

export const fotoSchema = z.object({
  // Solo enlaces https:// o rutas locales img/... (evita guardar "javascript:" u otros esquemas)
  url_foto: z.string().trim().max(500).regex(/^(https:\/\/|img\/)[^\s"'<>]+$/, 'Usa una URL https:// o una ruta img/...'),
  descripcion: textoOpcional(255),
});

export const horarioParams = z.object({ id, horarioId: id });
export const fotoParams = z.object({ id, fotoId: id });

// Foto desde un link: la API la descarga (puede ser el link de la imagen o de una página con foto)
export const fotoUrlSchema = z.object({
  url: z.string().trim().max(1000).regex(/^https?:\/\/[^\s"'<>]+$/, 'Pega un link que empiece con http:// o https://'),
  descripcion: textoOpcional(255),
});
