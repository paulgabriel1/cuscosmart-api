import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { limiteAsistente } from '../middlewares/limitadores.js';
import { idParam } from '../schemas/comunes.js';
import {
  preguntarSchema, preguntaFrecuenteSchema, listarResenasQuery, listarUsuariosQuery, rolSchema,
} from '../schemas/admin.schema.js';
import * as c from '../controllers/admin.controller.js';
import { eliminarMiResena } from '../controllers/viaje.controller.js';

const soloAdmin = [authenticate, authorize('ADMIN')];
const conId = validate(idParam, 'params');

// ---------- /asistente (público, con límite de 20 por minuto) ----------
export const asistente = Router();
asistente.post('/preguntar', limiteAsistente, validate(preguntarSchema), c.preguntar);

// ---------- /preguntas-frecuentes (leer público, cambiar solo ADMIN) ----------
export const preguntas = Router();
preguntas.get('/', c.listarPreguntas);
preguntas.post('/', soloAdmin, validate(preguntaFrecuenteSchema), c.crearPregunta);
preguntas.put('/:id', soloAdmin, conId, validate(preguntaFrecuenteSchema), c.actualizarPregunta);
preguntas.delete('/:id', soloAdmin, conId, c.eliminarPregunta);

// ---------- /atractivos/:id/resenas (público) y /resenas/:id (moderación ADMIN) ----------
export const resenasDeAtractivo = Router({ mergeParams: true });
resenasDeAtractivo.get('/', conId, validate(listarResenasQuery, 'query'), c.listarResenas);

export const resenas = Router();
resenas.delete('/:id', soloAdmin, conId, c.eliminarResena);
resenas.delete('/:id/propia', authenticate, conId, eliminarMiResena); // el turista borra SU reseña

// ---------- /usuarios (solo ADMIN) ----------
export const usuarios = Router();
usuarios.use(soloAdmin);
usuarios.get('/', validate(listarUsuariosQuery, 'query'), c.listarUsuarios);
usuarios.patch('/:id/rol', conId, validate(rolSchema), c.cambiarRol);
usuarios.delete('/:id', conId, c.eliminarUsuario);
