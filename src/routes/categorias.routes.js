// Leer es PÚBLICO (cualquier turista sin cuenta); escribir es solo ADMIN.
import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { idParam } from '../schemas/comunes.js';
import { categoriaSchema } from '../schemas/categorias.schema.js';
import * as c from '../controllers/categorias.controller.js';

const router = Router();
const soloAdmin = [authenticate, authorize('ADMIN')];
const conId = validate(idParam, 'params');

router.get('/', c.listarCategorias);
router.get('/:id', conId, c.verCategoria);
router.post('/', soloAdmin, validate(categoriaSchema), c.crearCategoria);
router.put('/:id', soloAdmin, conId, validate(categoriaSchema), c.actualizarCategoria);
router.delete('/:id', soloAdmin, conId, c.eliminarCategoria);

export default router;
