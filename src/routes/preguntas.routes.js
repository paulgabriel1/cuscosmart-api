// /preguntas-frecuentes: leer público, cambiar solo ADMIN
import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { idParam } from '../schemas/comunes.js';
import { preguntaFrecuenteSchema } from '../schemas/preguntas.schema.js';
import * as c from '../controllers/preguntas.controller.js';

const router = Router();
const soloAdmin = [authenticate, authorize('ADMIN')];
const conId = validate(idParam, 'params');

router.get('/', c.listarPreguntas);
router.post('/', soloAdmin, validate(preguntaFrecuenteSchema), c.crearPregunta);
router.put('/:id', soloAdmin, conId, validate(preguntaFrecuenteSchema), c.actualizarPregunta);
router.delete('/:id', soloAdmin, conId, c.eliminarPregunta);

export default router;
