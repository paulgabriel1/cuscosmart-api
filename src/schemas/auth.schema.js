import { z } from 'zod';
import { textoOpcional } from './comunes.js';

const correo = z.string().trim().toLowerCase().email('Correo inválido').max(100);

export const registroSchema = z.object({
  nombre_completo: z.string().trim().min(3, 'Mínimo 3 caracteres').max(150),
  correo,
  contrasena: z
    .string()
    .min(8, 'Mínimo 8 caracteres')
    .regex(/[A-Za-z]/, 'Debe tener al menos una letra')
    .regex(/[0-9]/, 'Debe tener al menos un número')
    .refine((v) => Buffer.byteLength(v, 'utf8') <= 72, 'Máximo 72 bytes (bcrypt ignora el resto)'),
  telefono: textoOpcional(20),
});

export const googleSchema = z.object({
  credential: z.string().min(20, 'Falta el token de Google').max(4096),
});

export const perfilSchema = z.object({
  nombre_completo: z.string().trim().min(3, 'Mínimo 3 caracteres').max(150),
  telefono: textoOpcional(20),
});

export const loginSchema = z.object({
  correo,
  contrasena: z.string().min(1, 'La contraseña es obligatoria').max(72),
});
