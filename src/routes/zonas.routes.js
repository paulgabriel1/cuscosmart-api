// Leer es PÚBLICO (cualquier turista sin cuenta); escribir es solo ADMIN.
import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { idParam } from '../schemas/comunes.js';
import { zonaSchema } from '../schemas/zonas.schema.js';
import * as c from '../controllers/zonas.controller.js';

const router = Router();
const soloAdmin = [authenticate, authorize('ADMIN')];
const conId = validate(idParam, 'params');

router.get('/', c.listarZonas);
router.get('/:id', conId, c.verZona);
router.post('/', soloAdmin, validate(zonaSchema), c.crearZona);
router.put('/:id', soloAdmin, conId, validate(zonaSchema), c.actualizarZona);
router.delete('/:id', soloAdmin, conId, c.eliminarZona);

export default router;
