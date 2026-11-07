// /resenas: moderación (ADMIN) y borrar la propia (turista).
// Crear una reseña está en itinerarios.routes.js (POST /itinerarios/:id/resenas).
import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { idParam } from '../schemas/comunes.js';
import { listarResenasQuery } from '../schemas/resenas.schema.js';
import * as c from '../controllers/resenas.controller.js';

const router = Router();
const soloAdmin = [authenticate, authorize('ADMIN')];
const conId = validate(idParam, 'params');

router.delete('/:id', soloAdmin, conId, c.eliminarResena);
router.delete('/:id/propia', authenticate, conId, c.eliminarMiResena); // el turista borra SU reseña

// GET /atractivos/:id/resenas (público); se monta en index.js con mergeParams
export const resenasDeAtractivo = Router({ mergeParams: true });
resenasDeAtractivo.get('/', conId, validate(listarResenasQuery, 'query'), c.listarResenas);

export default router;
