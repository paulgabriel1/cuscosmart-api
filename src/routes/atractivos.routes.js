// Atractivos con sus horarios y fotos. Leer es PÚBLICO; escribir es solo ADMIN.
import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { idParam } from '../schemas/comunes.js';
import {
  atractivoSchema, listarAtractivosQuery, cercanosQuery,
  horarioSchema, fotoSchema, horarioParams, fotoParams, fotoUrlSchema,
} from '../schemas/atractivos.schema.js';
import { subirFotos } from '../middlewares/subidas.js';
import * as c from '../controllers/atractivos.controller.js';

const router = Router();
const soloAdmin = [authenticate, authorize('ADMIN')];
const conId = validate(idParam, 'params');

router.get('/', validate(listarAtractivosQuery, 'query'), c.listarAtractivos);
router.get('/cercanos', validate(cercanosQuery, 'query'), c.cercanos); // antes de /:id
router.get('/:id', conId, c.verAtractivo);
router.post('/', soloAdmin, validate(atractivoSchema), c.crearAtractivo);
router.put('/:id', soloAdmin, conId, validate(atractivoSchema), c.actualizarAtractivo);
router.delete('/:id', soloAdmin, conId, c.eliminarAtractivo);

router.get('/:id/horarios', conId, c.listarHorarios);
router.post('/:id/horarios', soloAdmin, conId, validate(horarioSchema), c.agregarHorario);
router.delete('/:id/horarios/:horarioId', soloAdmin, validate(horarioParams, 'params'), c.eliminarHorario);

router.get('/:id/fotos', conId, c.listarFotos);
router.post('/:id/fotos', soloAdmin, conId, validate(fotoSchema), c.agregarFoto);
router.post('/:id/fotos/subir', soloAdmin, conId, subirFotos, c.subirFotos);          // archivos desde la PC (campo "fotos")
router.post('/:id/fotos/url', soloAdmin, conId, validate(fotoUrlSchema), c.fotoDesdeUrl); // la API descarga el link
router.delete('/:id/fotos/:fotoId', soloAdmin, validate(fotoParams, 'params'), c.eliminarFoto);

export default router;
