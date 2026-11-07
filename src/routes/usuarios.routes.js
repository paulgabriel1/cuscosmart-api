// Solo ADMIN
import { Router } from 'express';
import { authenticate, authorize } from '../middlewares/auth.js';
import { validate } from '../middlewares/validate.js';
import { idParam } from '../schemas/comunes.js';
import { listarUsuariosQuery, rolSchema } from '../schemas/usuarios.schema.js';
import * as c from '../controllers/usuarios.controller.js';

const router = Router();
const conId = validate(idParam, 'params');

router.use(authenticate, authorize('ADMIN'));
router.get('/', validate(listarUsuariosQuery, 'query'), c.listarUsuarios);
router.patch('/:id/rol', conId, validate(rolSchema), c.cambiarRol);
router.delete('/:id', conId, c.eliminarUsuario);

export default router;
